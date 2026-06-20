@echo off
REM Apply PackageCache patches for Meta XR SDK compatibility with Unity 6000.5+
REM Delegates to Apply-Patches.ps1 — PowerShell 7+ required.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Apply-Patches.ps1" %*
