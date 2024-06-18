#!/bin/bash
clear

URL_DEB_REPO=https://ftp.debian.org/debian
VERSION=""
ARCH=""

# Check parameters
if [ "$#" -ne 2 ]; then
	echo "USAGE: $0 <version> <arch>"
	echo "       $0 bookworm armhf"
	exit 1
else
	VERSION=$1
	ARCH=$2	
fi

# 0 FTP Main resources => ALL EXCEPT <pool> FOLDER
[ ! -d ./debian ] && mkdir -p ./debian
wget --recursive --no-parent https://ftp.debian.org/debian/dists/bookworm/
wget --recursive --no-parent https://ftp.debian.org/debian/dists/bookworm-updates/
wget --recursive --no-parent https://ftp.debian.org/debian/doc/
wget --recursive --no-parent https://ftp.debian.org/debian/indices/
wget --recursive --no-parent https://ftp.debian.org/debian/project/
wget --recursive --no-parent https://ftp.debian.org/debian/tools/
wget --recursive --no-parent https://ftp.debian.org/debian/zzz-dists/
mv ./ftp.debian.org/debian/* ./debian/
rm -rf ./ftp.debian.org

# 1 - Obtain the Packages file for this config
PACKAGES_GZ=$URL_DEB_REPO"/dists/$VERSION/main/binary-$ARCH/Packages.gz"
[ ! -f ./Packages.gz ] && wget $PACKAGES_GZ
gzip -d Packages.gz

# 2 - Get packages routes to wget from ftp
cat Packages | grep "Filename:" > Packages_filenames.txt

# 3 - mkdir dest folder
mkdir -p ./pool/main

# 4 - Get folder structure and download Packages
while read -r line; do
	WITHOUT_FILENAME=$(echo $line | sed 's/Filename: //')
	FOLDER="${WITHOUT_FILENAME%/*}"
	DEBNAME=$(basename ${WITHOUT_FILENAME})
	FULL_URL=$URL_DEB_REPO/$WITHOUT_FILENAME
	
	mkdir -p $FOLDER && cd $FOLDER
	
	# DOWNLOAD ONLY IF DONT EXIST!
	[ ! -f $DEBNAME ] && wget $FULL_URL
	cd - >/dev/null 2<&1
	
done < Packages_filenames.txt

echo "[INFO] The End."
exit 0

