param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [string]$DevicePattern = 'MTP|Watch|Android',
    [int]$MaxAttempts = 6
)

# Copy a file to the watch's internal storage root via MTP (retries for flaky cables).
# Requires: watch unlocked, screen on, and file storage / MTP access enabled in watch settings.
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
    Write-Error "Source file not found: $SourcePath"
    exit 1
}

$resolvedPath = (Resolve-Path -LiteralPath $SourcePath).Path
$name = Split-Path -Path $resolvedPath -Leaf
$portableZh = "$([char]0x4FBF)$([char]0x643A)$([char]0x5F0F)$([char]0x8BBE)$([char]0x5907)"

function Get-WatchFolder {
    param([string]$Pattern, [string]$PortableLabel)
    $shell = New-Object -ComObject Shell.Application
    $myComp = $shell.Namespace(17)
    foreach ($it in $myComp.Items()) {
        if ($it.Type -match "$PortableLabel|Portable" -or $it.Name -match $Pattern) {
            $storages = @($it.GetFolder.Items())
            if ($storages.Count -gt 0) { return $storages[0].GetFolder }
        }
    }
    return $null
}

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    Write-Output "[attempt $attempt/$MaxAttempts] probing MTP storage..."
    $folder = Get-WatchFolder -Pattern $DevicePattern -PortableLabel $portableZh
    if (-not $folder) {
        Write-Output "  storage not visible (locked screen / cable / MTP file access off), retry in 3s"
        Start-Sleep -Seconds 3
        continue
    }

    $exists = @($folder.Items()) | Where-Object { $_.Name -eq $name }
    if ($exists) {
        Write-Output "ALREADY_PRESENT: $name"
        exit 0
    }

    Write-Output "  copying $name ..."
    $folder.CopyHere($resolvedPath, 20)   # 4 = no progress dialog, 16 = yes-to-all

    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 1
        $ok = @($folder.Items()) | Where-Object { $_.Name -eq $name }
        if ($ok) {
            Write-Output "COPY_DONE: $name"
            exit 0
        }
    }
    Write-Output "  copy not confirmed in 20s, retrying"
}

Write-Output "COPY_FAILED after all attempts"
exit 1
