#!/bin/bash

DIST_DIR=dist
mkdir -p $DIST_DIR


keys=("https://files.prodkeys.net/ProdKeys.net-v20.0.1.zip" "https://files.prodkeys.net/ProdKeys.net-v20.0.0.zip" "https://files.prodkeys.net/ProdKeys.net-v19.0.1.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Prodkeys.net_v19.0.0.zip" "https://files-prodkeys.b-cdn.net/prodkeys/ProdKeys.net-v18.-1-0.zip" "https://files-prodkeys.b-cdn.net/prodkeys/prodkeys.net-18-0-1.zip" "https://files-prodkeys.b-cdn.net/prodkeys/ProdKeys.net-v18.0.0.zip" "https://files-prodkeys.b-cdn.net/prodkeys/prodkeys.net-v17.0.1.zip" "https://files-prodkeys.b-cdn.net/prodkeys/ProdkKeys.net-V17.0.0.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Prodkeys.net-V16.1.0.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Keys-16.0.3-By-Prodkeys.net_.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Keys-16.0.2-By-Prodkeys.net_.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Keys-16.0.1.zip" "https://files-prodkeys.b-cdn.net/prodkeys/Keys-16-by-Prodkeys.net_.zip")

for url in "${keys[@]}"; do
    curl -s -L "$url" -o "$DIST_DIR/$(basename "$url")"
done

function version_ge() {
    local v1=(${1//./ })
    local v2=(${2//./ })
    local len=${#v1[@]}
    if [ ${#v2[@]} -gt ${#v1[@]} ]; then
        len=${#v2[@]}
    fi
    for ((i=0; i<len; i++)); do
        local p1=${v1[i]:-0}
        local p2=${v2[i]:-0}
        if [ "$p1" -lt "$p2" ]; then
            return 1
        elif [ "$p1" -gt "$p2" ]; then
            return 0
        fi
    done
    return 0
}

releases=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/THZoria/NX_Firmware/releases?per_page=100")

if [ $? -ne 0 ]; then
    echo "release not found"
    exit 1
fi

echo "$releases" | jq -c '.[]' | while read -r release; do
    tag_name=$(echo "$release" | jq -r '.tag_name')
    echo $tag_name
    version=$(echo "$tag_name" | sed -E 's/^([0-9]+(\.[0-9]+)*).*/\1/')
    echo $version

    if [[ -z "$version" ]]; then
        echo "version error"
        continue
    fi

    if version_ge "$version" "16.0.0"; then
        asset_name="Firmware.${tag_name}.zip"
        echo $asset_name
        asset_url=$(echo "$release" | jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url")

        if [ -n "$asset_url" ]; then
            echo "downloading $asset_name from $asset_url"
            curl -s -L -H "Authorization: token $GITHUB_TOKEN" "$asset_url" -o "$DIST_DIR/$asset_name"
            if [ $? -eq 0 ]; then
                echo "successfully download $asset_name"
            else
                echo "failed download $asset_name"
            fi
        else
            echo "not found $asset_name at $tag_name"
        fi
    else
        echo "skip $tag_name (version $version < 16.0.0)"
        break
    fi
done

ls -lh $DIST_DIR