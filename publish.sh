#!/usr/bin/env bash
# Publish the shared course articles to dynanet.dev.
#
# For every workshop folder <workshop>/lab-manual/, the folder is copied to
# ~/webstack/site/workshops/<address>/ (replaced each time, so edit HERE, never in
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
# Website address of each workshop, when it differs from its folder name.
declare -A address=([clab-workshop]=containerlab)
for manual in "$here"/*/lab-manual; do
    [[ -d $manual ]] || continue
    workshop=$(basename "$(dirname "$manual")")
    target=${address[$workshop]:-$workshop}
    mkdir -p "$site/workshops/$target"
    rsync -a --delete --exclude '.quarto/' "$manual/" "$site/workshops/$target/"
    echo "Copied $workshop/lab-manual -> site/workshops/$target"
done

[[ ${1:-} == --copy ]] && exit 0
cd "$HOME/webstack"
docker compose run --rm build
