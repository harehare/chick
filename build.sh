#!/bin/bash

set -ex

DIST=chick-dist

yarn production && cd clojure && lein cljsbuild once prod && cd ..

rm -rf $DIST
mkdir -p $DIST/clojure/compiled
cp manifest.json $DIST
cp clojure/compiled/main.js $DIST/clojure/compiled/
cp -r dist $DIST
cp -r popup $DIST
cp -r option $DIST
cp -r img $DIST
cp chick.png $DIST

sed -i.bak 's/compiled-dev/compiled/g' $DIST/manifest.json
cd $DIST && zip -r chick.zip *
