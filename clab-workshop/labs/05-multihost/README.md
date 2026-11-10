# Part 5 lab: one lab across two hosts, joined by VXLAN

Two "lab hosts" run on one Ubuntu machine. Each is a privileged container with its own Docker engine and
Containerlab, standing in for a separate server or cloud VM. Each runs half of the Part 3 routed lab, and the two
routers are joined by a VXLAN tunnel across an underlay network.

```
 lab-host-1  192.168.100.11                       lab-host-2  192.168.100.12
 ┌──────────────────────────┐                     ┌──────────────────────────┐
 │  h1 ──── xrd1            │   VXLAN VNI 100     │            xrd2 ──── h2  │
 │            Gi0/0/0/1 ════╪═════ UDP 4789 ══════╪═ Gi0/0/0/1               │
 └──────────────────────────┘                     └──────────────────────────┘
          underlay network clab-underlay  192.168.100.0/24
```

The machine itself needs Docker, the Cisco XRd image (`ios-xr/xrd-control-plane:7.11.2`) and the XRd host settings
from Part 2, with about 5 GB of free RAM, 8 GB of free disk and 4 vCPUs. `up.sh` copies the XRd image into each lab
host and stops with a message if the image is not loaded.

```bash
./up.sh       # build the lab-host image, start both hosts, deploy site1 and site2 (about 1-2 minutes)
./verify.sh   # 16 checks, from the underlay to a large ping from h1 to h2
./down.sh     # remove both labs, both hosts and the underlay network (add --image to delete the image too)
```

| File | What it is |
|---|---|
| `host/Dockerfile`, `host/entrypoint.sh` | The lab-host image: Ubuntu 24.04 + Docker + Containerlab |
| `site1/site1.clab.yml` | h1 and xrd1, with a `type: vxlan` link from xrd1 Gi0-0-0-1 to 192.168.100.12 |
| `site2/site2.clab.yml` | xrd2 and h2, with the matching VXLAN link to 192.168.100.11 |
| `site*/configs/*.cfg` | IOS XR router configs: the Part 3 addresses and static routes, plus `ipv4 mtu 1450` on the tunnel interface |

Run a command on a lab host with `docker exec lab-host-1 <command>`, and inside a lab node with
`docker exec lab-host-1 docker exec clab-site1-xrd1 /pkg/bin/xr_cli "show ipv4 interface brief"`.

MTU: VXLAN adds 50 bytes. Containerlab gives the VXLAN links an MTU of 1450, the routers limit the tunnel interface
to IPv4 MTU 1450, and the hosts' lab interfaces use MTU 1450, so nothing is fragmented on the 1500-byte underlay.

The same `site1` and `site2` files work on two real machines or cloud VMs: change the `remote:` addresses to the
other machine's IP and allow UDP 4789 between them.
