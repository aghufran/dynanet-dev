# Containerlab Workshop

Part of [aghufran/dynanet-dev](https://github.com/aghufran/dynanet-dev).

Hands-on material for building networking labs with [Containerlab](https://containerlab.dev).
The full lab manuals are published at **https://dynanet.dev/workshops/containerlab/**; this folder holds the lab
files you run.

## Parts

| Part | Topic | Lab manual | Lab files |
|---|---|---|---|
| 1 | Installing Containerlab | [Part 1](https://dynanet.dev/workshops/containerlab/01-install-containerlab/) | [`labs/01-first-lab`](labs/01-first-lab) |
| 2 | Loading network OS images into Docker | [Part 2](https://dynanet.dev/workshops/containerlab/02-load-images/) | [`labs/02-images`](labs/02-images) |
| 3 | Writing a lab topology file | [Part 3](https://dynanet.dev/workshops/containerlab/03-topology-file/) | [`labs/03-topology`](labs/03-topology) |
| 4 | Connecting to the nodes in a lab | [Part 4](https://dynanet.dev/workshops/containerlab/04-connect-to-nodes/) | [`labs/04-connect`](labs/04-connect) (uses the Part 3 lab) |
| 5 | Running a lab across several hosts (VXLAN) | [Part 5](https://dynanet.dev/workshops/containerlab/05-multi-host/) | [`labs/05-multihost`](labs/05-multihost) |

## Quick start

On an Ubuntu host with Docker and Containerlab installed (see Part 1):

```bash
git clone https://github.com/aghufran/dynanet-dev.git
cd dynanet-dev/clab-workshop/labs/01-first-lab
containerlab deploy -t first-lab.clab.yml
./verify.sh                     # every check should say PASS
containerlab destroy -t first-lab.clab.yml
```

Every lab folder has a `verify.sh` that checks the running lab and prints PASS or FAIL for each check.

## Folder layout

```
lab-manual/  the lab manual for each part (Quarto .qmd), published to dynanet.dev by the repository's publish.sh
labs/        one folder per lab: the .clab.yml topology and any startup configs
scripts/     helper scripts used in the labs
cloud/       material for running labs across cloud VMs (AWS)
```

## Requirements

An Ubuntu 22.04, 24.04 or 26.04 LTS host (desktop, server or VM) with 4 vCPUs and 16 GB of RAM covers every lab.

The routers in Parts 2 to 5 run Cisco XRd (IOS XR), release 7.11.2 in the lab files. The XRd image is not in this
repository: you get it from Cisco with your own account, and Part 2 shows how to load it. Part 1 needs no vendor image.

## Licence

The lab manuals are licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); the lab files and scripts are licensed MIT.
See [`LICENSE.md`](../LICENSE.md) at the top of the repository.
