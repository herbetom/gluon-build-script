#!/bin/bash

# builds all targets for gluon (disk space needed: ~ 7 GB each)
#
# Install:
#
# sudo apt-get install git make gcc g++ unzip libncurses5-dev zlib1g-dev subversion gawk bzip2 libssl-dev ecdsautils
# git clone https://github.com/freifunk-gluon/gluon.git
# cd gluon
# # adapt your site
# make update
# ./buildAndDeploy.sh
# 
# tip: call this script through ccze: ./buildAndDeploy.sh | ccze -A
# 
# the gluon autoupdater only works with signed images. How to generate the private key: https://wiki.freifunk.net/ECDSA_Util#ecdsakeygen

# Configuration
GLUON_RELEASE="1.2.x-"$(date '+%Y%m%d-%H%M')""
GLUON_BRANCH="nightly"
IMAGEDEPLOYFOLDER="/var/www/gluon-firmware-selector/images/"$GLUON_BRANCH"/"
PACKAGESDEPLOYFOLDER="/var/www/opkgmirror/modules/"
LOGFILE=/tmp/gluon-build-log-$GLUON_RELEASE.log
SECRET=/home/ffrn/secret
BROKEN=0

#T="ar71xx-generic brcm2708-bcm2708 brcm2708-bcm2709 x86-64"
T="$(make list-targets BROKEN=$BROKEN)" # build all available

if [[ $EUID -eq 0 ]]; then 
  echo "cannot be run as root" | tee $LOGFILE
  exit
fi

start_timestamp=$(date +%s)
echo "################# $(date) started script ###########################" | tee $LOGFILE

# detect amount of CPU cores
NUM_CORES_PLUS_ONE=$(expr $(nproc) + 1) 
echo "Number of cores used: " $NUM_CORES_PLUS_ONE | tee -a $LOGFILE

for TARGET in $T; do
  trap ": user abort; exit;" SIGINT SIGTERM # so CTRL+C will exit the loop
  echo "################# $(date) start building target $TARGET ###########################" | tee -a $LOGFILE
  start=$(date +%s)

  make clean BROKEN=$BROKEN GLUON_TARGET=$TARGET | tee -a $LOGFILE
  make -j$NUM_CORES_PLUS_ONE GLUON_BRANCH=$GLUON_BRANCH GLUON_RELEASE=$GLUON_RELEASE BROKEN=$BROKEN GLUON_TARGET=$TARGET | tee -a $LOGFILE || exit 1 

  echo "time for $TARGET: "$((($(date +%s)-$start)/60))":"$((($(date +%s)-$start)%60))" Minuten" | tee -a $LOGFILE
  let i++
done && : "all targets created in folder output/images/" | tee -a $LOGFILE
echo "total runtime: "$((($(date +%s)-$start_timestamp)/60))":"$((($(date +%s)-$start_timestamp)%60))" Minuten" | tee -a $LOGFILE

make manifest GLUON_BRANCH=$GLUON_BRANCH GLUON_RELEASE=$GLUON_RELEASE BROKEN=$BROKEN | tee -a $LOGFILE

if contrib/sign.sh $SECRET output/images/sysupgrade/$GLUON_BRANCH.manifest | tee -a $LOGFILE; then
  echo "removing all content from "$IMAGEDEPLOYFOLDER""
  rm -rf $IMAGEDEPLOYFOLDER
  echo "copying generated images to "$IMAGEDEPLOYFOLDER""
  rsync -a --info=progress2 output/images/ $IMAGEDEPLOYFOLDER | tee -a $LOGFILE
  echo "copying generated packages to "$PACKAGESDEPLOYFOLDER""
  rsync -a --info=progress2 output/packages/ $PACKAGESDEPLOYFOLDER | tee -a $LOGFILE
fi

echo "################# $(date) finished script ###########################" | tee -a $LOGFILE
