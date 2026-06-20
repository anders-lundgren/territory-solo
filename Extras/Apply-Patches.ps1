#Requires -Version 7
<#
.SYNOPSIS
    Re-applies PackageCache patches after Library is cleared or on a fresh clone.
    Fixes CS0619 (obsolete API) errors in Meta XR SDK 203.0.0 on Unity 6000.5+.
.NOTES
    Uses string replacement — no patch.exe or git needed.
    Package folders are matched by name prefix so the content-hash suffix is ignored.
#>
param(
    [switch]$Force  # patch even if already applied
)

$projectRoot = Split-Path $PSScriptRoot -Parent
$cache       = Join-Path $projectRoot "Library\PackageCache"

if (-not (Test-Path $cache)) {
    Write-Error "Library\PackageCache not found at '$cache'. Open the project in Unity first so packages are extracted."
    exit 1
}

function Apply-StringPatch {
    param(
        [string]$PackageGlob,
        [string]$RelativePath,
        [string]$OldText,
        [string]$NewText
    )
    $pkgDir = Get-ChildItem $cache -Directory -Filter $PackageGlob | Select-Object -First 1
    if (-not $pkgDir) {
        Write-Warning "  SKIP  Package not found: $PackageGlob"
        return
    }
    $file = Join-Path $pkgDir.FullName ($RelativePath -replace '/', '\')
    if (-not (Test-Path $file)) {
        Write-Warning "  SKIP  File not found: $file"
        return
    }
    $content = [System.IO.File]::ReadAllText($file)
    if ($content.Contains($NewText)) {
        if (-not $Force) {
            Write-Host "  OK    Already patched: $RelativePath" -ForegroundColor Yellow
            return
        }
    }
    if (-not $content.Contains($OldText)) {
        Write-Warning "  SKIP  Expected text not found (wrong package version?): $RelativePath"
        return
    }
    $patched = $content.Replace($OldText, $NewText)
    [System.IO.File]::WriteAllText($file, $patched)
    Write-Host "  PATCH $RelativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Applying Meta XR SDK patches ===" -ForegroundColor Cyan
Write-Host "Cache: $cache"
Write-Host ""

# Patch 001a — MRUKGlobalContext.cs: GetInstanceID() → GetEntityId() in log message
Apply-StringPatch `
    -PackageGlob  "com.meta.xr.mrutilitykit@*" `
    -RelativePath "Core/Scripts/MRUKGlobalContext.cs" `
    -OldText      'Debug.LogError($"{nameof(MRUKGlobalContext)} with instance id {GetInstanceID()} was destroyed manually' `
    -NewText      'Debug.LogError($"{nameof(MRUKGlobalContext)} with instance id {GetEntityId()} was destroyed manually'

# Patch 001b — EnvironmentRaycastManager.cs: GetInstanceID() → GetEntityId() in log message
Apply-StringPatch `
    -PackageGlob  "com.meta.xr.mrutilitykit@*" `
    -RelativePath "Core/Scripts/EnvironmentRaycastManager.cs" `
    -OldText      'Debug.LogError($"More than one {nameof(EnvironmentRaycastManager)} component. Only one instance is allowed at a time. New instance: {name} ({GetInstanceID()})"' `
    -NewText      'Debug.LogError($"More than one {nameof(EnvironmentRaycastManager)} component. Only one instance is allowed at a time. New instance: {name} ({GetEntityId()})"'

# Patch 001c — Reflection.cs (MCPBridge): EntityId→int implicit cast → GetRawData() unchecked cast
Apply-StringPatch `
    -PackageGlob  "com.meta.xr.sdk.core@*" `
    -RelativePath "Scripts/MCPBridge/Tools/Reflection.cs" `
    -OldText      '                    return unityObject.GetEntityId();' `
    -NewText      '                    return unchecked((int)unityObject.GetEntityId().GetRawData());'

Write-Host ""
Write-Host "Done. In Unity: Assets > Reimport All  (or Ctrl+R) to trigger recompile." -ForegroundColor Cyan
