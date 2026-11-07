#!/usr/bin/env bash
# Remove the two-host lab: both labs, both lab hosts and the underlay network.
# Add --image to also delete the lab-host image.
set -uo pipefail
for i in 1 2; do
    docker exec "lab-host-$i" sh -c "cd /root/site$i 2>/dev/null && containerlab destroy -t site$i.clab.yml" >/dev/null 2>&1
    docker rm -f -v "lab-host-$i" >/dev/null 2>&1 && echo "removed lab-host-$i"
done
docker network rm clab-underlay >/dev/null 2>&1 && echo "removed network clab-underlay"
[[ ${1:-} == --image ]] && docker rmi clab-host:24.04 >/dev/null 2>&1 && echo "removed image clab-host:24.04"
exit 0
