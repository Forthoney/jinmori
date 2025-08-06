#!/bin/sh
set -e

while true; do
  echo "This script must be run in the root directory of Jinmori. Do you want to continue? [y/n] "
  read answer
  case "$answer" in
    y ) echo "Continuing..."; break;;
    n ) echo "Aborting."; exit 1;;
    * ) echo "Invalid answer.";;
  esac
done

jinmori_home="$HOME/.jinmori"
mkdir "$jinmori_home" "$jinmori_home/pkg" "$jinmori_home/bin" deps

dest="$jinmori_home/pkg/medjool"
git clone --branch v0.1.1 --depth 1 https://github.com/Forthoney/medjool.git "$dest"
ln --symbolic "$dest" "deps/medjool"

bin_dest="build/jinmori.dbg"
mlton -output "$bin_dest" -const 'Exn.keepHistory true' src/jinmori.mlb
echo "jinmori binary saved at '$bin_dest'"

echo "Consider adding '$jinmori_home/bin' to your path. Otherwise, you can run jinmori by running"
echo "$bin_dest --help"
echo "in your shell"
