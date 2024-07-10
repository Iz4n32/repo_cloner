#!/bin/bash
clear

URL_DEB_REPO=https://ftp.debian.org/debian
URL_DEB_ARCHI=http://archive.debian.org/debian
URL_UBU_REPO=http://es.archive.ubuntu.com/ubuntu
URL_UBU_PORTS=http://ports.ubuntu.com
URL_REPO=""

ARCH=$1
VERSION=$2
CLONE_DIR=$3

function make_directories {
	mkdir -p ./$1/pool/main
	mkdir -p ./$1/pool/multiverse
	mkdir -p ./$1/pool/restricted
	mkdir -p ./$1/pool/universe
	ln -s ./$1/pool pool
}

function download_Packages {
	VER=$1
	POOL_SUBDIR=$2

	[ -f ./Packages ] && rm -rf Packages_filenames.txt Packages

	PACKAGES_GZ=$URL_REPO"/dists/$VER/$POOL_SUBDIR/binary-$ARCH/Packages.gz"
	wget $PACKAGES_GZ
	gzip -d Packages.gz && cat Packages | grep "Filename:" > Packages_filenames.txt

	while read -r line; do
		WITHOUT_FILENAME=$(echo $line | sed 's/Filename: //')
		FOLDER="${WITHOUT_FILENAME%/*}"
		DEBNAME=$(basename ${WITHOUT_FILENAME})
		FULL_URL=$URL_REPO/$WITHOUT_FILENAME

		[ ! -d "$FOLDER" ] && mkdir -p $FOLDER
		cd $FOLDER

		# DOWNLOAD ONLY IF DONT EXIST!
		[ ! -f $DEBNAME ] && wget $FULL_URL
		cd - >/dev/null 2<&1

	done < Packages_filenames.txt
}

#################################################
# 1 Check parameters
#################################################
if [ "$#" -ne 3 ]; then
	printf "usage: $0 <ARCHITECTURE> <VERSION> <CLONE_DIRECTORY>\n"
	printf "\n  ARCHITECTURE can be:\n\tamd64 arm64 armel armhf i386 mips64el mipsel ppc64el s390x powerpc\n"
	printf "\n  DEBIAN VERSION can be:\n\tbookworm\n\tbullseye\n\tbuster\n\ttrixie\
		\n\tjessie\n\twheezy\n\tsqueeze\n\tlenny\n"
	printf "\n  UBUNTU VERSION can be:\n\tbionic\n\tfocal\n\tjammy\n\tlunar\
		\n\tmantic\n\tnoble\n\toracular\n\ttrusty\n\txenial\n"
	exit 1
fi

#################################################
# 2 Identify VERSION Debian / Ubuntu && do Folders & Links
#################################################

