#!/bin/bash

DIR=$(dirname $(readlink -f $0)) # Directory script is in
cd $DIR/libs/

function fail() {
  echo "Error: $@"
  exit 1
}

function get() {
  if [ -d "$2" ]; then
    cd $2        || fail "$DIR/libs/$2 does not exist."
    git pull     || fail "Could not update $1/$2"
    cd $DIR/libs || fail "$DIR/libs disappeared? Stop playing tricks on me."
  else
    git clone "https://github.com/$1/$2" || fail "Could not clone $1"
  fi
}

get nddrylliog    'zombieconfig'
get nddrylliog    'ooc-gobject'
get eagle2com     'ooc-sdl'
get nddrylliog    'ooc-cairo'
get fredreichbier 'deadlogger'
get nddrylliog    'ooc-rsvg'
get nddrylliog    'ooc-freetype2'

echo
echo "Everything is up to date. Now run \`source devrc\`"
