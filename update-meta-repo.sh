#!/bin/sh -euf

seed_dir=$(readlink -f "$(dirname "$0")")

if [ $# -lt 1 ]; then
    echo "Usage: $0 <meta-repo>"
    exit 1
fi

meta_repo=$1
cd "$meta_repo"

if [ -d ./seeds ]; then
    rm -rvf ./seeds
fi
mkdir ./seeds

base_dist="$(python3 -c '
import configparser

config = configparser.ConfigParser()
config.read("update.cfg.in")
print(config["DEFAULT"]["dist"])
')"
platform_seed="./seeds/platform.${base_dist}"
git clone \
    --depth 1 --branch "$base_dist" \
    https://git.launchpad.net/~ubuntu-core-dev/ubuntu-seeds/+git/platform \
    "$platform_seed"

ln -sv "$seed_dir" "./seeds/ubuntu-touch.${base_dist}"

exec ./update
