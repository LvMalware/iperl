#!/bin/sh

EXEC_PATH="/usr/bin"
LIBS_PATH="/usr/share"
BASE_NAME="iperl"
INSTALL_PATH="${LIBS_PATH}/${BASE_NAME}"
MAIN_PATH="${EXEC_PATH}/${BASE_NAME}"

# Checking for root privileges
ROOT="$(id `whoami` | cut -d \= -f 2 | cut -d \( -f 1)"
[ ! $ROOT -eq 0 ] && echo "Can't install without ROOT privileges" && exit
#identify system package manager
## Debian-based systems
PKG="$(which apt)" && INSTALL="$PKG install -y"
## Arch-based systems
[ -z "$PKG" ] && PKG="$(which pacman)" && INSTALL="$PKG -Sy"
## Fedora-based systems (using dnf for more compatibility)
[ -z "$PKG" ] && PKG="$(which dnf)" && INSTALL="$PKG install -y"
## FreeBSD-based systems
[ -z "$PKG" ] && PKG="$(which pkg)" && INSTALL="$PKG install -y"
## Void linux
[ -z "$PKG" ] && PKG="$(which xbps-install)" && INSTALL="$PKG -y"
#
echo "Installing dependences..."
#cpan -i JSON Term::ReadKey
$INSTALL libjson-perl libterm-readkey-perl libterm-size-perl
echo "Installing modules at $INSTALL_PATH"
mkdir -p "$INSTALL_PATH"
echo "Installing executable at $MAIN_PATH"
#
echo "Copying lib ..."
cp -r "./lib" "$INSTALL_PATH/"
echo "Copying modules ..."
[ -d "./modules" ] && cp -r "./modules" "$INSTALL_PATH/"
echo "Copying license ..."
cp "LICENSE" "$INSTALL_PATH/"
echo "Copying readme ..."
cp "README.md" "$INSTALL_PATH/"
echo "Copying executable ..."
cp "main.pl" "$MAIN_PATH"
echo "Configuring modules ..."
sed -i -E "s|\./lib|${INSTALL_PATH}/lib|" "$MAIN_PATH"
sed -i -E "s|\./modules|${INSTALL_PATH}/modules|" "$MAIN_PATH"
echo "Done. Executing IPerl ..."
iperl
