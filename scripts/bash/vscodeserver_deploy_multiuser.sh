#! /bin/bash
#
# Author:       Darren Hollinrake
# Version:      v1.0
# Date Created: 2026-05-27
# Date Updated:
#
# DESCRIPTION
#   This script installs vscode-server for one or more specified users. It installs the latest available version by
#   default, or a specific version when provided with -t/--target-version.
#
#
#   Update the 'VSCODELOCATION' variable to point to the location of the vscode-server files. Each version should be in
#   a directory with the version name (I.E. 1.58.2, 1.85.1, etc). Each of these folders should contain 2 files. A
#   'vscode-server-linux-x64.tar.gz' and a '*.txt' file where the name of the file matches the commit ID for the
#   corresponding version of vscode. You can find a Windows PowerShell script that is able to download the correct
#   files here: https://github.com/hollinrakedp/VSCode-Offline
#
# NOTES
#   - This script can install for users with or without an existing vscode-server installation.
#   - This script must be run with elevated rights as it requires write access to user home directories.
#
# EXAMPLE
#   ./vscodeserver_deploy_multiuser.sh user1 user2
#   ./vscodeserver_deploy_multiuser.sh -t 1.98.2 user1 user2 user3

usage() {
    echo "Usage: $0 [-t VERSION] USER [USER ...]"
    echo "  -t, --target-version  Install a specific vscode-server version"
    echo "  -h, --help            Show this help message"
}

# Location containing vscode-server installation files
VSCODELOCATION=/usr/local/vscode-server/repo
REQUESTED_VERSION=""
TARGET_USERS=()

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
        --)
            shift
            while [ "$#" -gt 0 ]; do
                TARGET_USERS+=("$1")
                shift
            done
            break
            ;;
        -*)
            echo "Error: unknown option '$1'"
            usage
            exit 1
            ;;
        *)
            TARGET_USERS+=("$1")
            ;;
    esac
    shift
done

if [ "${#TARGET_USERS[@]}" -eq 0 ]; then
    echo "Error: you must provide at least one username"
    usage
    exit 1
fi

if [ ! -d "$VSCODELOCATION" ]; then
    echo "Error: vscode-server repository not found at $VSCODELOCATION"
    exit 1
fi

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

echo "Using Version: $VERSION"
echo "Commit ID: $COMMITID"

FAILED=0
for user in "${TARGET_USERS[@]}"; do
    echo "User: $user"

    if ! id "$user" >/dev/null 2>&1; then
        echo "Warning: user '$user' does not exist. Skipping..."
        FAILED=1
        continue
    fi

    HOMEDIR=$(getent passwd "$user" | cut -d: -f6)
    if [ -z "$HOMEDIR" ] || [ ! -d "$HOMEDIR" ]; then
        echo "Warning: home directory for '$user' was not found. Skipping..."
        FAILED=1
        continue
    fi

    COMMITDIR="$HOMEDIR/.vscode-server/bin/$COMMITID"

    if [ -d "$COMMITDIR" ]; then
        echo "Detected: $COMMITID already exists for $user. Skipping..."
        continue
    fi

    mkdir -p "$COMMITDIR"
    if ! tar -xzf "$TARBALL" -C "$COMMITDIR" --strip-components 1; then
        echo "Warning: failed to extract archive for '$user'. Skipping..."
        FAILED=1
        continue
    fi

    if ! chown -R "$user" "$HOMEDIR/.vscode-server/bin"; then
        echo "Warning: failed to set ownership for '$user'."
        FAILED=1
        continue
    fi

    echo "Installed vscode-server $VERSION for $user into $COMMITDIR"
done

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi

exit 0
