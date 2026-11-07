#!/usr/bin/env bash
# Publish the shared course articles to dynanet.dev.
#
# For every topic in common/<topic>/articles/, the folder is copied to
# ~/webstack/site/workshops/<topic>/ (replaced each time, so edit HERE, never in
# webstack). workshops-index.qmd becomes https://dynanet.dev/workshops/.
# Then the site is rendered with the safe build: the live site changes only if the
# build succeeds.
#
#   ./publish.sh            copy + build (goes live)
#   ./publish.sh --copy     copy only, no build
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
site=$HOME/webstack/site

mkdir -p "$site/workshops"
cp "$here/workshops-index.qmd" "$site/workshops/index.qmd"
for articles in "$here"/common/*/articles; do
    [[ -d $articles ]] || continue
    topic=$(basename "$(dirname "$articles")")
    mkdir -p "$site/workshops/$topic"
    rsync -a --delete --exclude '.quarto/' "$articles/" "$site/workshops/$topic/"
    echo "Copied common/$topic/articles -> site/workshops/$topic"
done

[[ ${1:-} == --copy ]] && exit 0
cd "$HOME/webstack"
docker compose run --rm build
