# Downloads and installs VS Code extensions + coding CLIs into the portable stick.
# Called by Setup_First_Time.bat after VS Code Portable is downloaded.
# Idempotent: skips anything already installed.

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$Root = (Get-Item $PSScriptRoot).Parent.FullName
$VSCodeDir = Join-Path $Root 'tools\vscode'
$VSCodeExe = Join-Path $VSCodeDir 'bin\code.cmd'
$BinDir = Join-Path $PSScriptRoot 'bin'
$NodeDir = Get-ChildItem -Path $BinDir -Directory -Filter 'node-v*' -ErrorAction SilentlyContinue | Select-Object -First 1
$DataDir = Join-Path $Root 'data'
$WorkspaceConfig = Join-Path $Root 'tools\vscode-workspace'

function Write-Ok   { param([string]$T) Write-Host "     [OK] $T" -ForegroundColor Green }
function Write-Info { param([string]$T) Write-Host "       $T" -ForegroundColor DarkGray }
function Write-Warn { param([string]$T) Write-Host "     [!] $T" -ForegroundColor Yellow }

# ── VS Code Extensions ──────────────────────────────────────
if (Test-Path $VSCodeExe) {
    Write-Host ""
    Write-Host "  Installing VS Code extensions..." -ForegroundColor Cyan

    # Set portable data dir so extensions install INSIDE the stick
    $env:VSCODE_PORTABLE = Join-Path $VSCodeDir 'data'
    if (-not (Test-Path $env:VSCODE_PORTABLE)) { New-Item -ItemType Directory -Force -Path $env:VSCODE_PORTABLE | Out-Null }

    # Copy pre-configured settings into VS Code's portable data
    $userSettings = Join-Path $env:VSCODE_PORTABLE 'user-data\User'
    if (-not (Test-Path $userSettings)) { New-Item -ItemType Directory -Force -Path $userSettings | Out-Null }
    if (Test-Path (Join-Path $WorkspaceConfig 'settings.json')) {
        Copy-Item (Join-Path $WorkspaceConfig 'settings.json') (Join-Path $userSettings 'settings.json') -Force
        Write-Ok "VS Code settings pre-configured (Ollama :11438, Continue, Cline)"
    }

    # Extensions to install from the marketplace.
    # VS Code CLI handles download + install in one shot.
    $extensions = @(
        @{ id = 'continue.continue';          name = 'Continue (AI autocomplete + chat, supports Ollama)' },
        @{ id = 'saoudrizwan.claude-dev';      name = 'Cline (autonomous coding agent)' },
        @{ id = 'anthropic.claude-code';       name = 'Claude Code (official Anthropic extension)' },
        @{ id = 'ms-python.python';            name = 'Python' },
        @{ id = 'eamodio.gitlens';             name = 'GitLens (git blame, history)' },
        @{ id = 'esbenp.prettier-vscode';      name = 'Prettier (code formatter)' },
        @{ id = 'dbaeumer.vscode-eslint';      name = 'ESLint' }
    )

    foreach ($ext in $extensions) {
        Write-Info "Installing $($ext.name)..."
        & $VSCodeExe --install-extension $ext.id --force 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok $ext.name
        } else {
            Write-Warn "$($ext.name) install failed (may need internet or manual install)"
        }
    }
    Write-Host ""
} else {
    Write-Warn "VS Code Portable not found at $VSCodeDir — skipping extension install."
    Write-Info "Run Setup_First_Time.bat and choose Y for VS Code to enable this."
}

# ── Coding CLI Tools (npm) ───────────────────────────────────
if ($NodeDir) {
    $npm = Join-Path $NodeDir.FullName 'npm.cmd'
    $env:PATH = "$($NodeDir.FullName);$env:PATH"
    Write-Host "  Installing coding CLI tools..." -ForegroundColor Cyan

    # Codex (OpenAI's coding agent)
    Write-Info "Installing Codex CLI (OpenAI)..."
    & $npm install --prefix $BinDir @openai/codex --no-audit --no-fund --loglevel=error 2>$null | Out-Null
    if (Test-Path (Join-Path $BinDir 'node_modules\@openai\codex')) { Write-Ok "Codex CLI" } else { Write-Warn "Codex CLI install failed" }

    # Claude Code CLI (Anthropic) — the npm package, not the VS Code extension
    Write-Info "Installing Claude Code CLI (Anthropic)..."
    & $npm install --prefix $BinDir @anthropic-ai/claude-code --no-audit --no-fund --loglevel=error 2>$null | Out-Null
    if (Test-Path (Join-Path $BinDir 'node_modules\@anthropic-ai\claude-code')) { Write-Ok "Claude Code CLI" } else { Write-Warn "Claude Code CLI install failed" }

    Write-Host ""
} else {
    Write-Warn "Node.js not found — skipping CLI tool install."
}

# ── Aider (pip) ──────────────────────────────────────────────
$pythonDir = Join-Path $BinDir 'python'
$pipExe = $null
if (Test-Path (Join-Path $pythonDir 'python.exe')) {
    $pipExe = Join-Path $pythonDir 'Scripts\pip.exe'
    if (-not (Test-Path $pipExe)) { $pipExe = Join-Path $pythonDir 'Scripts\pip3.exe' }
}
if (-not $pipExe -or -not (Test-Path $pipExe)) {
    # Try system pip
    $pipExe = (Get-Command pip3 -ErrorAction SilentlyContinue).Source
    if (-not $pipExe) { $pipExe = (Get-Command pip -ErrorAction SilentlyContinue).Source }
}

if ($pipExe) {
    Write-Host "  Installing Aider (AI pair programmer)..." -ForegroundColor Cyan
    & $pipExe install --target (Join-Path $BinDir 'pip_packages') aider-chat --quiet 2>$null | Out-Null
    if (Test-Path (Join-Path $BinDir 'pip_packages\aider')) {
        Write-Ok "Aider installed"
    } else {
        Write-Warn "Aider install failed (may need full Python, not embed)"
    }
    Write-Host ""
} else {
    Write-Warn "pip not found — skipping Aider install."
    Write-Info "Install portable Python during setup to enable Aider."
}

Write-Host "  Done. All available coding tools installed." -ForegroundColor Green
Write-Host ""
