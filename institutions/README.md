# Institutions

Each course delivered to an institution has its own repository, mounted here as a git submodule.
Institution repositories can be private even though this main repository is public.

## Add an institution

1. Create an empty repository on GitHub, named `course-<institution>` (for example `course-uni-a`).
2. From the root of this repository:
   ```bash
   git submodule add git@github.com:aghufran/course-<institution>.git institutions/<institution>
   git commit -m "Add <institution> course"
   git push
   ```
3. Work inside `institutions/<institution>/` as in any repo (commit and push there), then record the new version
   in this repo with `git add institutions/<institution> && git commit`.

In an institution's course, link to the shared material in `common/` (or to its dynanet.dev articles)
rather than copying it.

## Clone

```bash
git clone --recurse-submodules git@github.com:aghufran/dynanet-dev.git   # everything you can access
git submodule update --init institutions/<institution>              # one institution, later
```

Students of one institution only need that institution's repository and the public `common/` material.
