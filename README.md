# dynanet-dev

Hands-on training material on networks, labs and automation, by Abid Ghufran. The workshops are published at
**https://dynanet.dev/workshops/**, and this repository holds their articles, lab files and scripts.

## Workshops

| Workshop | Folder | Website |
|---|---|---|
| Containerlab Workshop: build networking labs from containers, on one host or across several | [`clab-workshop`](clab-workshop) | https://dynanet.dev/workshops/containerlab/ |

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
  articles/NN-short-name/index.qmd   the workshop articles, published to dynanet.dev
  labs/NN-name/                      Containerlab topologies, startup configs and verify.sh
  scripts/                           helper scripts
workshops-index.qmd                  the dynanet.dev/workshops/ landing page
publish.sh                           maintainer only: publishes the articles to dynanet.dev
```

## Licence

Articles and written material: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Labs and code: MIT.
See [`LICENSE.md`](LICENSE.md) for which licence covers what.
