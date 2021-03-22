#!/bin/sh

EXEC_PATH="/usr/bin"
LIBS_PATH="/usr/share"
BASE_NAME="iperl"
INSTALL_PATH="${LIBS_PATH}/${BASE_NAME}"
MAIN_PATH="${EXEC_PATH}/${BASE_NAME}"

# Checking for root privileges
ROOT=$(id `whoami` | cut -d \= -f 2 | cut -d \( -f 1);
[ ! $ROOT -eq 0 ] && echo "Can't install without ROOT privileges" && exit
#

echo "Installing modules at $INSTALL_PATH"
mkdir -p "$INSTALL_PATH"
echo "Installing executable at $MAIN_PATH"
#
echo "Copying lib ..."
cp -r "./lib" "$INSTALL_PATH/"
echo "Copying modules ..."
cp -r "./modules" "$INSTALL_PATH/"
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