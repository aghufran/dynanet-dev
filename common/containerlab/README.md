# Containerlab Workshop

Part of [aghufran/course](https://github.com/aghufran/course): shared material for every course.

Hands-on material for building networking labs with [Containerlab](https://containerlab.dev).
The full articles are published at **https://dynanet.dev/workshops/containerlab/**; this folder holds the lab
files you run.

## Parts

| Part | Topic | Article | Lab files |
|---|---|---|---|
| 1 | Installing Containerlab | [Part 1](https://dynanet.dev/workshops/containerlab/01-install-containerlab/) | [`labs/01-first-lab`](labs/01-first-lab) |
| 2 | Loading network OS images into Docker | [Part 2](https://dynanet.dev/workshops/containerlab/02-load-images/) | [`labs/02-images`](labs/02-images) |
| 3 | Writing a lab topology file | [Part 3](https://dynanet.dev/workshops/containerlab/03-topology-file/) | [`labs/03-topology`](labs/03-topology) |
| 4 | Connecting to the nodes in a lab | [Part 4](https://dynanet.dev/workshops/containerlab/04-connect-to-nodes/) | [`labs/04-connect`](labs/04-connect) (uses the Part 3 lab) |
| 5 | Running a lab across several cloud VMs (AWS) | coming soon | [`cloud/`](cloud) |

## Quick start

On an Ubuntu host with Docker and Containerlab installed (see Part 1):

```bash
git clone https://github.com/aghufran/course.git
cd course/common/containerlab/labs/01-first-lab
containerlab deploy -t first-lab.clab.yml
./verify.sh                     # every check should say PASS
containerlab destroy -t first-lab.clab.yml
```

Every lab folder has a `verify.sh` that checks the running lab and prints PASS or FAIL for each check.

## Folder layout

```
articles/   workshop articles (Quarto .qmd), published to dynanet.dev by the repo's publish.sh
labs/       one folder per lab: the .clab.yml topology and any startup configs
scripts/    helper scripts used in the labs
cloud/      material for running labs across cloud VMs (AWS)
```

## Requirements

An Ubuntu 22.04, 24.04 or 26.04 LTS host (desktop, server or VM) with 4 vCPUs and 16 GB of RAM covers every lab. Some parts use network OS images
that need a vendor account to download (for example Cisco XRd); the article for each part says which.

## Licence

The articles are licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); the lab files and scripts are licensed MIT.
See [`LICENSE.md`](../../LICENSE.md) at the top of the repository.
