<#
.SYNOPSIS
  Offline installer for Conductor skills in Codex (Windows).

.DESCRIPTION
  Non-destructive by default:
  - Does NOT delete files.
  - Does NOT overwrite existing skill folders or init scripts.

  Installs into your user profile (no admin required):
  - Skills: %USERPROFILE%\.codex\skills\<skill>\SKILL.md
  - Init cmd: %USERPROFILE%\.codex\bin\codex_conductor_init.cmd
  - Init ps1: %USERPROFILE%\.codex\bin\codex_conductor_init.ps1

  Adds <bin> to the user PATH unless -SkipPathUpdate is set.

  Transparency note:
  - This installer uses plain markdown skill files from ./skills (next to this script).
  - No base64 payloads are used for skill installation.

.PARAMETER CodexHome
  Global Codex home directory. Default: %USERPROFILE%\.codex

.PARAMETER BinDir
  Where to install codex_conductor_init. Default: <CodexHome>\bin

.PARAMETER SkipPathUpdate
  If set, do not modify your user PATH.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\conductor_for_codex.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\conductor_for_codex.ps1 -SkipPathUpdate
#>
param(
  [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex'),
  [string]$BinDir = '',
  [switch]$SkipPathUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string] $path) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Ensure-PathContains([string] $dir) {
  if ($SkipPathUpdate) { return }
  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($null -eq $current) { $current = '' }
  $parts = $current.Split(';') | Where-Object { $_ -ne '' }
  if ($parts -contains $dir) {
    Write-Host "  Already in user PATH: $dir" -ForegroundColor Gray
    return
  }
  [Environment]::SetEnvironmentVariable('Path', (($parts + $dir) -join ';'), 'User')
  Write-Host "  Added to user PATH: $dir" -ForegroundColor Green
  Write-Host '  Open a new terminal for PATH changes to take effect.' -ForegroundColor Yellow
}

Write-Host '===============================================' -ForegroundColor Cyan
Write-Host '  Conductor for Codex - Installer (Windows)' -ForegroundColor Cyan
Write-Host '===============================================' -ForegroundColor Cyan
Write-Host ''

if ([string]::IsNullOrWhiteSpace($BinDir)) {
  $BinDir = Join-Path $CodexHome 'bin'
}

Ensure-Dir $CodexHome
Ensure-Dir $BinDir
Ensure-Dir (Join-Path $CodexHome 'skills')

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$bundledSkillsRoot = Join-Path $scriptDir 'skills'
$bundledTemplatesRoot = Join-Path $scriptDir 'templates'
$skillNames = @('conductor-setup','conductor-status','conductor-implement','conductor-newTrack','conductor-review','conductor-revert','update-conductor')

if (-not (Test-Path $bundledSkillsRoot)) {
  throw "Missing bundled skills directory: $bundledSkillsRoot"
}

foreach ($name in $skillNames) {
  $srcFile = Join-Path (Join-Path $bundledSkillsRoot $name) 'SKILL.md'
  if (-not (Test-Path $srcFile)) {
    throw "Missing bundled skill file: $srcFile"
  }

  $dstDir = Join-Path (Join-Path $CodexHome 'skills') $name
  $dstFile = Join-Path $dstDir 'SKILL.md'

  if (Test-Path $dstDir) {
    Write-Host "  Exists, skipping: $dstDir" -ForegroundColor Gray
    continue
  }

  Ensure-Dir $dstDir
  Copy-Item -Path $srcFile -Destination $dstFile -Force
  Write-Host "  Installed: $dstDir" -ForegroundColor Green
}

# Install Conductor templates (skip if destination exists)
if (Test-Path $bundledTemplatesRoot) {
  $dstTemplatesRoot = Join-Path $CodexHome 'conductor\templates'
  if (Test-Path $dstTemplatesRoot) {
    Write-Host "  Exists, skipping templates: $dstTemplatesRoot" -ForegroundColor Gray
  } else {
    Ensure-Dir $dstTemplatesRoot
    Copy-Item -Recurse -Force -Path (Join-Path $bundledTemplatesRoot '*') -Destination $dstTemplatesRoot
    Get-ChildItem -Path $dstTemplatesRoot -Filter '.DS_Store' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "  Installed templates: $dstTemplatesRoot" -ForegroundColor Green
  }
} else {
  Write-Host "  Missing bundled templates directory (skipping): $bundledTemplatesRoot" -ForegroundColor Yellow
}

# Install Conductor skill catalog (skip if destination exists)
$catalogSrc = Join-Path $bundledSkillsRoot 'catalog.md'
if (Test-Path $catalogSrc) {
  $catalogDstDir = Join-Path $CodexHome 'conductor\skills'
  $catalogDst = Join-Path $catalogDstDir 'catalog.md'
  if (Test-Path $catalogDst) {
    Write-Host "  Exists, skipping skill catalog: $catalogDst" -ForegroundColor Gray
  } else {
    Ensure-Dir $catalogDstDir
    Copy-Item -Path $catalogSrc -Destination $catalogDst -Force
    Write-Host "  Installed skill catalog: $catalogDst" -ForegroundColor Green
  }
} else {
  Write-Host "  Missing bundled skill catalog (skipping): $catalogSrc" -ForegroundColor Yellow
}

