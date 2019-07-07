buildAndDeploy.sh
====================

builds all targets for gluon (disk space needed: ~ 7 GB each)
You need to change the variables at the beginning of the script according to your needs.

## Install:
```
sudo apt install git make gcc g++ unzip libncurses5-dev zlib1g-dev subversion gawk bzip2 libssl-dev ecdsautils
git clone https://github.com/freifunk-gluon/gluon.git
git checkout v2018.2.2 #or something else
cd gluon
# adapt your site
make update
./buildAndDeploy.sh
```
tip: call this script through ccze: `./buildAndDeploy.sh | ccze -A`

The gluon autoupdater only works with signed images. For this it uses the ECDSA-Utils. How to use it can be found [here](https://wiki.freifunk.net/ECDSA_Util#Programme_und_Optionen_der_ECDSA-Utils).
