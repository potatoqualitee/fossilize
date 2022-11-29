[CmdletBinding()]
param (
    [string]$Server,
    [Alias("FullName")]
    [string]$Path,
    [string[]]$Type
)
<#

            Validation

#>

if (-not $Path) {
    Write-Warning "FilePath empty or missing"
    return
}
Write-Verbose "Exporting $Type to $Path"

. $PSScriptRoot/helpers.ps1
$myaccount = Invoke-Request -Path "accounts/verify_credentials" -Method GET
$script:myid = $myaccount.id

$script:accounts = New-Object System.Collections.ArrayList

# help 'em out
if ($Server -match '://') {
    $Server = ([uri]$Server).DnsSafeHost
} elseif ($Server -match '/@') {
    $Server = $($Server -split "/@" | Select-Object -First 1)
} elseif ($Server.StartsWith("@") -or $Server -match "@") {
    $Server = $($Server -split "@" | Select-Object -Last 1)
}

$dir = Resolve-Path -Path $Path -ErrorAction Ignore
if (-not $dir) {
    $dir = $Path
}
if (-not (Test-Path $dir)) {
    $null = New-Item -Path $dir -Type Directory -ErrorAction Stop
}
$dir = Resolve-Path -Path $dir -ErrorAction Ignore

$items = "follows", "lists", "blocks", "mutes", "domain_blocks", "bookmarks", "followers", "posts"

foreach ($item in $items) {
    if ($Type -contains $item -or "$Type" -eq "all") {
        Write-Verbose "Processing $item"

        if ($item -eq "blocks") {
            Write-Verbose "Exporting account blocks"
            $filepath = Join-Path -Path $dir -ChildPath blocked_accounts.csv
            #  No header, Just acct
            (Get-AccountBlock).acct | Out-File -FilePath $filepath
        }
        if ($item -eq "lists") {
            Write-Verbose "Exporting lists"
            $filepath = Join-Path -Path $dir -ChildPath lists.csv
            # No header, two columns formatted like: listname, user@domain.tld
            foreach ($list in (Get-List)) {
                foreach ($member in (Get-ListMember -Id $list.Id)) {
                        "$($list.title),$($member.acct)" #| Add-Content -Path $filepath
                }
            }
        }
        if ($item -eq "follows") {
            Write-Verbose "Exporting follows"
            $filepath = Join-Path -Path $dir -ChildPath following_accounts.csv
            # Account address,Show boosts,Notify on new posts,Languages
            # id[]=1&id[]=2
            <#
            id                   : 109344415928696897
            following            : True
            showing_reblogs      : True
            notifying            : False
            languages            :
            followed_by          : True
            blocking             : False
            blocked_by           : False
            muting               : False
            muting_notifications : False
            requested            : False
            domain_blocking      : False
            endorsed             : False
            note                 :
            #>
            $follows = Get-Follows
            $relationships = Get-Relationship
            $follows | ForEach-Object -Process {
                $rel = $relationships | Where-Object Id -eq $PSItem.Id
                $showboosts = $rel.showing_reblogs -eq $true
                $notify = $rel.notifying -eq $true
                [pscustomobject]@{
                    'Account address'     = $PSItem.acct
                    'Show boosts'         = $showboosts
                    'Notify on new posts' = $notify
                    'Languages'           = $rel.languages
                }
            } | Export-Csv -FilePath $filepath
        }

        if ($item -eq "mutes") {
            Write-Verbose "Exporting mutes"
            $filepath = Join-Path -Path $dir -ChildPath muted_accounts.csv
            # Account address,Hide notifications
            foreach ($account in (Get-AccountMute).acct) {
                "$account, $true" | Add-Content -FilePath $filepath
            }
        }

        if ($item -eq "domain_blocks") {
            Write-Verbose "Exporting domain blocks"
            $filepath = Join-Path -Path $dir -ChildPath blocked_domains.csv
            #  Just the domain
            Get-DomainBlock | Out-File -Filepath $filepath
        }

        if ($item -eq "bookmarks") {
            Write-Verbose "Exporting bookmarks"
            $filepath = Join-Path -Path $dir -ChildPath bookmarks.csv
            (Get-Bookmark).uri | Out-File -Filepath $filepath
        }

        if ($item -eq "followers") {
            Write-Verbose "Exporting followers"
            $filepath = Join-Path -Path $dir -ChildPath followers.csv
            "Follower" | Set-Content -FilePath $filepath
            (Get-Follower).acct | Add-Content -FilePath $filepath
        }

        if ($item -eq "posts") {
            Write-Verbose "Exporting bookmarks"
            $filepath = Join-Path -Path $dir -ChildPath posts.json
            Get-Post | Export-Csv -FilePath $filepath
        }

        Get-ChildItem -Path $filepath
    }
}

<#
if (-not $PSBoundParameter.Type) {
    if ($first -match "Hide Notifications") {
        $Type = "mutes"
        $csv = Import-Csv -Path $file
    } elseif ($first -match "Show boosts") {
        $Type = "follows"
        $csv = Import-Csv -Path $file
    } elseif ($first -match "@" -and $first -notmatch ",") {
        $Type = "accountblocks"
        $csv = Get-Content -Path $file
    } elseif ($first -match "@" -and $first -match ",") {
        $Type = "lists"
        $csv = Import-Csv -Path $file -Header List, UserName
    } elseif ($first -notmatch "," -and $first -match "http") {
        $Type = "bookmarks"
        $csv = Get-Content -Path $file
    } elseif ($first -notmatch "http" -and $first -notmatch "," -and $first -match ".") {
        $Type = "domainblocks"
        $csv = Get-Content -Path $file
    } else {
        $basename = Split-Path -Path $file -Leaf
        throw "Can't auto-detect file type for $basename. Please specify type in the Action"
    }
}
#>


$csv = Resolve-Path -Path $Path
"csv-path=$csv" >> $env:GITHUB_OUTPUT