#!/bin/sh

set -e

unset LANG LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME LC_ALL
export LC_ALL=C
export TZ=UTC

export BUILDER_CHECKOUT=$HOME/source/repos/mac-builder-visualboyadvance-m
export CHECKOUT=$HOME/source/repos/nightly-visualboyadvance-m
export BUILD_ROOT_SUFFIX=-nightly

mkdir -p ~/logs

case "$1" in
    *f*)
        force=1
        ;;
esac

{
    date

    cd "$CHECKOUT"

    git fetch --all --prune

    head=$(git rev-parse --short HEAD)
    current=$(git rev-parse --short origin/master)

    sources_changed=$(
        git diff --name-only "${head}..${current}" \
            | grep -cE 'cmake|CMake|\.(c|cpp|h|in|xrc|xml|rc|cmd|xpm|ico|icns|png|svg)$' || : \
    )

    translations_changed=$(
        git diff --name-only "${head}..${current}" \
            | grep -cE 'cmake|CMake|\.po$' || : \
    )

    # Write date and time for beginning of check/build.
    date

    if [ -z "$force" ] && [ "$sources_changed" -eq 0 ] && [ "$translations_changed" -eq 0 ]; then
        echo 'INFO: No changes to build.'
        exit 0
    fi
    git pull --rebase

    # Unlock login keychain for codesigning certificate.
    security unlock-keychain -p "$(cat ~/.login-keychain-password)" login.keychain || :

    cd "$BUILDER_CHECKOUT"
#    git pull --rebase
    git fetch --all --prune
    git checkout master
    git pull --rebase
    git branch -D mac-arm64
    git checkout mac-arm64

    cd ~
    $BUILDER_CHECKOUT/tools/macOS/builder

    # Reset the .pot file after build, it can block later pulls.
    cd "$CHECKOUT"
    git checkout -f HEAD -- po/wxvbam/wxvbam.pot

    cd ~
    rm -rf ~/nightly-stage
    mkdir -p ~/nightly-stage

    cp ~/"vbam-build-mac-64bit$BUILD_ROOT_SUFFIX"/project/release/visualboyadvance-m-Mac-*.zip \
        ~/"vbam-build-mac-64bit$BUILD_ROOT_SUFFIX"/project/debug/visualboyadvance-m-Mac-*-debug.zip \
        ~/nightly-stage

    cd ~/nightly-stage
    for z in *.zip; do
        printf '%s\n%s\n' "put $z" "chmod 664 $z" | sftp sftpuser@posixsh.org:nightly.visualboyadvance-m.org/
    done

} 2>&1 | tee -a ~/logs/builder.log

# vim:sw=4 et ft=sh:
