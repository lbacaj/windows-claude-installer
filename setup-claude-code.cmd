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
    "!_LOCAL_SCRIPT!"
    exit /b %ERRORLEVEL%
)

set "_TMP_OUT=%TEMP%\_claude_install_dir.txt"
if exist "%_TMP_OUT%" del "%_TMP_OUT%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "Write-Host '==> Checking for Git Bash...' -ForegroundColor Cyan;" ^
  "$bash = 'C:\Program Files\Git\bin\bash.exe';" ^
  "if (-not (Test-Path $bash)) {" ^
  "  Write-Host '==> Git not found. Installing Portable Git...' -ForegroundColor Yellow;" ^
  "  $arch=$env:PROCESSOR_ARCHITECTURE; $isArm=($arch -eq 'ARM64');" ^
  "  $assetUrl=$null;" ^
  "  try {" ^
  "    $api='https://api.github.com/repos/git-for-windows/git/releases/latest';" ^
  "    $resp=Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent'='claude-setup' } -TimeoutSec 30;" ^
  "    if ($isArm) {" ^
  "      $asset=$resp.assets | Where-Object { $_.name -match 'PortableGit-.*-arm64.*\.7z\.exe$' } | Select-Object -First 1" ^
  "    } else {" ^
  "      $asset=$resp.assets | Where-Object { $_.name -match 'PortableGit-.*-64-bit.*\.7z\.exe$' } | Select-Object -First 1" ^
  "    }" ^
  "    if ($asset) { $assetUrl=$asset.browser_download_url }" ^
  "  } catch { Write-Host 'Warning: Could not fetch latest Git release, using fallback' -ForegroundColor Yellow }" ^
  "  if (-not $assetUrl) {" ^
  "    if ($isArm) {" ^
  "      $assetUrl='https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/PortableGit-2.47.1-arm64.7z.exe'" ^
  "    } else {" ^
  "      $assetUrl='https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/PortableGit-2.47.1-64-bit.7z.exe'" ^
  "    }" ^
  "  }" ^
  "  $dst = Join-Path $env:TEMP ([IO.Path]::GetFileName($assetUrl));" ^
  "  Write-Host ('==> Downloading: ' + [IO.Path]::GetFileName($assetUrl)) -ForegroundColor Cyan;" ^
  "  try {" ^
  "    Invoke-WebRequest -Uri $assetUrl -OutFile $dst -UseBasicParsing;" ^
  "  } catch {" ^
  "    Write-Host 'Error downloading Git. Please check your internet connection.' -ForegroundColor Red;" ^
  "    throw $_" ^
  "  }" ^
  "  $target = Join-Path $env:LOCALAPPDATA 'PortableGit';" ^
  "  if (Test-Path $target) {" ^
  "    Write-Host '==> Removing old Portable Git installation...' -ForegroundColor Yellow;" ^
  "    Remove-Item -Recurse -Force $target" ^
  "  }" ^
  "  New-Item -ItemType Directory -Force -Path $target | Out-Null;" ^
  "  Write-Host '==> Extracting Portable Git (this may take a minute)...' -ForegroundColor Cyan;" ^
  "  $proc = Start-Process -FilePath $dst -ArgumentList @('-y', '-o'+$target, '-gm2') -PassThru -Wait;" ^
  "  if ($proc.ExitCode -ne 0) { throw 'Git extraction failed with exit code: ' + $proc.ExitCode }" ^
  "  $bash = Join-Path $target 'bin\bash.exe';" ^
  "  if (-not (Test-Path $bash)) { throw 'Git extraction failed: bash.exe not found.' }" ^
  "  Write-Host '==> Portable Git installed successfully!' -ForegroundColor Green;" ^
  "} else {" ^
  "  Write-Host '==> Git Bash found at standard location' -ForegroundColor Green;" ^
  "}" ^
  "" ^
  "Write-Host '==> Setting CLAUDE_CODE_GIT_BASH_PATH environment variable...' -ForegroundColor Cyan;" ^
  "[Environment]::SetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', $bash, 'User');" ^
  "$env:CLAUDE_CODE_GIT_BASH_PATH = $bash;" ^
  "" ^
  "Write-Host '==> Installing Claude Code via official installer...' -ForegroundColor Cyan;" ^
  "try {" ^
  "  $installScript = Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' -UseBasicParsing;" ^
  "  Invoke-Expression $installScript;" ^
  "} catch {" ^
  "  Write-Host 'Error installing Claude Code. Please check your internet connection.' -ForegroundColor Red;" ^
  "  throw $_" ^
  "}" ^
  "" ^
  "Write-Host '==> Locating claude.exe...' -ForegroundColor Cyan;" ^
  "$searchPaths = @(" ^
  "  (Join-Path $env:USERPROFILE '.local\bin')," ^
  "  (Join-Path $env:LOCALAPPDATA 'Programs\claude')," ^
  "  (Join-Path $env:LOCALAPPDATA 'Programs')," ^
  "  $env:USERPROFILE" ^
  ");" ^
  "$claudePath = $null;" ^
  "foreach ($searchPath in $searchPaths) {" ^
  "  if (Test-Path $searchPath) {" ^
  "    $found = Get-ChildItem -Path $searchPath -Filter 'claude.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1;" ^
  "    if ($found) {" ^
  "      $claudePath = $found.FullName;" ^
  "      break;" ^
  "    }" ^
  "  }" ^
  "}" ^
  "if (-not $claudePath) {" ^
  "  throw 'Claude Code installed but claude.exe not found. Please try running the installer again.'" ^
  "}" ^
  "$claudeDir = Split-Path $claudePath;" ^
  "Write-Host ('==> Found Claude Code at: ' + $claudePath) -ForegroundColor Green;" ^
  "" ^
  "Write-Host '==> Adding Claude Code to PATH...' -ForegroundColor Cyan;" ^
  "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
  "if ($userPath -notlike ('*' + $claudeDir + '*')) {" ^
  "  $newPath = $userPath + ';' + $claudeDir;" ^
  "  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User');" ^
  "  Write-Host '==> PATH updated for future sessions' -ForegroundColor Green;" ^
  "}" ^
  "" ^
  "Write-Host '==> Saving install directory for current session...' -ForegroundColor Cyan;" ^
  "Set-Content -Path '%_TMP_OUT%' -Value $claudeDir -Encoding ASCII;" ^
  "" ^
  "Write-Host ''" ^
  "Write-Host '==> Verifying installation...' -ForegroundColor Cyan;" ^
  "& $claudePath --version;" ^
  "Write-Host ''" ^
  "Write-Host '==> Running Claude Code doctor...' -ForegroundColor Cyan;" ^
  "& $claudePath doctor;" ^
  "Write-Host ''" ^
  "Write-Host '============================================' -ForegroundColor Green;" ^
  "Write-Host '  Claude Code installed successfully!' -ForegroundColor Green;" ^
  "Write-Host '============================================' -ForegroundColor Green;" ^
  "Write-Host ''" ^
  "Write-Host 'Next steps:' -ForegroundColor Yellow;" ^
  "Write-Host '  1. Run: claude login' -ForegroundColor White;" ^
  "Write-Host '  2. Start using: claude [your prompt]' -ForegroundColor White;" ^
  "Write-Host ''" ^
  "Write-Host 'Note: You may need to restart your terminal for PATH changes to take effect.' -ForegroundColor Yellow"

:: Update PATH for current CMD session
if exist "%_TMP_OUT%" (
  set /p _CLAUDE_DIR=<"%_TMP_OUT%"
  if not "!_CLAUDE_DIR!"=="" (
    echo.
    echo ==> Updating PATH for current session...
    set "PATH=!PATH!;!_CLAUDE_DIR!"
  )
  del "%_TMP_OUT%" >nul 2>&1
)

:: Test if claude works in current session
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

echo.
pause