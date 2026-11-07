# Course material

Training material for networking courses: articles, lab files and scripts.

- **`common/`** holds material shared by every course, one folder per topic. The articles are published at
  **https://dynanet.dev/workshops/**.
- **`institutions/`** holds the courses delivered to individual institutions. Each is its own repository, added here as a
  git submodule (see [`institutions/README.md`](institutions/README.md)).

## Topics

| Topic | Folder | Website |
|---|---|---|
| Containerlab for networking labs | [`common/containerlab`](common/containerlab) | https://dynanet.dev/workshops/containerlab/ |

## Get the material

```bash
git clone https://github.com/aghufran/course.git
cd course/common/containerlab
```

## Layout

```
common/<topic>/
  articles/NN-short-name/index.qmd   articles (Quarto), published to dynanet.dev
  labs/NN-name/                      Containerlab topologies (.clab.yml) and startup configs
  scripts/                           helper scripts
institutions/<institution>/          per-institution course (git submodule)
workshops-index.qmd                  the dynanet.dev/workshops/ landing page
publish.sh                           maintainer only: publishes common/*/articles to dynanet.dev
```

## Maintainer notes

- Write articles in `common/<topic>/articles/` (same Quarto format as dynanet.dev posts, see
  `~/webstack/docs/WRITING-ARTICLES.md`). Each article folder has an `order:` field for its part number.
- Publish with `./publish.sh`. Never edit the copies in `~/webstack/site/workshops/`; they are overwritten each time.
- Test every lab on NetDev1 before publishing the article that uses it.
- `draft: true` leaves an article out of the build entirely (Quarto renders it as a blank page).
- All instructions target Ubuntu Linux (22.04, 24.04, 26.04 LTS).
