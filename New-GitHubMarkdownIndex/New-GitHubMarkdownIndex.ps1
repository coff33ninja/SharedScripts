function New-GitHubMarkdownIndex {
<#
.SYNOPSIS
Function to generate an index to be used in markdown files

.DESCRIPTION
This function looks at a file structure and creates a tree representation in markdown. This can be used as an index for GitHub projects, options for specifying specific file formats are included in this function

.EXAMPLE
New-GitHubMarkdownIndex

Will execute with default values and generate a markdown file, copying the results to the clipboard

.EXAMPLE
New-GitHubMarkdownIndex -GitHubAccount jaapbrasser -GitHubRepo SharedScripts -Path C:\Temp\SharedScripts

Will run against the jaapbrasser account, sharedscripts repository and will look in the C:\Temp\SharedScripts for the local files.
#>
    [cmdletbinding(SupportsShouldProcess,DefaultParametersetName='Uri')]
    param(
        # The path of the file structure that will be mapped in markdown
        [string] $Path = 'C:\Temp\Events',
        # The GitHub full GitHub uri that files will be linked to
        [Parameter(ParameterSetName='Uri',Mandatory=$false)]
        [string] $GitHubUri = 'https://github.com/jaapbrasser/events/tree/master',
        # The GitHub Account that should be linked to
        [Parameter(ParameterSetName='AccRepo',Mandatory=$true)]
        [string] $GitHubAccount,
        # The GitHub repository that should be linked to
        [Parameter(ParameterSetName='AccRepo',Mandatory=$true)]
        [string] $GitHubRepo,
        # Included file types, specified by extension
        [string[]] $IncludeExtensions = @('.md','pdf'),
        # Whether to use clip.exe or to output to console
        [switch] $NoClipBoard,
        # File exclusion list
        [string[]] $ExcludeFile = @('license')
    )
    
    begin {
        $IncludeExtensions = $IncludeExtensions | ForEach-Object {
            if ($_ -notmatch '^\.') {
                ".$_"
            } else {
                $_
            }
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'AccRepo') {
            $GitHubUri = 'https://github.com/{0}/{1}/tree/master' -f $GitHubAccount, $GitHubRepo
        }

        $BuildMarkDown = {
            Get-ChildItem -LiteralPath $Path | ForEach-Object {
                if ((-not $_.PSIsContainer) -and ($ExcludeFile -contains $_.name)) {
                    # Do nothing
                } else {
                    $GHPath = $_.FullName -replace [regex]::Escape($Path) -replace '\\','/' -replace '\s','%20'
                    "* [$(Split-Path $_ -Leaf)]($GitHubUri$GHPath)"
                    if ($_.PSIsContainer) {
                        $_ | Get-ChildItem -Recurse | ? {$_.PSIsContainer -or $_.Extension -in $IncludeExtensions} | ForEach-Object {
                            if ((-not $_.PSIsContainer) -and ($ExcludeFile -contains $_.name)) {
                                # Do nothing
                            } else {
                                $Count = ($_.FullName -split '\\').Count-($Path.Split('\').Count+1)
                                $GHPath = $_.FullName -replace [regex]::Escape($Path) -replace '\\','/' -replace '\s','%20'
                                "$(" "*$Count*2)* [$(Split-Path $_ -Leaf)]($GitHubUri$GHPath)"
                            }
                        }
                    }
                }
            }
        }
    }
        
    process {
        if ($NoClipBoard) {
            $BuildMarkDown.Invoke()
        } else {
            if (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue) {
                $BuildMarkDown.Invoke() | Set-Clipboard
            } else {
                $BuildMarkDown.Invoke() | clip
            }
        }
    }
}
