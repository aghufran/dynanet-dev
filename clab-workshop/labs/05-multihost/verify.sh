#!/usr/bin/env bash
# Verify the two-host VXLAN lab (Part 5). Run after ./up.sh
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
on()   { local host=$1; shift; docker exec "$host" "$@" 2>/dev/null; }          # run on a lab host
node() { local host=$1 n=$2; shift 2; docker exec "$host" docker exec "$n" "$@" 2>/dev/null; }  # run in a lab node
cli()  { node "lab-host-$1" "clab-site$1-xrd$1" /pkg/bin/xr_cli "$2"; }             # IOS XR command on xrd1 or xrd2

echo "Checking the two-host lab"
for i in 1 2; do
    [[ $(docker inspect -f '{{.State.Running}}' "lab-host-$i" 2>/dev/null) == true ]] \
        && pass "lab-host-$i is running" || fail "lab-host-$i is not running"
done
(( fails == 0 )) || { echo; echo "Start the lab first: ./up.sh"; exit 1; }

on lab-host-1 ping -c 2 -W 2 192.168.100.12 | grep -q ' 0% packet loss' \
    && pass "underlay: lab-host-1 reaches lab-host-2 (192.168.100.11 -> .12)" || fail "underlay: lab-host-1 cannot reach 192.168.100.12"

for pair in 1:xrd1 1:h1 2:xrd2 2:h2; do
    i=${pair%%:*}; n=${pair#*:}; site=site$i
    [[ $(on "lab-host-$i" docker inspect -f '{{.State.Running}}' "clab-$site-$n") == true ]] \
        && pass "$n is running on lab-host-$i" || fail "$n is not running on lab-host-$i"
done

# XRd keeps starting after the deploy, then loads its startup config; wait for both (up to 3 minutes).
for pair in 1:xrd1 2:xrd2; do
    i=${pair%%:*}; n=${pair#*:}
    for _ in $(seq 1 36); do
        cli "$i" "show running-config hostname" | grep -q "^hostname $n" && break
        echo "  ....  waiting for $n to finish starting"; sleep 5
    done
done

for pair in 1:xrd1 2:xrd2; do
    i=${pair%%:*}; n=${pair#*:}
    for ifc in GigabitEthernet0/0/0/0 GigabitEthernet0/0/0/1; do
        cli "$i" "show interfaces $ifc" | grep -q 'is up, line protocol is up' \
            && pass "$n $ifc is up" || fail "$n $ifc is not up"
    done
done

ok=no
for _ in $(seq 1 12); do
    cli 1 "ping 10.0.12.2 count 3" | grep -q 'Success rate is 100 percent' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "xrd1 pings xrd2 across the VXLAN tunnel (10.0.12.1 -> 10.0.12.2)" \
                 || fail "xrd1 cannot reach xrd2 across the tunnel: check both sides use the same VNI and port, and the remote IPs"
tries=12; [[ $ok == yes ]] || tries=1   # no point retrying the end-to-end checks if the tunnel is down

ok=no
for _ in $(seq 1 "$tries"); do
    node lab-host-1 clab-site1-h1 ping -c 3 -W 2 192.168.2.10 | grep -q ' 0% packet loss' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "h1 (lab-host-1) pings h2 (lab-host-2), 0% loss" || fail "h1 cannot ping h2 at 192.168.2.10"
h2_ok=$ok

path=$(node lab-host-1 clab-site1-h1 traceroute -n -w 2 -m 5 192.168.2.10 | awk 'NR>1 {print $2}' | paste -sd' ')
[[ $path == "192.168.1.1 10.0.12.2 192.168.2.10" ]] \
    && pass "h1 to h2 path is xrd1 -> xrd2 -> h2 ($path)" || fail "unexpected path from h1 to h2: $path"

# Capture the underlay while pinging: the packets between the hosts must be VXLAN, VNI 100.
docker exec -d lab-host-1 sh -c 'timeout 8 tcpdump -ni eth0 -c 4 udp port 4789 > /tmp/verify-vxlan.txt 2>&1'
sleep 1; node lab-host-1 clab-site1-h1 ping -c 3 192.168.2.10 >/dev/null; sleep 3
on lab-host-1 grep -q 'VXLAN.*vni 100' /tmp/verify-vxlan.txt \
    && pass "underlay carries the traffic as VXLAN, VNI 100, UDP 4789" || fail "no VXLAN (VNI 100) packets seen on the underlay"

if [[ $h2_ok == yes ]]; then
    node lab-host-1 clab-site1-h1 ping -c 2 -W 2 -s 3000 192.168.2.10 | grep -q ' 0% packet loss' \
        && pass "large packets (3000 bytes) cross the tunnel" || fail "large packets do not cross the tunnel (check the MTU settings)"
fi

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
