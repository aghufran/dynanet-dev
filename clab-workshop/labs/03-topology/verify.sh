#!/usr/bin/env bash
# Verify the routed lab (Part 3). Run after: containerlab deploy -t routed.clab.yml
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
lab=routed; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
cli()  { docker exec "clab-$lab-$1" /pkg/bin/xr_cli "$2" 2>/dev/null; }

echo "Checking lab $lab"
command -v python3 >/dev/null || { echo "python3 is required by this script. Install it: sudo apt install -y python3"; exit 1; }
# Management addresses as Containerlab reports them (works whatever network mode a node's container uses).
mgmt=$(containerlab inspect -t "$(dirname "$0")/routed.clab.yml" --format json 2>/dev/null | python3 -c '
import json, sys
try:
    for nodes in json.load(sys.stdin).values():
        for n in nodes:
            print(n["name"], n.get("ipv4_address", "").split("/")[0])
except ValueError:
    pass')
for n in xrd1:172.20.20.11 xrd2:172.20.20.12 h1:172.20.20.21 h2:172.20.20.22; do
    name=${n%%:*}; ip=${n#*:}
    if [[ $(docker inspect -f '{{.State.Running}}' "clab-$lab-$name" 2>/dev/null) != true ]]; then
        fail "$name is not running"; continue
    fi
    got=$(awk -v n="clab-$lab-$name" '$1 == n {print $2}' <<<"$mgmt")
    [[ $got == "$ip" ]] && pass "$name is running with management address $ip" \
                        || fail "$name has management address ${got:-unknown}, expected $ip"
done
(( fails == 0 )) || { echo; echo "Deploy the lab first: containerlab deploy -t routed.clab.yml"; exit 1; }

# XRd keeps starting after the deploy finishes, then loads its startup config; wait for both (up to 3 minutes).
for n in xrd1 xrd2; do
    for _ in $(seq 1 36); do
        cli "$n" "show running-config hostname" | grep -q "^hostname $n" && break
        echo "  ....  waiting for $n to finish starting"; sleep 5
    done
done

for n in xrd1 xrd2; do
    for i in GigabitEthernet0/0/0/0 GigabitEthernet0/0/0/1; do
        cli "$n" "show interfaces $i" | grep -q 'is up, line protocol is up' && pass "$n $i is up" || fail "$n $i is not up"
    done
done

cli xrd1 "show route 192.168.2.0/24" | grep -q 'Known via "static"' \
    && pass "xrd1 has the static route to 192.168.2.0/24 installed" || fail "xrd1 static route to 192.168.2.0/24 is not installed"
cli xrd2 "show route 192.168.1.0/24" | grep -q 'Known via "static"' \
    && pass "xrd2 has the static route to 192.168.1.0/24 installed" || fail "xrd2 static route to 192.168.1.0/24 is not installed"

# Routers need a few seconds after boot before they forward; retry for up to 60 s.
ok=no
for _ in $(seq 1 12); do
    docker exec clab-$lab-h1 ping -c 3 -W 2 192.168.2.10 2>/dev/null | grep -q ' 0% packet loss' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "h1 pings h2 (192.168.1.10 -> 192.168.2.10), 0% loss" || fail "h1 cannot ping h2 at 192.168.2.10"

# A router pings from the address of the outgoing interface (10.0.12.x), which h2 has no route back to.
# Giving the address of the interface facing the hosts as the source makes the ping work end to end.
cli xrd1 "ping 192.168.2.10 source 192.168.1.1 count 3" | grep -q 'Success rate is 100 percent' \
    && pass "xrd1 pings h2 with source 192.168.1.1 (its host-facing address)" || fail "xrd1 cannot ping h2 at 192.168.2.10 with source 192.168.1.1"

cli xrd2 "ping 192.168.1.10 source 192.168.2.1 count 3" | grep -q 'Success rate is 100 percent' \
    && pass "xrd2 pings h1 with source 192.168.2.1 (its host-facing address)" || fail "xrd2 cannot ping h1 at 192.168.1.10 with source 192.168.2.1"

docker exec clab-$lab-h2 ping -c 3 -W 2 192.168.1.10 2>/dev/null | grep -q ' 0% packet loss' \
    && pass "h2 pings h1 (192.168.2.10 -> 192.168.1.10), 0% loss" || fail "h2 cannot ping h1 at 192.168.1.10"

path=$(docker exec clab-$lab-h1 traceroute -n -w 2 -m 5 192.168.2.10 2>/dev/null | awk 'NR>1 {print $2}' | paste -sd' ')
[[ $path == "192.168.1.1 10.0.12.2 192.168.2.10" ]] \
    && pass "h1 to h2 path is xrd1 -> xrd2 -> h2 ($path)" || fail "unexpected path from h1 to h2: $path"

path=$(docker exec clab-$lab-h2 traceroute -n -w 2 -m 5 192.168.1.10 2>/dev/null | awk 'NR>1 {print $2}' | paste -sd' ')
[[ $path == "192.168.2.1 10.0.12.1 192.168.1.10" ]] \
    && pass "h2 to h1 path is xrd2 -> xrd1 -> h1 ($path)" || fail "unexpected path from h2 to h1: $path"

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
