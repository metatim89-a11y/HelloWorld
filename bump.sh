#!/data/data/com.termux/files/usr/bin/bash

VERSION_FILE="VERSION"

v=$(cat $VERSION_FILE)

IFS='.' read -r major minor patch <<< "$v"

patch=$((patch+1))

new="$major.$minor.$patch"

echo $new > $VERSION_FILE

git add .
git commit -m "v$new - update"
git tag "v$new"
git push
git push --tags

echo "🚀 Version bumped to $new"
