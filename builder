#!/usr/local/bin/reattach-to-user-namespace /usr/local/bin/bash -l

set -e

unset LANG LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME LC_ALL
export LANG=C
export TZ=UTC

mkdir -p ~/logs

case "$1" in
    *f*)
        force=1
        ;;
esac

{
    date

    cd ~/source/repos/nightly-visualboyadvance-m

    git fetch --all --prune

    head=$(git rev-parse --short HEAD)
    current=$(git rev-parse --short origin/master)

    sources_changed=$(
        git diff --name-only "${head}..${current}" \
            | grep -cE 'cmake|CMake|\.(c|cpp|h|in|xrc|xml|rc|cmd|xpm|ico|icns|png|svg)$' \
    )

    # Write date and time for beginning of check/build.
    date

    if [ -z "$force" ] && [ "$sources_changed" -eq 0 ]; then
        echo 'INFO: No changes to build.'
        exit 0
    fi
    git pull --rebase

    # Unlock login keychain for codesigning certificate.
    security unlock-keychain -p 'Vbam3***' login.keychain || :

    cd ~
    ~/source/repos/nightly-visualboyadvance-m/tools/osx/builder

    rm -rf ~/nightly-stage
    mkdir -p ~/nightly-stage

    cp ~/vbam-build-mac-64bit/project/release/visualboyadvance-m-Mac-x86_64.zip \
        ~/vbam-build-mac-64bit/project/debug/visualboyadvance-m-Mac-x86_64-debug.zip \
        ~/nightly-stage

    cd ~/nightly-stage
    for z in *.zip; do
        printf '%s\n%s\n' "put $z" "chmod 664 $z" | sftp sftpuser@posixsh.org:nightly.vba-m.com/
    done

} 2>&1 | tee -a ~/logs/builder.log

# vim:sw=4 et ft=sh:
