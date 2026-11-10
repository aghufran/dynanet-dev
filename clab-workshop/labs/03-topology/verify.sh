#!/usr/bin/env bash
# Verify the routed lab (Part 3). Run after: containerlab deploy -t routed.clab.yml
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
lab=routed; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
cli()  { docker exec "clab-$lab-$1" /pkg/bin/xr_cli "$2" 2>/dev/null; }

echo "Checking lab $lab"
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

path=$(docker exec clab-$lab-h1 traceroute -n -w 2 -m 5 192.168.2.10 2>/dev/null | awk 'NR>1 {print $2}' | paste -sd' ')
[[ $path == "192.168.1.1 10.0.12.2 192.168.2.10" ]] \
    && pass "h1 to h2 path is xrd1 -> xrd2 -> h2 ($path)" || fail "unexpected path from h1 to h2: $path"

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