# Plain-text init script for auditability.
$initPs1 = @'
param(
  [string] $RepoRoot = (Get-Location).Path,
  [string] $CodexHome = (Join-Path $env:USERPROFILE '.codex')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string] $path) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Ensure-GitignoreHas([string] $path, [string] $line) {
  if (-not (Test-Path $path)) {
    Set-Content -Path $path -Value ($line + "`r`n") -Encoding UTF8
    return
  }
  $lines = Get-Content $path
  if ($lines -contains $line) { return }
  Add-Content -Path $path -Value $line
}

function Ensure-AgentsRule([string] $path, [string] $rule) {
  if (-not (Test-Path $path)) {
    Set-Content -Path $path -Value ("# AGENTS.md`r`n`r`n" + $rule + "`r`n") -Encoding UTF8
    Write-Host "  Created AGENTS.md" -ForegroundColor Green
    return
  }
  $lines = Get-Content $path
  if (-not ($lines -contains $rule)) {
    Add-Content -Path $path -Value $rule
  }
  Write-Host "  Ensured AGENTS.md contains conductor-status rule" -ForegroundColor Green
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  codex_conductor_init (Conductor for Codex)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$skillNames = @('conductor-setup','conductor-status','conductor-implement','conductor-newTrack','conductor-review','conductor-revert','update-conductor')
$dstSkillsRoot = Join-Path $RepoRoot '.codex\skills'
Ensure-Dir $dstSkillsRoot

foreach ($name in $skillNames) {
  $src = Join-Path $CodexHome (Join-Path 'skills' $name)
  if (-not (Test-Path $src)) { throw "Missing installed skill: $src" }

  $dst = Join-Path $dstSkillsRoot $name
  if (Test-Path $dst) {
    Write-Host "  Exists, skipping: .codex\skills\$name" -ForegroundColor Gray
    continue
  }

  Copy-Item -Recurse -Force -Path $src -Destination $dst
  Write-Host "  Installed: .codex\skills\$name" -ForegroundColor Green
}

$srcTemplatesRoot = Join-Path $CodexHome 'conductor\templates'
$dstTemplatesRoot = Join-Path $RepoRoot 'conductor\templates'
if (Test-Path $srcTemplatesRoot) {
  if (Test-Path $dstTemplatesRoot) {
    Write-Host "  Exists, skipping: conductor\\templates" -ForegroundColor Gray
  } else {
    Ensure-Dir $dstTemplatesRoot
    Copy-Item -Recurse -Force -Path (Join-Path $srcTemplatesRoot '*') -Destination $dstTemplatesRoot
    Get-ChildItem -Path $dstTemplatesRoot -Filter '.DS_Store' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "  Installed: conductor\\templates" -ForegroundColor Green
  }
} else {
  Write-Host "  NOTE: Missing templates at $srcTemplatesRoot (re-run conductor_for_codex.ps1)" -ForegroundColor Yellow
}

$srcCatalog = Join-Path $CodexHome 'conductor\skills\catalog.md'
$dstCatalogDir = Join-Path $RepoRoot 'conductor\skills'
$dstCatalog = Join-Path $dstCatalogDir 'catalog.md'
if (Test-Path $srcCatalog) {
  if (Test-Path $dstCatalog) {
    Write-Host "  Exists, skipping: conductor\\skills\\catalog.md" -ForegroundColor Gray
  } else {
    Ensure-Dir $dstCatalogDir
    Copy-Item -Path $srcCatalog -Destination $dstCatalog -Force
    Write-Host "  Installed: conductor\\skills\\catalog.md" -ForegroundColor Green
  }
} else {
  Write-Host "  NOTE: Missing skill catalog at $srcCatalog (re-run conductor_for_codex.ps1)" -ForegroundColor Yellow
}

$agentsRule = 'Always run $conductor-status before doing anything else.'
Ensure-AgentsRule -path (Join-Path $RepoRoot 'AGENTS.md') -rule $agentsRule

Ensure-GitignoreHas -path (Join-Path $RepoRoot '.gitignore') -line 'conductor/'
Write-Host "  Ensured .gitignore contains conductor/" -ForegroundColor Green

Write-Host ""
Write-Host "Next:" -ForegroundColor White
Write-Host "  1) Start Codex in this repo" -ForegroundColor White
Write-Host '  2) Run $conductor-status' -ForegroundColor White
'@

$initCmd = @'
@echo off
setlocal

set "CODEX_HOME=%USERPROFILE%\.codex"
set "PS_SCRIPT=%CODEX_HOME%\bin\codex_conductor_init.ps1"

if not exist "%PS_SCRIPT%" (
  echo codex_conductor_init: missing "%PS_SCRIPT%"
  echo Re-run conductor_for_codex.ps1
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
exit /b %ERRORLEVEL%
'@

$initPs1Path = Join-Path $BinDir 'codex_conductor_init.ps1'
$initCmdPath = Join-Path $BinDir 'codex_conductor_init.cmd'

if (-not (Test-Path $initPs1Path)) {
  Set-Content -Path $initPs1Path -Value $initPs1 -Encoding UTF8
  Write-Host "  Created: $initPs1Path" -ForegroundColor Green
} else {
  Write-Host "  Exists, skipping: $initPs1Path" -ForegroundColor Gray
}

if (-not (Test-Path $initCmdPath)) {
  Set-Content -Path $initCmdPath -Value $initCmd -Encoding ASCII
  Write-Host "  Created: $initCmdPath" -ForegroundColor Green
} else {
  Write-Host "  Exists, skipping: $initCmdPath" -ForegroundColor Gray
}

Ensure-PathContains -dir $BinDir

Write-Host ''
Write-Host 'Run in any repo directory:' -ForegroundColor White
Write-Host '  codex_conductor_init.cmd' -ForegroundColor White
