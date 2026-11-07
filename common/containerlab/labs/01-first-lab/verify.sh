#!/usr/bin/env bash
# Verify the first-lab lab (Part 1). Run after: containerlab deploy -t first-lab.clab.yml
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
lab=first-lab; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }

echo "Checking lab $lab"
for n in n1:10.0.12.1 n2:10.0.12.2; do
    name=${n%%:*}; ip=${n#*:}
    if [[ $(docker inspect -f '{{.State.Running}}' "clab-$lab-$name" 2>/dev/null) == true ]]; then
        pass "$name is running"
    else
        fail "$name is not running (deploy the lab first)"; continue
    fi
    docker exec "clab-$lab-$name" ip -4 addr show eth1 2>/dev/null | grep -q "inet $ip/30" \
        && pass "$name eth1 has $ip/30" || fail "$name eth1 does not have $ip/30"
done

docker exec clab-$lab-n1 ping -c 3 -W 2 10.0.12.2 2>/dev/null | grep -q ' 0% packet loss' \
    && pass "n1 pings n2 (10.0.12.1 -> 10.0.12.2), 0% loss" || fail "n1 cannot ping n2 at 10.0.12.2"

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
