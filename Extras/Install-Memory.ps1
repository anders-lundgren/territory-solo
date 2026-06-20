#Requires -Version 7
<#
.SYNOPSIS
    Installs Claude Code agent memory for this project into the current user profile.
    Run this once on each machine that will use Claude Code with this project.
.DESCRIPTION
    Claude Code stores project memory at:
        %APPDATA%\..\Roaming\... (varies) or
        $env:USERPROFILE\.claude\projects\<encoded-path>\memory\
    The encoded path is the project root with backslashes replaced by dashes and
    the drive colon removed, prefixed with the drive letter lowercased.
    e.g.  D:\Dev\territory-solo  ->  d--Dev-territory-solo
#>

$projectRoot  = Split-Path $PSScriptRoot -Parent
$sourceMemory = Join-Path $PSScriptRoot "claude-memory"

# Derive the Claude Code project key from the project path
# Claude uses: lowercase drive + "--" + path-with-backslash-as-dash, no colon
$drive    = ($projectRoot.Substring(0, 1)).ToLower()
$rest     = $projectRoot.Substring(3) -replace '\\', '-'   # strip "D:\"
$key      = "$drive--$rest"                                  # e.g. d--Dev-territory-solo

$targetDir = Join-Path $env:USERPROFILE ".claude\projects\$key\memory"

Write-Host ""
Write-Host "=== Installing Claude Code memory ===" -ForegroundColor Cyan
Write-Host "Source : $sourceMemory"
Write-Host "Target : $targetDir"
Write-Host ""

if (-not (Test-Path $sourceMemory)) {
    Write-Error "Source memory folder not found: $sourceMemory"
    exit 1
}

New-Item -ItemType Directory -Force $targetDir | Out-Null

$files = Get-ChildItem $sourceMemory -File
foreach ($f in $files) {
    $dest = Join-Path $targetDir $f.Name
    if (Test-Path $dest) {
        Write-Host "  EXISTS  $($f.Name) (skipping — delete manually to overwrite)" -ForegroundColor Yellow
    } else {
        Copy-Item $f.FullName $dest
        Write-Host "  COPIED  $($f.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Memory will be loaded automatically in the next Claude Code session." -ForegroundColor Cyan
