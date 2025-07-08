#!/bin/bash

REPO="THZoria/NX_Firmware"
DIST_DIR="dist"

mkdir -p "$DIST_DIR"

releases=$(curl -s "https://api.github.com/repos/$REPO/releases")

if [ -z "$releases" ]; then
  echo "github api error"
  exit 1
fi

version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]
}

echo "$releases" | jq -r '.[] | select(.tag_name | test("Firmware \\d+\\.\\d+\\.\\d+")) | .tag_name' | while read -r tag; do
  echo "release tag: $tag"

  assets=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$tag" | jq -r '.assets[] | .browser_download_url')

  if [ -z "$assets" ]; then
    echo "not found assets"
    continue
  fi

  # release_dir="$DIST_DIR/$tag"
  # mkdir -p "$release_dir"

  if [[ $tag =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    while IFS= read -r url; do
      filename=$(basename "$url")
      echo "downloading: $filename"
      curl -L -o "$DIST_DIR/$filename" "$url"
      if [ $? -eq 0 ]; then
        echo "download: $filename"
      else
        echo "error: $filename"
      fi
    done <<< "$assets"
  fi

done

ls -lh $DIST_DIR