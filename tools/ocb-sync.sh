#!/bin/sh
# This script is meant to keep the github OCA/OCB and odoo/odoo in sync.
# Technically, it simply merges odoo into the repective branch in OCB, thereby
# keeping commit identifiers stable (that as opposed to a rebase approach,
# where commit hashes are rewritten)
# The following variables can be overriden by a file called ocb-sync.sh.conf
# in the same directory as this file.

ODOO="git@github.com:/odoo/odoo.git"
OCB="git@github.com:/OCA/OCB.git"
BRANCHES="13.0 12.0 11.0 10.0 9.0 8.0 7.0"
GITDIR="/var/tmp/git"
PUBDIR="/var/tmp/ocb-nightly"
BUILDDIR="/var/tmp/ocb-build"

if [ -f $(dirname $0)/$(basename $0).conf ]; then
    . $(dirname $0)/$(basename $0).conf
fi
if [ ! -d $GITDIR ]; then
    mkdir -p $GITDIR
fi
cd $GITDIR
if [ ! -d $(basename $OCB .git) ]; then
    git clone $OCB
    cd $(basename $OCB .git)
    git remote add odoo $ODOO
    cd ..
fi

cd $(basename $OCB .git)
git fetch --all
for BRANCH in $BRANCHES; do
    git checkout origin/$BRANCH -B $BRANCH
    git pull --ff-only
    git merge --no-edit odoo/$BRANCH || exit 1
    git push -u origin HEAD:$BRANCH || exit 1
    cd setup || exit 1
    python package.py --no-testing --no-debian --no-rpm --no-windows -b $BUILDDIR -p $PUBDIR/$BRANCH || exit 1
    cd ..
done
exit 0
