
#!/bin/bash

NAME="Unstack2"
GAME_VERSION=`git tag|tail -1`
REVISION=`git log ${GAME_VERSION}..HEAD --oneline | wc -l | sed -e 's/ //g'`
GAME_VERSION=${GAME_VERSION}.${REVISION}
FILENAME="$NAME-$GAME_VERSION"
BUILD="`pwd`/build"
corona="/Applications/gamedev/CoronaSDK/Corona Simulator.app/Contents/MacOS/Corona Simulator"

echo "Building $FILENAME"
# Take HEAD make an archive of it
git archive HEAD -o "$BUILD/$FILENAME.zip"

cd "$BUILD"
rm -R "$FILENAME"
unzip "$FILENAME.zip" -d "$FILENAME"
cd "$BUILD/$FILENAME"

# files that don't go into the git repo
cp -R ../../conf .

moonc .
find . -name "*.moon" -exec ls {} \;
GOOGLE_VERSION=`echo $GAME_VERSION | sed -e 's/\\.//g'`
sed -i.bak s/VERSION/$GOOGLE_VERSION/ build.settings


echo "return '${GAME_VERSION}'" > "version.lua"

exec "$corona" main.lua