# DEBIAN
if [ "$VERSION" = "bookworm" ] || [ "$VERSION" = "bullseye" ] || [ "$VERSION" = "buster" ] ||\
   [ "$VERSION" = "trixie" ]; then

	if [ "$ARCH" != "amd64" ] &&\
	   [ "$ARCH" != "arm64" ] && [ "$ARCH" != "armel" ] &&\
	   [ "$ARCH" != "armhf" ] && [ "$ARCH" != "i386" ] &&\
	   [ "$ARCH" != "mips64el" ] && [ "$ARCH" != "mipsel" ] &&\
	   [ "$ARCH" != "ppc64el" ] && [ "$ARCH" != "s390x" ]; then
		echo "[ERROR] arch:$ARCH is not available in DEBIAN $VERSION"
		exit 2
	fi

	URL_REPO=$URL_DEB_REPO
	[ ! -d $CLONE_DIR/ftp.debian.org ] && mkdir -p $CLONE_DIR/ftp.debian.org
	[ ! -e ./ftp.debian.org ] && ln -s $CLONE_DIR/ftp.debian.org ./ftp.debian.org
	[ ! -d $CLONE_DIR/$VERSION\_$ARCH/debian ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH/debian
	[ ! -e ./debian ] && ln -s $CLONE_DIR/$VERSION\_$ARCH/debian ./debian

# DEBIAN ARCHIVE
elif [ "$VERSION" = "lenny" ] || [ "$VERSION" = "squeeze" ] || [ "$VERSION" = "wheezy" ] ||\
     [ "$VERSION" = "jessie" ]; then

	URL_REPO=$URL_DEB_ARCHI
	[ ! -d $CLONE_DIR/archive.debian.org ] && mkdir -p $CLONE_DIR/archive.debian.org
	[ ! -e ./archive.debian.org ] && ln -s $CLONE_DIR/archive.debian.org ./archive.debian.org
	[ ! -d $CLONE_DIR/$VERSION\_$ARCH/debian ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH/debian
	[ ! -e ./debian ] && ln -s $CLONE_DIR/$VERSION\_$ARCH/debian ./debian

# UBUNTU
elif [ "$VERSION" = "bionic" ] || [ "$VERSION" = "focal" ] || [ "$VERSION" = "jammy" ] ||\
     [ "$VERSION" = "lunar" ] || [ "$VERSION" = "mantic" ] || [ "$VERSION" = "noble" ] ||\
     [ "$VERSION" = "oracular" ] || [ "$VERSION" = "trusty" ] || [ "$VERSION" = "xenial" ]; then

	if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then

		# UBUNTU from <archive.ubuntu.com>
		URL_REPO=$URL_UBU_REPO
		[ ! -d $CLONE_DIR/es.archive.ubuntu.com ] && mkdir -p $CLONE_DIR/es.archive.ubuntu.com
		[ ! -e ./es.archive.ubuntu.com ] && ln -s $CLONE_DIR/es.archive.ubuntu.com ./es.archive.ubuntu.com
		[ ! -d $CLONE_DIR/$VERSION\_$ARCH/ubuntu ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH/ubuntu
		[ ! -e ./ubuntu ] && ln -s $CLONE_DIR/$VERSION\_$ARCH/ubuntu ./ubuntu

	elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "armhf" ] ||\
	     [ "$ARCH" = "ppc64el" ] || [ "$ARCH" = "s390x" ]; then

		# UBUNTU from <ports.ubuntu.com>
		URL_REPO=$URL_UBU_PORTS
		[ ! -d $CLONE_DIR/ports.ubuntu.com ] && mkdir -p $CLONE_DIR/ports.ubuntu.com
		[ ! -e ./ports.ubuntu.com ] && ln -s $CLONE_DIR/ports.ubuntu.com ./ports.ubuntu.com
		[ ! -d $CLONE_DIR/$VERSION\_$ARCH ] && mkdir -p $CLONE_DIR/$VERSION\_$ARCH
		[ ! -e ./ubuntuP ] && ln -s $CLONE_DIR/$VERSION\_$ARCH ./ubuntuP
	else
		echo "[ERROR] arch:$ARCH is not available in UBUNTU $VERSION"
		exit 2
	fi
else
	echo "[ERROR] Version not found."
	exit 2
fi

#################################################
# 3 FTP Main resources => ALL EXCEPT <pool> FOLDER
#################################################
wget --recursive --no-parent $URL_REPO/dists/$VERSION/
wget --recursive --no-parent $URL_REPO/dists/$VERSION-updates/
#wget --recursive --no-parent $URL_REPO/doc/
wget --recursive --no-parent $URL_REPO/indices/
wget --recursive --no-parent $URL_REPO/project/
#wget --recursive --no-parent $URL_REPO/tools/
#wget --recursive --no-parent $URL_REPO/zzz-dists/

[ -e ./ftp.debian.org ] && mv ./ftp.debian.org/debian/* ./debian/ && rm -rf ./ftp.debian.org && rm -rf $CLONE_DIR/ftp.debian.org
[ -e ./archive.debian.org ] && mv ./archive.debian.org/debian/* ./debian/ && rm -rf ./archive.debian.org && rm -rf $CLONE_DIR/archive.debian.org
[ -e ./es.archive.ubuntu.com ] && mv ./es.archive.ubuntu.com/ubuntu/* ./ubuntu/ && rm -rf ./es.archive.ubuntu.com && rm -rf $CLONE_DIR/es.archive.ubuntu.com
[ -e ./ports.ubuntu.com ] && mv ./ports.ubuntu.com/* ./ubuntuP/ && rm -rf ./ports.ubuntu.com && rm -rf $CLONE_DIR/ports.ubuntu.com

#################################################
# 4 - mkdir dest folder
#################################################
if [ "$URL_REPO" = "$URL_DEB_REPO" ]; then
	make_directories debian
elif [ "$URL_REPO" = "$URL_UBU_REPO" ];then
	make_directories ubuntu
elif [ "$URL_REPO" = "$URL_UBU_PORTS" ];then
	make_directories ubuntuP
fi

#################################################
# 5 - Obtain the Packages files and download
#################################################
download_Packages $VERSION main
download_Packages $VERSION multiverse
download_Packages $VERSION restricted
download_Packages $VERSION universe
download_Packages $VERSION-updates main
download_Packages $VERSION-updates multiverse
download_Packages $VERSION-updates restricted
download_Packages $VERSION-updates universe

#################################################
# 6 Clean-up Time!
#################################################
rm -rf Packages_filenames.txt Packages
find . -maxdepth 1 -type l -delete

echo "[INFO] The End."
exit 0

