#!/usr/bin/env bash
# Verify the srl-pair lab (Part 2). Run after: containerlab deploy -t srl-pair.clab.yml
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
lab=srl-pair; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
cli()  { docker exec "clab-$lab-$1" sr_cli "$2" 2>/dev/null; }

echo "Checking lab $lab"
for n in srl1 srl2; do
    if [[ $(docker inspect -f '{{.State.Running}}' "clab-$lab-$n" 2>/dev/null) == true ]]; then
        pass "$n is running"
    else
        fail "$n is not running (deploy the lab first)"
    fi
done
(( fails == 0 )) || { echo; echo "Deploy the lab first: containerlab deploy -t srl-pair.clab.yml"; exit 1; }

# SR Linux keeps starting for a short while after the deploy finishes; wait for both CLIs (up to 90 s).
for n in srl1 srl2; do
    for _ in $(seq 1 18); do
        cli "$n" "show version" | grep -q 'Software Version' && break
        echo "  ....  waiting for $n to finish starting"; sleep 5
    done
done

ver=$(cli srl1 "show version" | awk -F': ' '/Software Version/ {print $2}')
[[ -n $ver ]] && pass "srl1 answers the CLI: SR Linux $ver" || fail "srl1 does not answer the CLI yet (wait a minute and retry)"

for n in srl1 srl2; do
    cli "$n" "show interface ethernet-1/1" | grep -q 'ethernet-1/1 is up' \
        && pass "$n ethernet-1/1 is up" || fail "$n ethernet-1/1 is not up"
done

cli srl1 "show system lldp neighbor" | grep -q 'srl2' \
    && pass "srl1 sees srl2 as an LLDP neighbour" || fail "srl1 does not see srl2 over LLDP (wait 30 s and retry)"

# The routers need a few seconds after boot before they forward; retry for up to 60 s.
ok=no
for _ in $(seq 1 12); do
    if cli srl1 "ping 10.0.12.2 network-instance default -c 3" | grep -q ' 0% packet loss'; then ok=yes; break; fi
    sleep 5
done
[[ $ok == yes ]] && pass "srl1 pings srl2 (10.0.12.1 -> 10.0.12.2), 0% loss" || fail "srl1 cannot ping srl2 at 10.0.12.2"

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
