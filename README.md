# VSCode-Offline

Scripts for both:

- Downloading VS Code Server files for offline or air-gapped environments (PowerShell)
- Deploying and updating VS Code Server on Linux systems (Bash)

## Overview

This repository now contains the end-to-end workflow:

1. Use PowerShell scripts on a connected system to retrieve release metadata and download the matching VS Code Server archive.
2. Stage those versioned files into your Linux repository path.
3. Use Bash scripts on Linux to deploy or update `vscode-server` for users.

## Repository Contents

### PowerShell Download Scripts

- `scripts/powershell/Get-VSCodeRelease.ps1`
- `scripts/powershell/Get-VSCodeServer.ps1`

### Linux Deployment Scripts

- `scripts/bash/vscodeserver_deploy_singleuser.sh`
- `scripts/bash/vscodeserver_update_multiuser.sh`
- `scripts/bash/vscodeserver_deploy_multiuser.sh`

## PowerShell Scripts

### `Get-VSCodeRelease.ps1`

Queries GitHub release metadata to return VS Code version and commit ID pairs.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Count` | int | No | Number of releases to return (1-30). Defaults to `1`. |
| `Token` | string | No | GitHub personal access token for authenticated API requests. |

> Note: Unauthenticated GitHub API requests are rate-limited to 60 requests per hour.

#### Examples

```powershell
# Get the latest release
. .\scripts\powershell\Get-VSCodeRelease.ps1
. .\scripts\powershell\Get-VSCodeServer.ps1

Get-VSCodeRelease

# Get the latest 3 releases using a GitHub PAT
Get-VSCodeRelease -Count 3 -Token "github_pat_..."
```

#### Output

```text
Version  CommitId
-------  --------
1.93.1   38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40
```

### `Get-VSCodeServer.ps1`

Downloads `vscode-server-linux-x64.tar.gz` for a provided commit ID and version, and writes files in a version folder.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CommitId` | string | Yes | VS Code commit ID for the desired version. |
| `Version` | string | Yes | VS Code version string (for example, `1.93.1`). |
| `OutPath` | string | Yes | Destination directory where version folders are created. |

#### Example

```powershell
. .\scripts\powershell\Get-VSCodeRelease.ps1
. .\scripts\powershell\Get-VSCodeServer.ps1

Get-VSCodeServer -CommitId "38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40" -Version "1.93.1" -OutPath "C:\Temp\"
```

#### Output Structure

```text
C:\Temp\
└── 1.93.1\
    ├── vscode-server-linux-x64.tar.gz
    └── 38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40.txt
```

## Linux Repository Layout

The deployment scripts expect versioned downloads to exist in:

`/usr/local/vscode-server/repo`

Each version directory must contain:

- `vscode-server-linux-x64.tar.gz`
- a `*.txt` file named as the commit ID

Example:

```text
/usr/local/vscode-server/repo
├── 1.58.2
│   ├── 74f6148eb9ea00507ec113ec51c489d6ffb4b771.txt
│   └── vscode-server-linux-x64.tar.gz
└── 1.80.1
    ├── b7c8d9e0f1234567890abcdef1234567890abcde.txt
    └── vscode-server-linux-x64.tar.gz
```

## Linux Deployment Scripts

### `vscodeserver_deploy_singleuser.sh`

Installs `vscode-server` for the user running the script.

- Defaults to the latest version available in the repository
- Supports selecting a specific version interactively
- Uses `SUDO_USER` when run with `sudo`, otherwise `whoami`

```bash
./scripts/bash/vscodeserver_deploy_singleuser.sh
```

### `vscodeserver_update_multiuser.sh`

Updates users who already have an existing `~/.vscode-server` installation.

- Installs the latest version by default
- Optional `-t|--target-version` argument for a specific version
- Skips users who already have the selected commit ID installed

```bash
./scripts/bash/vscodeserver_update_multiuser.sh
./scripts/bash/vscodeserver_update_multiuser.sh -t 1.98.2
```

### `vscodeserver_deploy_multiuser.sh`

Installs `vscode-server` for one or more specified users.

- Accepts usernames as command arguments
- Defaults to latest version when no target is given
- Optional `-t|--target-version` argument

```bash
./scripts/bash/vscodeserver_deploy_multiuser.sh user1 user2
./scripts/bash/vscodeserver_deploy_multiuser.sh -t 1.98.2 user1 user2 user3
```

## End-to-End Example

### 1) On a connected Windows system

```powershell
. .\scripts\powershell\Get-VSCodeRelease.ps1
. .\scripts\powershell\Get-VSCodeServer.ps1

Get-VSCodeRelease -Count 3 | Get-VSCodeServer -OutPath "C:\Temp\VSCodeServer"
```

### 2) Copy version folders to Linux

Copy the generated version directories to:

`/usr/local/vscode-server/repo`

### 3) Deploy on Linux

```bash
sudo ./scripts/bash/vscodeserver_update_multiuser.sh
```

## Requirements

- PowerShell 5.1 or later (for download scripts)
- Bash shell (for Linux deployment scripts)
- Internet access only on the download host
- Elevated rights on Linux for installation into user home directories

## Exit Codes (Linux scripts)

- `0`: Success
- `1`: Validation error or runtime failure
