# Part 5 lab: one lab across two hosts, joined by VXLAN

Two "lab hosts" run on one Ubuntu machine. Each is a privileged container with its own Docker engine and
Containerlab, standing in for a separate server or cloud VM. Each runs half of the Part 3 routed lab, and the two
routers are joined by a VXLAN tunnel across an underlay network.

```
 lab-host-1  192.168.100.11                       lab-host-2  192.168.100.12
 ┌──────────────────────────┐                     ┌──────────────────────────┐
 │  h1 ──── srl1            │   VXLAN VNI 100     │            srl2 ──── h2  │
 │         ethernet-1/2 ════╪═════ UDP 4789 ══════╪═ ethernet-1/2            │
 └──────────────────────────┘                     └──────────────────────────┘
          underlay network clab-underlay  192.168.100.0/24
```

Only Docker is needed on the machine itself (about 6 GB of free RAM and 4 vCPUs).

```bash
./up.sh       # build the lab-host image, start both hosts, deploy site1 and site2 (about 1-2 minutes)
./verify.sh   # 16 checks, from the underlay to a large ping from h1 to h2
./down.sh     # remove both labs, both hosts and the underlay network (add --image to delete the image too)
```

| File | What it is |
|---|---|
| `host/Dockerfile`, `host/entrypoint.sh` | The lab-host image: Ubuntu 24.04 + Docker + Containerlab |
| `site1/site1.clab.yml` | h1 and srl1, with a `type: vxlan` link from srl1 ethernet-1/2 to 192.168.100.12 |
| `site2/site2.clab.yml` | srl2 and h2, with the matching VXLAN link to 192.168.100.11 |
| `site*/configs/*.cli` | Router configs: the Part 3 addresses and static routes, plus IP MTU 1450 on the tunnel interface |

Run a command on a lab host with `docker exec lab-host-1 <command>`, and inside a lab node with
`docker exec lab-host-1 docker exec clab-site1-srl1 sr_cli "show interface brief"`.

MTU: VXLAN adds 50 bytes. The VXLAN links are set to MTU 1500 (SR Linux ports refuse less), the routers limit the
tunnel interface to IP MTU 1450, and the hosts' lab interfaces use MTU 1450, so nothing is fragmented on the
1500-byte underlay.

The same `site1` and `site2` files work on two real machines or cloud VMs: change the `remote:` addresses to the
other machine's IP and allow UDP 4789 between them.
