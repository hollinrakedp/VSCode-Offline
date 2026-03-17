# VSCode-Offline

PowerShell scripts for downloading VS Code Server files for offline/air-gapped environments.

## Overview

This repository contains two PowerShell functions that work together to retrieve VS Code release
information and download the corresponding VS Code Server binaries. This is useful when you need
to pre-stage VS Code Server files for Linux systems that do not have internet access.

## Scripts

### `Get-VSCodeRelease.ps1`

Queries the GitHub API to retrieve the latest VS Code release version(s) and their corresponding
commit IDs.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Count` | int | No | Number of releases to return (1-30). Defaults to `1`. |
| `Token` | string | No | GitHub personal access token for authenticated API requests. |

> **Note:** The GitHub API has a rate limit of **60 requests/hour** for unauthenticated users.
> Each call consumes one request for the release list plus one additional request per release
> version retrieved.

#### Examples

```powershell
# Get the latest release
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

---

### `Get-VSCodeServer.ps1`

Downloads the VS Code Server tarball (`vscode-server-linux-x64.tar.gz`) for a given commit ID and
version. Creates a version-named subdirectory and places a commit ID marker file alongside the
tarball.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CommitId` | string | Yes | The VS Code commit ID for the desired version. |
| `Version` | string | Yes | The VS Code version string (e.g., `1.93.1`). |
| `OutPath` | string | Yes | Destination directory for the downloaded files. |

#### Examples

```powershell
# Download a specific version
Get-VSCodeServer -CommitId "38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40" -Version "1.93.1" -OutPath "C:\Temp\"
```

#### Output Structure

```text
C:\Temp\
└── 1.93.1\
    ├── vscode-server-linux-x64.tar.gz
    └── 38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40.txt
```

---

## Combined Usage

The two functions are designed to work together via the pipeline. The output of `Get-VSCodeRelease`
can be piped directly into `Get-VSCodeServer` to download one or more versions in a single command.

```powershell
# Dot-source both scripts
. .\Get-VSCodeRelease.ps1
. .\Get-VSCodeServer.ps1

# Download the latest VS Code Server version
Get-VSCodeRelease | Get-VSCodeServer -OutPath "C:\Temp\VSCodeServer"

# Download the latest 3 versions
Get-VSCodeRelease -Count 3 | Get-VSCodeServer -OutPath "C:\Temp\VSCodeServer"
```

## Requirements

- PowerShell 5.1 or later
- Internet access from the machine running the scripts (to reach GitHub API and Microsoft update servers)
- The target Linux machine(s) do **not** need internet access — only the machine running these scripts does

## Related Repositories

- [vscode-server-offline](../vscode-server-offline/) — Scripts for packaging/staging VS Code Server
- [vscode-server-deployment](../vscode-server-deployment/) — Shell scripts for deploying VS Code Server to Linux hosts
