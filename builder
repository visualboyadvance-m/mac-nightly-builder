#!/usr/local/bin/reattach-to-user-namespace /usr/local/bin/bash

set -e

mkdir -p ~/logs

case "$1" in
    *f*)
        force=1
        ;;
esac

{
    cd ~/source/repos/nightly-visualboyadvance-m
    git fetch --all --prune
    if [ -z "$force" ] && git status | grep -q '^Your branch is up to date with'; then
        echo 'INFO: No changes to build.'
        exit 0
    fi
    git pull --rebase

    # Unlock login keychain for codesigning certificate.
    security unlock-keychain -p 'Vbam3***' login.keychain || :

    cd ~
    ~/source/repos/nightly-visualboyadvance-m/tools/osx/builder

    scp ~/vbam-build-mac-64bit/project/release/visualboyadvance-m-Mac-x86_64.zip \
        ~/vbam-build-mac-64bit/project/debug/visualboyadvance-m-Mac-x86_64-debug.zip \
        win.vba-m.com:/inetpub/wwwroot/nightly

} 2>&1 | tee -a ~/logs/builder.log

# vim:sw=4 et:
