#!/bin/bash
clear

URL_DEB_REPO=https://ftp.debian.org/debian
URL_UBU_REPO=http://es.archive.ubuntu.com/ubuntu/

URL_REPO=""
VERSION=""
ARCH=""
CLONE_DIR="./"

# Check parameters
if [ "$#" -ne 3 ]; then
	printf "usage: $0 <ARCHITECTURE> <VERSION> <CLONE_DIRECTORY>\n"
	#echo "       $0 bookworm armhf"
	printf "\n  ARCHITECTURE can be:\n\tamd64\n\tarm64\n\tarmel\n\tarmhf\
		\n\ti386\n\tmips64el\n\tmipsel\n\tppc64el\n\ts390x\n"
	printf "\n  DEBIAN VERSION can be:\n\tbookworm\n\tbullseye\n\tbuster\n\ttrixie\n"
	printf "\n  UBUNTU VERSION can be:\n\tbionic\n\tfocal\n\tjammy\n\tlunar\
		\n\tmantic\n\tnoble\n\toracular\n\ttrusty\n\txenial\n"
	exit 1
else
	ARCH=$1
	VERSION=$2
	CLONE_DIR=$3

	if [ "$2" = "bookworm" ] || [ "$2" = "bullseye" ] || [ "$2" = "buster" ] ||\
	   [ "$2" = "trixie" ]; then

		# It's DEBIAN
		URL_REPO=$URL_DEB_REPO
		[ ! -d $CLONE_DIR/ftp.debian.org ] && mkdir -p $CLONE_DIR/ftp.debian.org
		[ ! -e ./ftp.debian.org ] && ln -s $CLONE_DIR/ftp.debian.org ./ftp.debian.org
		[ ! -d $CLONE_DIR/$VERSION\_$ARCH/debian ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH/debian
		[ ! -e ./debian ] && ln -s $CLONE_DIR/$VERSION\_$ARCH/debian ./debian

	elif [ "$2" = "bionic" ] || [ "$2" = "focal" ] || [ "$2" = "jammy" ] ||\
	     [ "$2" = "lunar" ] || [ "$2" = "mantic" ] || [ "$2" = "noble" ] ||\
	     [ "$2" = "oracular" ] || [ "$2" = "trusty" ] || [ "$2" = "xenial" ]; then

		# It's UBUNTU
		URL_REPO=$URL_UBU_REPO
		[ ! -d $CLONE_DIR/es.archive.ubuntu.com ] && mkdir -p $CLONE_DIR/es.archive.ubuntu.com
		[ ! -e ./es.archive.ubuntu.com ] && ln -s $CLONE_DIR/es.archive.ubuntu.com ./es.archive.ubuntu.com
		[ ! -d $CLONE_DIR/$VERSION\_$ARCH/ubuntu ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH/ubuntu
		[ ! -e ./ubuntu ] && ln -s $CLONE_DIR/$VERSION\_$ARCH/ubuntu ./ubuntu
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
[ -e ./ftp.debian.org ] && mv ./ftp.debian.org/debian/* ./debian/ && rm -rf ./ftp.debian.org && rm -rf $CLONE_DIR/ftp.debian.org
[ -e ./es.archive.ubuntu.com ] && mv ./es.archive.ubuntu.com/ubuntu/* ./ubuntu/ && rm -rf ./es.archive.ubuntu.com && rm -rf $CLONE_DIR/es.archive.ubuntu.com


# 1 - Obtain the Packages file for this config
PACKAGES_GZ=$URL_REPO"/dists/$VERSION/main/binary-$ARCH/Packages.gz"
[ ! -f ./Packages.gz ] && wget $PACKAGES_GZ
gzip -d Packages.gz

# 2 - Get packages routes to wget from ftp
cat Packages | grep "Filename:" > Packages_filenames.txt

# 3 - mkdir dest folder
if [ "$URL_REPO" = "$URL_DEB_REPO" ]; then
	mkdir -p ./debian/pool/main
	ln -s ./debian/pool pool
elif [ "$URL_REPO" = "$URL_UBU_REPO" ];then
	mkdir -p ./ubuntu/pool/main
	ln -s ./ubuntu/pool pool
fi

# 4 - Get folder structure and download Packages
while read -r line; do
	WITHOUT_FILENAME=$(echo $line | sed 's/Filename: //')
	FOLDER="${WITHOUT_FILENAME%/*}"
	DEBNAME=$(basename ${WITHOUT_FILENAME})
	FULL_URL=$URL_REPO/$WITHOUT_FILENAME
	
	mkdir -p $FOLDER && cd $FOLDER
	
	# DOWNLOAD ONLY IF DONT EXIST!
	[ ! -f $DEBNAME ] && wget $FULL_URL
	cd - >/dev/null 2<&1

done < Packages_filenames.txt

# Clean-up Time!
rm -rf Packages_filenames.txt Packages
find . -maxdepth 1 -type l -delete

echo "[INFO] The End."
exit 0

