#!/bin/bash
clear

URL_DEB_REPO=https://ftp.debian.org/debian
URL_UBU_REPO=http://es.archive.ubuntu.com/ubuntu/

URL_REPO=""
VERSION=""
ARCH=""

# Check parameters
if [ "$#" -ne 2 ]; then
	printf "usage: $0 <ARCHITECTURE> <VERSION>\n"
	#echo "       $0 bookworm armhf"
	printf "\n  ARCHITECTURE can be:\n\t-amd64\n\t-arm64\n\t-armel\n\t-armhf\
		\n\t-i386\n\t-mips64el\n\t-mipsel\n\t-ppc64el\n\t-s390x\n"
	printf "\n  DEBIAN VERSION can be:\n\t-bookworm\n\t-bullseye\n\t-buster\n\t-trixie\n"
	printf "\n  UBUNTU VERSION can be:\n\t-bionic\n\t-focal\n\t-jammy\n\t-lunar\
		\n\t-mantic\n\t-noble\n\t-oracular\n\t-trusty\n\t-xenial\n"
	exit 1
else
	ARCH=$1
	VERSION=$2

	if [ "$2" = "bookworm" ] || [ "$2" = "bullseye" ] || [ "$2" = "buster" ] ||\
	   [ "$2" = "trixie" ]; then
		URL_REPO=$URL_DEB_REPO
		[ ! -d ./$VERSION\_$ARCH/debian ] && mkdir -p ./$VERSION\_$ARCH/debian
	elif [ "$2" = "bionic" ] || [ "$2" = "focal" ] || [ "$2" = "jammy" ] ||\
	     [ "$2" = "lunar" ] || [ "$2" = "mantic" ] || [ "$2" = "noble" ] ||\
	     [ "$2" = "oracular" ] || [ "$2" = "trusty" ] || [ "$2" = "xenial" ]; then
		URL_REPO=$URL_UBU_REPO
		[ ! -d ./$VERSION\_$ARCH/ubuntu ] && mkdir -p ./$VERSION\_$ARCH/ubuntu
	else
		echo "[ERROR] Version not found."
		exit 2
	fi
fi


# 0 FTP Main resources => ALL EXCEPT <pool> FOLDER
wget --recursive --no-parent $URL_REPO/dists/$VERSION/
wget --recursive --no-parent $URL_REPO/dists/$VERSION-updates/
#wget --recursive --no-parent $URL_REPO/doc/
wget --recursive --no-parent $URL_REPO/indices/
wget --recursive --no-parent $URL_REPO/project/
#wget --recursive --no-parent $URL_REPO/tools/
#wget --recursive --no-parent $URL_REPO/zzz-dists/
[ -d ./ftp.debian.org ] mv ./ftp.debian.org/debian/* ./$VERSION\_$ARCH/debian/ && rm -rf ./ftp.debian.org
[ -d ./es.archive.ubuntu.com ] mv ./es.archive.ubuntu.com/ubuntu/* ./$VERSION\_$ARCH/ubuntu/ && rm -rf ./es.archive.ubuntu.com


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

