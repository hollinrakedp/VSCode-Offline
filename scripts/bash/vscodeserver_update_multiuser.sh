#! /bin/bash
#
# Author:       Mike Bowling, Darren Hollinrake
# Version:      v1.3
# Date Created: 2023-09-01
# Date Updated: 2026-05-27
#
# DESCRIPTION
#   This script updates vscode-server for users who already have a version of vscode-server installed. It installs the
#   latest version by default and can target a specific version when provided with -t/--target-version.
#
#
#   Update the 'VSCODELOCATION' variable to point to the location of the vscode-server files. Each version should be in
#   a directory with the version name (I.E. 1.58.2, 1.85.1, etc). Each of these folders should contain 2 files. A
#   'vscode-server-linux-x64.tar.gz' and a '*.txt' file where the name of the file matches the commit ID for the
#   corresponding version of vscode. You can find a Windows PowerShell script that is able to download the correct
#   files here: https://github.com/hollinrakedp/VSCode-Offline
#
# NOTES
#   - This script does *NOT* install vscode-server for all users, only those with an existing installation.
#   - This script must be run with elevated rights as it requires write access to all user home directories.
#
# EXAMPLE
#   ./vscodeserver_update_multiuser.sh
#   ./vscodeserver_update_multiuser.sh -t 1.98.2

usage() {
    echo "Usage: $0 [-t VERSION]"
    echo "  -t, --target-version  Update users to a specific vscode-server version"
    echo "  -h, --help            Show this help message"
}

# Collect all users with an existing vscode-server installation
USERS=$(find /home -mindepth 2 -maxdepth 2 -type d -name '.vscode-server' -printf '%h\n' | xargs -n 1 basename | sort -u)

# Location containing vscode-server installation files
VSCODELOCATION=/usr/local/vscode-server/repo
REQUESTED_VERSION=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -t|--target-version)
            shift
            if [ -z "$1" ]; then
                echo "Error: missing value for --target-version"
                usage
                exit 1
            fi
            REQUESTED_VERSION="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ ! -d "$VSCODELOCATION" ]; then
    echo "Error: vscode-server repository not found at $VSCODELOCATION"
    exit 1
fi

# Retrieve the version to use
if [ -n "$REQUESTED_VERSION" ]; then
    VERSION="$REQUESTED_VERSION"
else
    VERSION=$(find "$VSCODELOCATION" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -1)
fi

if [ -z "$VERSION" ]; then
    echo "Error: no vscode-server versions were found in $VSCODELOCATION"
    exit 1
fi

if [ ! -d "$VSCODELOCATION/$VERSION" ]; then
    echo "Error: version '$VERSION' was not found in $VSCODELOCATION"
    exit 1
fi

# Retrieve the commit ID to use
COMMITID=$(find "$VSCODELOCATION/$VERSION" -maxdepth 1 -name '*.txt' -printf '%f\n' | sed 's/\.txt$//' | head -n 1)

if [ -z "$COMMITID" ]; then
    echo "Error: no commit ID file was found for version $VERSION"
    exit 1
fi

TARBALL="$VSCODELOCATION/$VERSION/vscode-server-linux-x64.tar.gz"

if [ ! -f "$TARBALL" ]; then
    echo "Error: archive not found at $TARBALL"
    exit 1
fi

# Show the version and commit ID being used
echo "Using Version: $VERSION"
echo "Commit ID: $COMMITID"

# Loop through users' home directories
if [ -z "$USERS" ]; then
    echo "No users with an existing vscode-server installation were found. Nothing to do."
    exit 0
fi

for i in $USERS; do
    echo "User: $i"
    COMMITDIR="/home/$i/.vscode-server/bin/$COMMITID"

    # Verify the user doesn't already have selected version's commit ID
    if [ -d "$COMMITDIR" ]; then
        echo "Detected: $COMMITID already exists. Skipping..."
    else
        echo "Extracting vscodeserver"
        mkdir -p "$COMMITDIR"
        tar -xzf "$TARBALL" -C "$COMMITDIR" --strip-components 1
        chown -R "$i" "/home/$i/.vscode-server/bin"
    fi
done
