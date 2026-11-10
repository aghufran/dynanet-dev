#!/usr/bin/env bash
# Verify the connection methods from Part 4 against the Part 3 lab.
# Run after: containerlab deploy -t ../03-topology/routed.clab.yml
# Prints PASS, SKIP or FAIL for each check and exits non-zero if any check fails.
lab=routed; topo=../03-topology/routed.clab.yml; fails=0
pass() { printf '  PASS  %s\n' "$1"; }
skip() { printf '  SKIP  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
cd "$(dirname "$0")"

echo "Checking connection methods on lab $lab"
for n in xrd1 xrd2 h1 h2; do
    [[ $(docker inspect -f '{{.State.Running}}' "clab-$lab-$n" 2>/dev/null) == true ]] || fail "$n is not running"
done
(( fails == 0 )) || { echo; echo "Deploy the Part 3 lab first: containerlab deploy -t $topo"; exit 1; }

# Wait for XRd to finish starting and load its startup config (up to 3 minutes).
for n in xrd1 xrd2; do
    for _ in $(seq 1 36); do
        docker exec "clab-$lab-$n" /pkg/bin/xr_cli "show running-config hostname" 2>/dev/null | grep -q "^hostname $n" && break
        echo "  ....  waiting for $n to finish starting"; sleep 5
    done
done

# 1. Host names in /etc/hosts
count=$(grep -cE "clab-$lab-(xrd1|xrd2|h1|h2)( |$)" /etc/hosts)
[[ $count -ge 4 ]] && pass "/etc/hosts has entries for all 4 nodes" || fail "/etc/hosts is missing lab entries (found $count of 4)"

# 2. docker exec: a shell on a host, the CLI on a router
[[ $(docker exec clab-$lab-h1 hostname 2>/dev/null) == h1 ]] && pass "docker exec opens a shell on h1" || fail "docker exec into h1 failed"
docker exec clab-$lab-xrd1 /pkg/bin/xr_cli "show version" 2>/dev/null | grep -q 'Cisco IOS XR Software' \
    && pass "docker exec runs the IOS XR CLI on xrd1" || fail "docker exec xr_cli on xrd1 failed"

# 3. containerlab exec on every node of a kind
n=$(containerlab exec -t "$topo" --label clab-node-kind=cisco_xrd --cmd '/pkg/bin/xr_cli "show version"' 2>&1 | grep -c 'Cisco IOS XR Software')
[[ $n -eq 2 ]] && pass "containerlab exec ran on both routers" || fail "containerlab exec reached $n of 2 routers"

# 4. SSH by name. XRd logs you in as clab with the password clab@123; the helper below answers the
#    password prompt so this check needs no extra packages.
#    IOS XR accepts one new SSH session per second, so the SSH checks pause briefly between logins.
askpass=$(mktemp); printf '#!/bin/sh\necho "clab@123"\n' > "$askpass"; chmod 700 "$askpass"
#    The SSH server starts a little after the CLI answers, so each login is retried for up to 2 minutes.
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
done
rm -f -- "$askpass"

# 5. The generated inventories
for f in ansible-inventory.yml nornir-simple-inventory.yml topology-data.json; do
    [[ -s ../03-topology/clab-$lab/$f ]] && pass "lab folder has $f" || fail "lab folder is missing $f"
done

# 6. Python script using the generated inventory
py=${PYTHON:-python3}
if "$py" -c 'import netmiko' 2>/dev/null; then
    sleep 2
    n=$("$py" show_version.py ../03-topology/clab-$lab/topology-data.json 2>/dev/null | grep -c 'IOS XR [0-9]')
    [[ $n -eq 2 ]] && pass "show_version.py reached both routers" || fail "show_version.py reached $n of 2 routers"
else
    skip "netmiko is not installed for $py, so show_version.py was not run (set PYTHON=~/clab-venv/bin/python)"
fi

echo
if (( fails == 0 )); then echo "All checks passed."; else echo "$fails check(s) failed."; exit 1; fi
