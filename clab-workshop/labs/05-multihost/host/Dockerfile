# A "lab host": Ubuntu 24.04 with its own Docker engine and Containerlab.
# Two of these stand in for two separate machines (or cloud VMs) in Part 5.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io iproute2 iputils-ping tcpdump ca-certificates curl python3 \
 && echo "deb [trusted=yes] https://netdevops.fury.site/apt/ /" > /etc/apt/sources.list.d/netdevops.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends containerlab \
 && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# The nested Docker engine keeps its images and containers here.
VOLUME /var/lib/docker
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
