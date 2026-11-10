# dynanet-dev

Hands-on training material on networks, labs and automation, by Abid Ghufran. The workshops are published at
**https://dynanet.dev/workshops/**, and this repository holds their lab manuals, lab files and scripts.

## Workshops

### Containerlab Workshop

Build networking labs from containers, on one host or across several. Each lab comes with a step-by-step lab manual
on [dynanet.dev](https://dynanet.dev/workshops/containerlab/) and a `verify.sh` that checks the lab is working.

| Part | Lab | Description | Lab manual |
|:---:|---|---|---|
| 1 | [First lab](clab-workshop/labs/01-first-lab) | Install Docker and Containerlab on Ubuntu, then deploy two Linux nodes joined by a single link and confirm they can reach each other. | [Installing Containerlab](https://dynanet.dev/workshops/containerlab/01-install-containerlab/) |
| 2 | [XRd pair](clab-workshop/labs/02-images) | Load network OS images into Docker (Cisco XRd, Arista cEOS, public images and VM-based images with vrnetlab), then run two Cisco XRd routers with startup configurations that address the link between them. | [Loading network OS images](https://dynanet.dev/workshops/containerlab/02-load-images/) |
| 3 | [Routed lab](clab-workshop/labs/03-topology) | Write a complete topology file: two hosts and two Cisco XRd routers in a line, with management addresses, startup configurations and static routes, so that one host reaches the other across both routers. | [Writing a topology file](https://dynanet.dev/workshops/containerlab/03-topology-file/) |
| 4 | [Connecting to nodes](clab-workshop/labs/04-connect) | Using the Part 3 lab, reach the nodes by SSH, `docker exec` and `containerlab exec`, connect from another machine, and log in to every router from Python with the inventory Containerlab generates. | [Connecting to the nodes](https://dynanet.dev/workshops/containerlab/04-connect-to-nodes/) |
| 5 | [Multi-host VXLAN](clab-workshop/labs/05-multihost) | Split the Part 3 lab across two hosts and join the halves with a VXLAN tunnel, first with two lab-host containers on one machine, then on two real machines or cloud VMs. | [Running a lab across several hosts](https://dynanet.dev/workshops/containerlab/05-multi-host/) |

**Requirements:** an Ubuntu 22.04, 24.04 or 26.04 LTS host with 4 vCPUs and 16 GB of RAM covers every lab. The
routers in Parts 2 to 5 run Cisco XRd (IOS XR). The XRd image is not in this repository: you get it from Cisco with
your own account, and Part 2 shows how to load it.

## Get the material

```bash
git clone https://github.com/aghufran/dynanet-dev.git
cd dynanet-dev/clab-workshop
```

Each workshop folder has its own README with the parts, the lab files and the requirements. All instructions target
Ubuntu Linux (22.04, 24.04 and 26.04 LTS), and every lab has a `verify.sh` that checks it is working.

## Layout

```
<workshop>/
  lab-manual/NN-short-name/index.qmd the lab manual for each part, published to dynanet.dev
  labs/NN-name/                      Containerlab topologies, startup configs and verify.sh
  scripts/                           helper scripts
workshops-index.qmd                  the dynanet.dev/workshops/ landing page
publish.sh                           maintainer only: publishes the lab manuals to dynanet.dev
```

## Licence

Lab manuals and written material: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Labs and code: MIT.
See [`LICENSE.md`](LICENSE.md) for which licence covers what.
