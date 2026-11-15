#!/usr/bin/env bash
# Verify the xrd-pair lab (Part 2). Run after: containerlab deploy -t xrd-pair.clab.yml
# Prints PASS or FAIL for each check and exits non-zero if any check fails.
lab=xrd-pair; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
cli()  { docker exec "clab-$lab-$1" /pkg/bin/xr_cli "$2" 2>/dev/null; }

echo "Checking lab $lab"
for n in xrd1 xrd2; do
    if [[ $(docker inspect -f '{{.State.Running}}' "clab-$lab-$n" 2>/dev/null) == true ]]; then
        pass "$n is running"
    else
        fail "$n is not running (deploy the lab first)"
    fi
done
(( fails == 0 )) || { echo; echo "Deploy the lab first: containerlab deploy -t xrd-pair.clab.yml"; exit 1; }

# XRd keeps starting after the deploy finishes, then loads its startup config; wait for both (up to 3 minutes).
for n in xrd1 xrd2; do
    for _ in $(seq 1 36); do
        cli "$n" "show running-config hostname" | grep -q "^hostname $n" && break
        echo "  ....  waiting for $n to finish starting"; sleep 5
    done
done

# Log in over SSH as a student would. The helper answers the password prompt, so no extra packages are needed.
# IOS XR accepts one new SSH session per second, and its SSH server starts a little after the CLI answers,
# so each login is retried for up to 2 minutes.
askpass=$(mktemp); printf '#!/bin/sh\necho "clab@123"\n' > "$askpass"; chmod 700 "$askpass"
for n in xrd1 xrd2; do
    ok=no
    for _ in $(seq 1 24); do
        SSH_ASKPASS="$askpass" SSH_ASKPASS_REQUIRE=force timeout 30 \
            ssh -o ConnectTimeout=10 -o PubkeyAuthentication=no "clab-$lab-$n" "show version" </dev/null 2>/dev/null \
            | grep -q 'Cisco IOS XR Software' && { ok=yes; break; }
        sleep 5
    done
    [[ $ok == yes ]] && pass "ssh clab-$lab-$n logs in as clab with the lab password" \
        || fail "ssh clab-$lab-$n failed (check the login clab / clab@123 and that SSH is enabled in the startup config)"
    sleep 1
done
rm -f -- "$askpass"

ver=$(cli xrd1 "show version" | sed -n 's/^Cisco IOS XR Software, Version //p')
[[ -n $ver ]] && pass "xrd1 answers the CLI: IOS XR $ver" || fail "xrd1 does not answer the CLI yet (wait a minute and retry)"

for n in xrd1 xrd2; do
    cli "$n" "show interfaces GigabitEthernet0/0/0/0" | grep -q 'is up, line protocol is up' \
        && pass "$n GigabitEthernet0/0/0/0 is up" || fail "$n GigabitEthernet0/0/0/0 is not up"
done

# LLDP neighbours appear within about 30 s; retry for up to 60 s.
ok=no
for _ in $(seq 1 12); do
    cli xrd1 "show lldp neighbors" | grep -q '^xrd2 ' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "xrd1 sees xrd2 as an LLDP neighbour" || fail "xrd1 does not see xrd2 over LLDP"

# The first ping can lose a packet while the routers learn each other's MAC address; retry for up to 60 s.
ok=no
for _ in $(seq 1 12); do
    cli xrd1 "ping 10.0.12.2 count 3" | grep -q 'Success rate is 100 percent' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "xrd1 pings xrd2 (10.0.12.1 -> 10.0.12.2), 100% success" || fail "xrd1 cannot ping xrd2 at 10.0.12.2"

ok=no
for _ in $(seq 1 12); do
    cli xrd2 "ping 10.0.12.1 count 3" | grep -q 'Success rate is 100 percent' && { ok=yes; break; }
    sleep 5
done
[[ $ok == yes ]] && pass "xrd2 pings xrd1 (10.0.12.2 -> 10.0.12.1), 100% success" || fail "xrd2 cannot ping xrd1 at 10.0.12.1"

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
