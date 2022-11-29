$PSDefaultParameterValues["Invoke-Request:UseWebRequest"] = $true
$PSDefaultParameterValues["Invoke-Request:Method"] = "GET"
function Get-WhoFollowsMe {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "accounts/$Id/followers?limit=80"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-WhoAmIFollowing {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "accounts/$Id/following?limit=80"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Invoke-Request {
    param(
        [string]$Method = "GET",
        [string]$Server = $env:MASTODON_SERVER,
        [Parameter(Mandatory)]
        [Alias("Uri")]
        [string]$Path,
        [string]$Version = "v1",
        [string]$Body,
        [string]$OutFile,
        [switch]$UseWebRequest,
        [switch]$Raw
    )

    if ($Path -match "://") {
        $url = $Path
    } else {
        $url = "https://$Server/api/$Version/$Path"
    }

    Write-Verbose "Going to $url"
    $parms = @{
        Uri         = $url
        ErrorAction = "Stop"
        Headers     = @{ Authorization = "Bearer $env:ACCESS_TOKEN" }
        Method      = $Method
        Verbose     = $false # too chatty
    }

    if ($Body) {
        $parms.Body = $Body
        $parms.ContentType = "application/json"
    }

    if ($OutFile) {
        $parms.OutFile = $OutFile
    }

    if ($UseWebRequest) {
        $response = Invoke-WebRequest @parms

        if ($response.Headers.Link) {
            $script:link = $response.Headers.Link.Split(";") | Where-Object { $PSitem -match "max_id" } | Select-Object -First 1
            if ($script:link) {
                foreach ($term in "<", ">") {
                    $script:link = $script:link.Replace($term, "")
                }
            }
        } else {
            $script:link = $null
        }

        if (-not $OutFile -and -not $Raw) {
            $response.Content | ConvertFrom-Json -Depth 10
        }

        if ($Raw) {
            $response.Content
        }
    } else {
        Invoke-RestMethod @parms
    }

    # This keeps it from calling too many times in a 5 minute period
    Start-Sleep -Seconds 1
}

function Get-Account {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$UserName
    )

    foreach ($user in $UserName) {
        $user = $user.Replace("@$env:MASTODON_SERVER", "")
        if ($user.StartsWith("@")) {
            $user = $user.Substring(1)
        }

        $ignored = "youtube.com", "medium.com", "withkoji.com", "counter.social", "twitter.com"
        foreach ($domain in $ignored) {
            if ($user -match $domain) {
                Write-Verbose "User ($user) matched invalid Mastodon domain ($domain). Skipping."
                continue
            }
        }

        $account = $script:accounts | Where-Object acct -eq $user

        if (-not $user.StartsWith("http")) {
            try {
                $address = [mailaddress]$user
                if ($address.Host -eq $Server) {
                    $account = $script:accounts | Where-Object acct -eq $address.User
                    if ($account) {
                        $account
                        continue
                    } else {
                        $user = "https://" + $address.Host + "/@" + $address.User
                    }
                }
            } catch {
                # trying a variety of things because there is no specific
                # search for username, so just ignore it if this didn't work
            }
        }

        $user = $user.Replace("@$Server", "")
        $account = $script:accounts | Where-Object acct -eq $user

        if ($account.id) {
            $account
            continue
        }

        $parms = @{
            Path    = "search?type=accounts&q=$user&resolve=true"
            Method  = "GET"
            Version = "v2"
        }

        $account = Invoke-Request @parms | Select-Object -ExpandProperty accounts

        if ($account) {
            # add to script variable and return
            $null = $script:accounts.Add($account)
            $account
        } else {
            throw "$user not found. The account may not exist, or it may be blocked by your account or Mastodon instance."
        }
    }
}
function Get-Bookmark {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "bookmarks"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-AccountMute {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "mutes"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-DomainBlock {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "domain_blocks"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-List {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "lists"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}
function Get-ListMember {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "lists/$Id/accounts"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-AccountBlock {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "blocks"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-Post {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )
    $script:link = $null
    Invoke-Request -Path "accounts/$id/statuses?exclude_replies=true"

    while ($null -ne $script:link) {
        Invoke-Request -Path $script:link
    }
}

function Get-Relationship {
    [CmdletBinding()]
    param(
        [psobject[]]$Id = $script:myid
    )

    $splits = Split-array -Objects $script:accounts.id -Size 100
    foreach ($split in $splits) {
        $idstring = $split -join "&id[]="
        Invoke-Request -Path "accounts/relationships?id[]=$idstring"
    }
}


# thanks https://www.powershellgallery.com/packages/PSSharedGoods/0.0.252/Content/PSSharedGoods.psm1
function Split-Array {
    <#
    .SYNOPSIS
    Split an array into multiple arrays of a specified size or by a specified number of elements

    .DESCRIPTION
    Split an array into multiple arrays of a specified size or by a specified number of elements

    .PARAMETER Objects
    Lists of objects you would like to split into multiple arrays based on their size or number of parts to split into.

    .PARAMETER Parts
    Parameter description

    .PARAMETER Size
    Parameter description

    .EXAMPLE
    This splits array into multiple arrays of 3
    Example below wil return 1,2,3 + 4,5,6 + 7,8,9
    Split-array -Objects @(1,2,3,4,5,6,7,8,9,10) -Parts 3

    .EXAMPLE
    This splits array into 3 parts regardless of amount of elements
    Split-array -Objects @(1,2,3,4,5,6,7,8,9,10) -Size 3

    .NOTES

    #>
    [CmdletBinding()]
    param([alias('InArray', 'List')][Array] $Objects,
        [int]$Parts,
        [int]$Size)
    if ($Objects.Count -eq 1) { return $Objects }
    if ($Parts) { $PartSize = [Math]::Ceiling($inArray.count / $Parts) }
    if ($Size) {
        $PartSize = $Size
        $Parts = [Math]::Ceiling($Objects.count / $Size)
    }
    $outArray = [System.Collections.Generic.List[Object]]::new()
    for ($i = 1; $i -le $Parts; $i++) {
        $start = (($i - 1) * $PartSize)
        $end = (($i) * $PartSize) - 1
        if ($end -ge $Objects.count) { $end = $Objects.count - 1 }
        $outArray.Add(@($Objects[$start..$end]))
    }
    , $outArray
}