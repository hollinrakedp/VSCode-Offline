# UNCLASSIFIED
function Get-VSCodeServer {
    <#
    .SYNOPSIS
    Downloads the corresponding VSCode Server version for a given VS Code commit ID.

    .DESCRIPTION
    This function will download vscode-server from the commit ID provided and place it in a corresponding version folder. A text file will be created with the commit ID as the filename.

    .NOTES
    Name         - Get-VSCodeServer
    Version      - 1.0
    Author       - Darren Hollinrake
    Date Created - 2022-08-30
    Date Updated - 2024-09-22

    .PARAMETER CommitId
    The VSCode Commit ID for the version of vscode-server that should be downloaded.

    .PARAMETER Version
    The version of vscode-server that is being downloaded. This should be in the format 'X.Y.Z'.

    .PARAMETER OutPath
    The destination path for the file. Do not include the file name.

    .EXAMPLE
    Invoke-VSCodeServerDownload -CommitId 2ccd690cbff1569e4a83d7c43d45101f817401dc -Version "1.80.2" -OutPath "C:\Temp\"
    This will download vscode-server with the given commit ID and place it in 'C:\Temp\1.80.2'. A text file named '2ccd690cbff1569e4a83d7c43d45101f817401dc.txt' will be placed in the folder.

    #>
    
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipelineByPropertyName,
            Mandatory)]
        [string]$CommitId,
        [Parameter(
            ValueFromPipelineByPropertyName,
            Mandatory)]
        [string]$Version,
        [Parameter(
            ValueFromPipelineByPropertyName,
            Mandatory)]
            [Alias("Path")]
        [string]$OutPath
    )
    
    $Url = "https://update.code.visualstudio.com/commit:$CommitId/server-linux-x64/stable"
    
    $VersionPath = Join-Path -Path $OutPath -ChildPath $Version
    if (! (Test-Path $VersionPath)) {
        New-Item -ItemType Directory -Path $VersionPath -Force | Out-Null
    }
    
    $OutFile = Join-Path -Path $VersionPath -ChildPath "vscode-server-linux-x64.tar.gz"
    
    if (! (Test-Path $OutFile)) {
        Write-Output "Downloading v$Version"
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile
            New-Item -Path $VersionPath -Name "$CommitId.txt" -ItemType File | Out-Null
        }
        catch {
            Write-Warning "There was an issue downloading one of the files. Exiting..."
            Remove-Item -Path $VersionPath -Recurse
            throw
        }
    }
    else {
        Write-Output "Downloading v$Version - Already exists - Skipping..."
    }
        
}
# UNCLASSIFIED
