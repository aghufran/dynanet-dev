#!/usr/bin/env bash
# Build and start the two-host lab on one Ubuntu machine.
#   - two "lab hosts" (containers with their own Docker + Containerlab) on an underlay network
#   - site1 (h1, xrd1) on lab-host-1, site2 (xrd2, h2) on lab-host-2
#   - xrd1 and xrd2 joined by a VXLAN tunnel (VNI 100) across the underlay
# Needs Docker and the Cisco XRd image on this machine (Part 2). Run:  ./up.sh      Remove with:  ./down.sh
set -euo pipefail
cd "$(dirname "$0")"
NET=clab-underlay SUBNET=192.168.100.0/24 GW=192.168.100.1
XRD=ios-xr/xrd-control-plane:7.11.2
IMAGES=("$XRD" alpine:3)

# XRd cannot be downloaded from a public registry, so it must already be loaded here (Part 2).
docker image inspect "$XRD" >/dev/null 2>&1 || {
    echo "The image $XRD is not loaded on this machine. Load it first (Part 2), then run ./up.sh again."; exit 1; }

echo "1/5 Building the lab-host image (Ubuntu + Docker + Containerlab)"
docker build -q -t clab-host:24.04 host/ >/tmp/clab-host-build.log 2>&1 || { cat /tmp/clab-host-build.log; exit 1; }

echo "2/5 Creating the underlay network $NET ($SUBNET)"
docker network inspect "$NET" >/dev/null 2>&1 || docker network create --subnet "$SUBNET" --gateway "$GW" "$NET" >/dev/null

echo "3/5 Starting lab-host-1 (192.168.100.11) and lab-host-2 (192.168.100.12)"
for i in 1 2; do
    docker inspect "lab-host-$i" >/dev/null 2>&1 || \
        docker run -d --privileged --name "lab-host-$i" --hostname "lab-host-$i" \
            --network "$NET" --ip "192.168.100.1$i" clab-host:24.04 >/dev/null
done
for i in 1 2; do
    until docker exec "lab-host-$i" docker info >/dev/null 2>&1; do sleep 1; done
done

echo "4/5 Getting the node images into each lab host"
for i in 1 2; do
    for img in "${IMAGES[@]}"; do
        docker exec "lab-host-$i" docker image inspect "$img" >/dev/null 2>&1 && continue
        if docker image inspect "$img" >/dev/null 2>&1; then
            docker save "$img" | docker exec -i "lab-host-$i" docker load -q >/dev/null   # copy from this machine
        else
            docker exec "lab-host-$i" docker pull -q "$img" >/dev/null                      # download
        fi
    done
done

echo "5/5 Deploying site1 on lab-host-1 and site2 on lab-host-2"
for i in 1 2; do
    docker exec "lab-host-$i" rm -rf "/root/site$i"
    docker cp "site$i" "lab-host-$i:/root/site$i"
done
docker exec lab-host-1 sh -c 'cd /root/site1 && containerlab deploy -t site1.clab.yml' >/tmp/site1-deploy.log 2>&1 &
docker exec lab-host-2 sh -c 'cd /root/site2 && containerlab deploy -t site2.clab.yml' >/tmp/site2-deploy.log 2>&1 &
wait
grep -h -E 'running' /tmp/site1-deploy.log /tmp/site2-deploy.log || { cat /tmp/site1-deploy.log /tmp/site2-deploy.log; exit 1; }
echo
echo "Done. Check it with ./verify.sh"
