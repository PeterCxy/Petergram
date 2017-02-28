#!/bin/bash
RED='\033[0;31m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'
NC='\033[0m'
function error() { echo -e "${WHITE}==> ${RED}E: ${WHITE}${1}${NC}"; }
function info() { echo -e "${WHITE}==> ${BLUE}I: ${WHITE}${1}${NC}"; }

__PWD="$PWD"
WORKDIR="${PWD}/work"
ORIG_APK="${WORKDIR}/orig.apk"
ORIG_DIR="${WORKDIR}/orig"
ORIG_BAK="${WORKDIR}/orig_bak"
APKMIRROR_BASE="https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id="
source ./project.conf

function initialize() {
    if [[ -d "$WORKDIR" ]]; then
        error "Directory ${WORKDIR} already exists. Aborting."
        exit 1
    fi
    mkdir -p $WORKDIR
    local url="$APKMIRROR_BASE$APKMIRROR_ID"
    info "Downloading $url"
    curl -L "$url" > "$ORIG_APK"
    if [[ $? != 0 ]] || [[ ! -e "$ORIG_APK" ]]; then
        error "Download failure. Aborting."
        exit 1
    fi
    info "Decompling the original apk file."
    apktool d "$ORIG_APK" -o "$ORIG_DIR"
    if [[ $? != 0 ]] || [[ ! -d "$ORIG_DIR" ]]; then
        error "Decompile failure. Aborting."
        exit 1
    fi
    info "Backing up the original files and applying patches."
    cp -R "$ORIG_DIR" "$ORIG_BAK"
    patch "$ORIG_DIR/AndroidManifest.xml" < AndroidManifest.patch
    if [[ $? != 0 ]]; then
        error "Failed to apply some patches for AndroidManifest. You should resolve them later."
    fi
    pushd "$ORIG_DIR" > /dev/null
    patch -p1 < "${__PWD}/smali.patch"
    if [[ $? != 0 ]]; then
        error "Failed to apply some patches for smali code. You should resolve them later."
    fi
    popd > /dev/null
    info "Deleting unneeded files."
    for file in $(cat files.remove); do 
        rm -rf "$ORIG_DIR/$file"
    done
    info "Copying added files."
    for file in $(cat files.copy); do
        cp -R "$PWD/$file" "$ORIG_DIR/$file"
    done
    info "The code is now ready in $ORIG_DIR. If any conflict occurred, please resolve them now."
    info "After making modifications, use 'build.sh package' to build the package. Use 'build.sh update-patches' to generate a new patchset."
}

function clean() {
    info "Cleaning up."
    rm -rf work
}

case "$1" in
    clean)
        clean
        ;;
    initialize)
        initialize
        ;;
esac