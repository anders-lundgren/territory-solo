#Requires -Version 7
param(
    [ValidateSet("editmode", "playmode", "all")]
    [string]$mode = "editmode"
)

function Find-Unity([string]$version) {
    $candidates = [System.Collections.Generic.List[string]]::new()

    # Unity Hub secondary install path (common on Windows with a non-default drive)
    $hubJson = "$env:APPDATA\UnityHub\secondaryInstallPath.json"
    if (Test-Path $hubJson) {
        try {
            $root = (Get-Content $hubJson -Raw | ConvertFrom-Json).path
            if ($root) { $candidates.Add("$root\$version\Editor\Unity.exe") }
        } catch {}
    }

    # Unity Hub default install paths
    $candidates.Add("$env:PROGRAMFILES\Unity\Hub\Editor\$version\Editor\Unity.exe")
    $candidates.Add("C:\Program Files\Unity\Hub\Editor\$version\Editor\Unity.exe")

    # Drive-root installs (D:\Dev\Unity\..., E:\Unity\..., etc.)
    foreach ($drive in @("C:", "D:", "E:", "F:")) {
        foreach ($sub in @("Dev\Unity", "Unity")) {
            $candidates.Add("$drive\$sub\$version\Editor\Unity.exe")
        }
    }

    return $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$project = $PSScriptRoot

# Read required Unity version from ProjectSettings
$versionFile = Join-Path $project "ProjectSettings\ProjectVersion.txt"
$unityVersion = (Get-Content $versionFile | Select-String "m_EditorVersion:") -replace "m_EditorVersion:\s*", ""

$unity = Find-Unity $unityVersion
if (-not $unity) {
    Write-Error "Unity $unityVersion not found. Install it via Unity Hub or add its Editor folder to the search paths in runtests.ps1."
    exit 1
}

$results = Join-Path $project "TestResults"
New-Item -ItemType Directory -Force $results | Out-Null

$platform    = switch ($mode) {
    "editmode" { "EditMode" }
    "playmode" { "PlayMode" }
    "all"      { "All"      }
}
$logFile     = Join-Path $results "$mode-test.log"
$resultsFile = Join-Path $results "$mode-results.xml"

Write-Host "Unity   : $unity"
Write-Host "Mode    : $platform"
Write-Host "Results : $resultsFile"
Write-Host ""

& $unity -batchmode -quit -projectPath $project `
    -runTests -testPlatform $platform `
    -testResults $resultsFile `
    -logFile $logFile

$exit = $LASTEXITCODE
if ($exit -eq 0) {
    Write-Host "Tests passed." -ForegroundColor Green
} else {
    Write-Host "Tests failed (exit $exit). See: $logFile" -ForegroundColor Red
}
exit $exit
