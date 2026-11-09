#!/bin/sh
# Start a Docker engine inside this (privileged) container.
# On cgroup v2 hosts, move this container's own processes into a child cgroup first,
# so the nested engine can create cgroups for its containers (same approach as docker:dind).
set -e
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    mkdir -p /sys/fs/cgroup/init
    xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || :
    sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control
fi
exec dockerd --host=unix:///var/run/docker.sock
