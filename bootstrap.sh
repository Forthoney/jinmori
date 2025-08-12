#!/bin/sh
set -e

while true; do
  echo "This script must be run in the root directory of Jinmori. Do you want to continue? [y/n]"
  read answer
  case "$answer" in
    y ) echo "Continuing..."; break;;
    n ) echo "Aborting."; exit 1;;
    * ) echo "Invalid answer.";;
  esac
done

jinmori_home="$HOME/.jinmori"
mkdir "$jinmori_home" "$jinmori_home/pkg" "$jinmori_home/bin" deps build

dest="$jinmori_home/pkg/medjool"
git clone --branch v0.1.1 --depth 1 https://github.com/Forthoney/medjool.git "$dest"
ln -s "$dest" "deps/medjool"

dbg="build/jinmori.dbg"
mlton -output "$dbg" -const 'Exn.keepHistory true' src/jinmori.mlb
echo "Bootstrapped, debug mode jinmori binary saved at '$dbg'"

release="build/jinmori"
build/jinmori.dbg build --release
echo "Built release mode jinmori binary at '$release'"

while true; do
  echo "Would you like to copy '$release' into '$jinmori_home/bin'? This is where jinmori will save installed commands by default. [y/n]"
  read answer
  case "$answer" in
    y )
      cp "$release" "$jinmori_home/bin/jinmori"
      printf "Consider adding '$jinmori_home/bin' to your path. "
      release="$jinmori_home/bin/jinmori"
      break;;
    n ) break;;
    * ) echo "Invalid answer.";;
  esac
done
    
echo "You can now run jinmori by running"
echo "$release --help"
echo "in your shell"
