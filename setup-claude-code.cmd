@echo off
setlocal EnableExtensions EnableDelayedExpansion
:: ============================================================================
:: Claude Code One-Click Windows Installer
:: 
:: This script automatically installs Claude Code on Windows with all required
:: dependencies (Git Bash) without requiring admin rights, Node.js, or winget.
:: ============================================================================

echo.
echo ============================================
echo   Claude Code Windows Setup
echo   No admin, no Node.js, no winget required!
echo ============================================
echo.

:: Handle UNC paths - copy to temp and run from there
if "%~d0"=="\\" (
    echo Detected network path. Copying to local temp directory...
    set "_LOCAL_SCRIPT=%TEMP%\setup-claude-code.cmd"
    copy "%~f0" "!_LOCAL_SCRIPT!" >nul 2>&1
    cd /d "%TEMP%"
    "!_LOCAL_SCRIPT!"
    exit /b %ERRORLEVEL%
)

:: Create PowerShell script in temp
set "_PS_SCRIPT=%TEMP%\install-claude.ps1"
(
echo $ErrorActionPreference = 'Stop'
echo.
echo Write-Host '==^> Checking for Git Bash...' -ForegroundColor Cyan
echo $bash = 'C:\Program Files\Git\bin\bash.exe'
echo.
echo if ^(-not ^(Test-Path $bash^)^) {
echo     Write-Host '==^> Git not found. Installing Portable Git...' -ForegroundColor Yellow
echo     $arch = $env:PROCESSOR_ARCHITECTURE
echo     $isArm = ^($arch -eq 'ARM64'^)
echo     $assetUrl = $null
echo.    
echo     try {
echo         $api = 'https://api.github.com/repos/git-for-windows/git/releases/latest'
echo         $resp = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent'='claude-setup' } -TimeoutSec 30
echo         if ^($isArm^) {
echo             $asset = $resp.assets ^| Where-Object { $_.name -match 'PortableGit-.*-arm64.*\.7z\.exe$' } ^| Select-Object -First 1
echo         } else {
echo             $asset = $resp.assets ^| Where-Object { $_.name -match 'PortableGit-.*-64-bit.*\.7z\.exe$' } ^| Select-Object -First 1
echo         }
echo         if ^($asset^) { $assetUrl = $asset.browser_download_url }
echo     } catch {
echo         Write-Host 'Warning: Could not fetch latest Git release, using fallback' -ForegroundColor Yellow
echo     }
echo.    
echo     if ^(-not $assetUrl^) {
echo         if ^($isArm^) {
echo             $assetUrl = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/PortableGit-2.47.1-arm64.7z.exe'
echo         } else {
echo             $assetUrl = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/PortableGit-2.47.1-64-bit.7z.exe'
echo         }
echo     }
echo.    
echo     $dst = Join-Path $env:TEMP ^([IO.Path]::GetFileName^($assetUrl^)^)
echo     Write-Host ^('==^> Downloading: ' + [IO.Path]::GetFileName^($assetUrl^)^) -ForegroundColor Cyan
echo.    
echo     try {
echo         Invoke-WebRequest -Uri $assetUrl -OutFile $dst -UseBasicParsing
echo     } catch {
echo         Write-Host 'Error downloading Git. Please check your internet connection.' -ForegroundColor Red
echo         throw $_
echo     }
echo.    
echo     $target = Join-Path $env:LOCALAPPDATA 'PortableGit'
echo     if ^(Test-Path $target^) {
echo         Write-Host '==^> Removing old Portable Git installation...' -ForegroundColor Yellow
echo         Remove-Item -Recurse -Force $target
echo     }
echo.    
echo     New-Item -ItemType Directory -Force -Path $target ^| Out-Null
echo     Write-Host '==^> Extracting Portable Git ^(this may take a minute^)...' -ForegroundColor Cyan
echo     $proc = Start-Process -FilePath $dst -ArgumentList @^('-y', "-o$target", '-gm2'^) -PassThru -Wait
echo.    
echo     if ^($proc.ExitCode -ne 0^) { 
echo         throw "Git extraction failed with exit code: $^($proc.ExitCode^)"
echo     }
echo.    
echo     $bash = Join-Path $target 'bin\bash.exe'
echo     if ^(-not ^(Test-Path $bash^)^) { 
echo         throw 'Git extraction failed: bash.exe not found.'
echo     }
echo     Write-Host '==^> Portable Git installed successfully!' -ForegroundColor Green
echo } else {
echo     Write-Host '==^> Git Bash found at standard location' -ForegroundColor Green
echo }
echo.
echo Write-Host '==^> Setting CLAUDE_CODE_GIT_BASH_PATH environment variable...' -ForegroundColor Cyan
echo [Environment]::SetEnvironmentVariable^('CLAUDE_CODE_GIT_BASH_PATH', $bash, 'User'^)
echo $env:CLAUDE_CODE_GIT_BASH_PATH = $bash
echo.
echo Write-Host '==^> Installing Claude Code via official installer...' -ForegroundColor Cyan
echo try {
echo     $installScript = Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' -UseBasicParsing
echo     Invoke-Expression $installScript
echo } catch {
echo     Write-Host 'Error installing Claude Code. Please check your internet connection.' -ForegroundColor Red
echo     throw $_
echo }
echo.
echo Write-Host '==^> Locating claude.exe...' -ForegroundColor Cyan
echo $searchPaths = @^(
echo     ^(Join-Path $env:USERPROFILE '.local\bin'^),
echo     ^(Join-Path $env:LOCALAPPDATA 'Programs\claude'^),
echo     ^(Join-Path $env:LOCALAPPDATA 'Programs'^),
echo     $env:USERPROFILE
echo ^)
echo.
echo $claudePath = $null
echo foreach ^($searchPath in $searchPaths^) {
echo     if ^(Test-Path $searchPath^) {
echo         $found = Get-ChildItem -Path $searchPath -Filter 'claude.exe' -Recurse -ErrorAction SilentlyContinue ^| Select-Object -First 1
echo         if ^($found^) {
echo             $claudePath = $found.FullName
echo             break
echo         }
echo     }
echo }
echo.
echo if ^(-not $claudePath^) {
echo     throw 'Claude Code installed but claude.exe not found. Please try running the installer again.'
echo }
echo.
echo $claudeDir = Split-Path $claudePath
echo Write-Host ^("==^> Found Claude Code at: $claudePath"^) -ForegroundColor Green
echo.
echo Write-Host '==^> Adding Claude Code to PATH...' -ForegroundColor Cyan
echo $userPath = [Environment]::GetEnvironmentVariable^('Path', 'User'^)
echo if ^($userPath -notlike "*$claudeDir*"^) {
echo     $newPath = "$userPath;$claudeDir"
echo     [Environment]::SetEnvironmentVariable^('Path', $newPath, 'User'^)
echo     Write-Host '==^> PATH updated for future sessions' -ForegroundColor Green
echo }
echo.
echo Write-Host '==^> Saving install directory for current session...' -ForegroundColor Cyan
echo Set-Content -Path "$env:TEMP\_claude_install_dir.txt" -Value $claudeDir -Encoding ASCII
echo.
echo Write-Host ''
echo Write-Host '==^> Verifying installation...' -ForegroundColor Cyan
echo ^& $claudePath --version
echo Write-Host ''
echo Write-Host '==^> Running Claude Code doctor...' -ForegroundColor Cyan
echo ^& $claudePath doctor
echo Write-Host ''
echo Write-Host '============================================' -ForegroundColor Green
echo Write-Host '  Claude Code installed successfully!' -ForegroundColor Green
echo Write-Host '============================================' -ForegroundColor Green
echo Write-Host ''
echo Write-Host 'Next steps:' -ForegroundColor Yellow
echo Write-Host '  1. Run: claude login' -ForegroundColor White
echo Write-Host '  2. Start using: claude [your prompt]' -ForegroundColor White
echo Write-Host ''
echo Write-Host 'Note: You may need to restart your terminal for PATH changes to take effect.' -ForegroundColor Yellow
) > "%_PS_SCRIPT%"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%_PS_SCRIPT%"
set "_EXIT_CODE=%ERRORLEVEL%"

:: Get the Claude directory if it was saved
set "_TMP_OUT=%TEMP%\_claude_install_dir.txt"
if exist "%_TMP_OUT%" (
    set /p _CLAUDE_DIR=<"%_TMP_OUT%"
    if not "!_CLAUDE_DIR!"=="" (
        echo.
        echo ==> Updating PATH for current session...
        set "PATH=!PATH!;!_CLAUDE_DIR!"
    )
    del "%_TMP_OUT%" >nul 2>&1
)

:: Clean up
if exist "%_PS_SCRIPT%" del "%_PS_SCRIPT%" >nul 2>&1

:: Test if claude works in current session
if %_EXIT_CODE% EQU 0 (
    echo.
    echo ==> Testing Claude Code in current session...
    claude --version 2>nul
    if errorlevel 1 (
        echo.
        echo Claude Code is installed but not available in this session.
        echo Please close and reopen your terminal, then run: claude login
    ) else (
        echo.
        echo Claude Code is ready to use!
        echo Run: claude login
    )
)

echo.
pause
exit /b %_EXIT_CODE%