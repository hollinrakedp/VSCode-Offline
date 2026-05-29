#! /bin/bash
#
# Author:       Mike Bowling, Darren Hollinrake
# Version:      v1.2
# Date Created: 2023-09-01
# Date Updated: 2026-05-27
#
# DESCRIPTION
#   This script installs vscode-server for the user who executes it. It deploys the latest version by default and
#   allows a specific version to be selected from the repository if needed.
#
#
#   Update the 'VSCODELOCATION' variable to point to the location of the vscode-server files. Each version should be
#   stored in a directory named after the version (I.E. 1.58.2, 1.85.1, etc). Each version directory should contain
#   2 files: a 'vscode-server-linux-x64.tar.gz' archive and a '*.txt' file where the file name matches the commit ID
#   for the corresponding version of vscode.
#
# NOTES
#   - This script installs vscode-server only for the selected user, not for all users on the system.
#   - This script must be run with elevated rights as it requires write access to the target user's home directory.
#
# EXAMPLE
#   ./vscodeserver_deploy_singleuser.sh

#######################################
## VARIABLES
# Location containing vscode-server installation files
VSCODELOCATION=/usr/local/vscode-server/repo

if [ ! -d "$VSCODELOCATION" ]; then
    echo "Error: vscode-server repository not found at $VSCODELOCATION"
    exit 1
fi

# Selects the user to install vscode-server for
TARGET_USER="${SUDO_USER:-$(whoami)}"

# Selects the current version of vscode-server from the repo
VERSION=$(find "$VSCODELOCATION" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -1)

if [ -z "$VERSION" ]; then
    echo "Error: no vscode-server versions were found in $VSCODELOCATION"
    exit 1
fi

# Identifies the commit ID for the corresponding vscode-server install
COMMITID=$(find "$VSCODELOCATION/$VERSION" -maxdepth 1 -name '*.txt' -printf '%f\n' | sed 's/\.txt$//' | head -n 1)

if [ -z "$COMMITID" ]; then
    echo "Error: no commit ID file was found for version $VERSION"
    exit 1
fi
#######################################

# Select yes to install latest and no to select a specific version
echo ""
echo "Installing additional versions of vscode-server will not overwrite your other installs"
echo ""
while true; do
    echo "Would you like to install the latest version of vscode-server? [yes/no]: "
    read -r XX

    case "${XX,,}" in
        yes|y)
            INSTALL_LATEST=true
            break
            ;;
        no|n)
            INSTALL_LATEST=false
            break
            ;;
        *)
            echo "Please answer yes or no."
            echo ""
            ;;
    esac
done

# Deploys vscode-server for the selected user and sets permissions on the target install directory

if [ "$INSTALL_LATEST" = false ]; then
    echo ""
    AVAILABLE_VERSIONS=$(find "$VSCODELOCATION" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V)

    if [ -z "$AVAILABLE_VERSIONS" ]; then
        echo "Error: no vscode-server versions were found in $VSCODELOCATION"
        exit 1
    fi

    while true; do
        echo "Available versions:"
        echo "$AVAILABLE_VERSIONS"
        echo ""
        echo "What version would you like to install: "
        read -r VERSION

        if printf '%s\n' "$AVAILABLE_VERSIONS" | grep -Fxq "$VERSION"; then
            break
        fi

        echo "Error: '$VERSION' is not a valid available version."
        echo ""
    done

    COMMITID=$(find "$VSCODELOCATION/$VERSION" -maxdepth 1 -name '*.txt' -printf '%f\n' | sed 's/\.txt$//' | head -n 1)

    if [ -z "$COMMITID" ]; then
        echo "Error: no commit ID file was found for version $VERSION"
        exit 1
    fi
    COMMITDIR="/home/$TARGET_USER/.vscode-server/bin/$COMMITID"
    TARBALL="$VSCODELOCATION/$VERSION/vscode-server-linux-x64.tar.gz"

    if [ ! -f "$TARBALL" ]; then
        echo "Error: archive not found at $TARBALL"
        exit 1
    fi

    mkdir -p "$COMMITDIR"
    tar -xzf "$TARBALL" -C "$COMMITDIR" --strip-components 1
    chown -R "$TARGET_USER" "/home/$TARGET_USER/.vscode-server/bin"
    echo ""
    echo "vscode-server $VERSION has been installed into $COMMITDIR"
    echo ""

else
    COMMITDIR="/home/$TARGET_USER/.vscode-server/bin/$COMMITID"
    TARBALL="$VSCODELOCATION/$VERSION/vscode-server-linux-x64.tar.gz"

    if [ ! -f "$TARBALL" ]; then
        echo "Error: archive not found at $TARBALL"
        exit 1
    fi

    mkdir -p "$COMMITDIR"
    tar -xzf "$TARBALL" -C "$COMMITDIR" --strip-components 1
    chown -R "$TARGET_USER" "/home/$TARGET_USER/.vscode-server/bin"
    echo ""
    echo "vscode-server $VERSION has been installed into $COMMITDIR"
    echo ""
fi
