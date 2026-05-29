# UNCLASSIFIED
function Get-VSCodeRelease {
    <#
    .SYNOPSIS
    Retrieves the version and commit ID of the latest release(s) of VS Code.

    .NOTES
    Name        : Get-VSCodeRelease
    Author      : Darren Hollinrake
    Date Created: 2023-09-19
    Date Updated:

    .DESCRIPTION
    This function will retrieve the latest release(s) of VS Code and the corresponding commit ID.

    The function retrieves information from the GitHub API, which has rate limits. For unauthenticated users, the limit is 60 requests per hour. Each call to the function will call the API once to collect the release information and once for each release requested to retrieve the commit ID.

    .PARAMETER Count
    Defines the number of releases to return. Must be between 1 and 30.

    .PARAMETER Token
    Allows the use of a GitHub personal access token for authentication during the API calls.

    .EXAMPLE
    Get-VSCodeRelease

    Version CommitId
    ------- --------
    1.93.1  38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40

    The latest release and commit ID of VS Code is returned. This is identical to running 'Get-VSCodeRelease -Count 1'.

    .EXAMPLE
    Get-VSCodeRelease -Count 3 -Token github_pat_0123456789ABCDEFGHJKLM_OPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHJKL

    Version CommitId
    ------- --------
    1.93.1  38c31bc77e0dd6ae88a4e9cc93428cc27a56ba40
    1.93.0  4849ca9bdf9666755eb463db297b69e5385090e3
    1.92.2  fee1edb8d6d72a0ddff41e5f71a671c23ed924b9

    The latest 3 releases and corresponding commit IDs of VS Code are returned.
    #>

    [CmdletBinding()]
    param (
        [Parameter (
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateRange(1, 30)]
        [int]$Count = 1,
        [Parameter (
            Position = 1,
            ValueFromPipelineByPropertyName
        )]
        [string]$Token
    )

    begin {}

    process {
        # Retrieve the release(s)
        if ($Count -eq 1) {
            $Uri = "https://api.github.com/repos/microsoft/vscode/releases/latest"
        }
        else {
            $Uri = "https://api.github.com/repos/microsoft/vscode/releases?per_page=$Count"
        }

        if ($Token) {
            $ReleaseParams = @{
                Headers = @{ "Authorization" = "Bearer $Token" }
                Uri     = "$Uri"
            }
        }
        else {
            $ReleaseParams = @{
                Uri = "$Uri"
            }
        }

        try {
            $Releases = Invoke-RestMethod @ReleaseParams
        }
        catch {
            Write-Error "Failed to retrieve VS Code releases: $_" -ErrorAction Stop
        }
        
        $Versions = $Releases.tag_name

        # Retrieve the commit ID for each version
        foreach ($Version in $Versions) {
            $VersionUri = "https://api.github.com/repos/microsoft/vscode/git/ref/tags/$Version"
            if ($Token) {
                $VersionParams = @{
                    Headers = @{"Authorization" = "Bearer $Token" }
                    Uri     = "$VersionUri"
                }
            }
            else {
                $VersionParams = @{
                    Uri = "$VersionUri"
                }
            }

            try {
                $TagInfo = Invoke-RestMethod @VersionParams
            }
            catch {
                Write-Error "Failed to retrieve the release commit ID: $_" -ErrorAction Stop
            }
            
            $CommitId = $TagInfo.object.sha
            [PSCustomObject]@{
                Version  = $Version
                CommitId = $CommitId
            }
        }
    }

    end {}
}

# UNCLASSIFIED
