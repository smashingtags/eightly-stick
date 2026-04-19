$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Resolve-Path "$ScriptDir\..").Path
$DataDir = "$RootDir\data"
$EnvFile = "$DataDir\ai_settings.env"
$ModelsDir = "$DataDir\models"
$OllamaDir = "$DataDir\ollama"

$ModelCatalog = @(
    # Category 1: Gemma 4
    @{ Num=1;  Category="Gemma 4 Family (Multimodal)"; Name="Gemma 4 (E2B)"; Tag="gemma4:e2b"; Size="7.2"; Input="Text, Image"; Label="STANDARD"; Badge="TINY" },
    @{ Num=2;  Category="Gemma 4 Family (Multimodal)"; Name="Gemma 4 (E4B)"; Tag="gemma4:e4b"; Size="9.6"; Input="Text, Image"; Label="STANDARD"; Badge="RECOMMENDED" },
    @{ Num=3;  Category="Gemma 4 Family (Multimodal)"; Name="Gemma 4 (26B)"; Tag="gemma4:26b"; Size="18.0"; Input="Text, Image"; Label="POWERFUL"; Badge="MoE" },
    @{ Num=4;  Category="Gemma 4 Family (Multimodal)"; Name="Gemma 4 (31B)"; Tag="gemma4:31b"; Size="20.0"; Input="Text, Image"; Label="POWERFUL"; Badge="DENSE" },
    
    # Category 2: Most Popular Open Source
    @{ Num=5;  Category="Most Popular Open Source"; Name="MiniMax M2.7"; Tag="minimax-m2.7:cloud"; Size="-"; Input="Text"; Label="CLOUD"; Badge="" },
    @{ Num=6;  Category="Most Popular Open Source"; Name="Kimi K2.5"; Tag="kimi-k2.5:cloud"; Size="-"; Input="Text, Image"; Label="CLOUD"; Badge="" },
    @{ Num=7;  Category="Most Popular Open Source"; Name="Gemini 3 Flash"; Tag="gemini-3-flash-preview:latest"; Size="-"; Input="Text"; Label="CLOUD"; Badge="1M CTX" },
    @{ Num=8;  Category="Most Popular Open Source"; Name="Kimi K2 Thinking"; Tag="kimi-k2-thinking:cloud"; Size="-"; Input="Text"; Label="CLOUD"; Badge="REASONING" },
    
    # Category 3: Qwen 3.5 & Ministral 3
    @{ Num=9;  Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Qwen 3.5 (0.8B)"; Tag="qwen3.5:0.8b"; Size="1.0"; Input="Text, Image"; Label="STANDARD"; Badge="MICRO" },
    @{ Num=10; Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Qwen 3.5 (2B)"; Tag="qwen3.5:2b"; Size="2.7"; Input="Text, Image"; Label="STANDARD"; Badge="TINY" },
    @{ Num=11; Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Qwen 3.5 (4B)"; Tag="qwen3.5:4b"; Size="3.4"; Input="Text, Image"; Label="STANDARD"; Badge="BALANCED" },
    @{ Num=12; Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Qwen 3.5 (9B)"; Tag="qwen3.5:9b"; Size="6.6"; Input="Text, Image"; Label="STANDARD"; Badge="RECOMMENDED" },
    @{ Num=13; Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Ministral 3 (3B)"; Tag="ministral-3:3b"; Size="3.0"; Input="Text, Image"; Label="STANDARD"; Badge="FAST" },
    @{ Num=14; Category="Qwen 3.5 & Ministral 3 (Daily Drivers)"; Name="Ministral 3 (8B)"; Tag="ministral-3:8b"; Size="6.0"; Input="Text, Image"; Label="STANDARD"; Badge="DAILY" },
    
    # Category 4: Heavyweight & Coders
    @{ Num=15; Category="Heavyweights & Code Specialists"; Name="GLM 4.7 Flash (q4)"; Tag="glm-4.7-flash:q4_K_M"; Size="19.0"; Input="Text"; Label="POWERFUL"; Badge="198K CTX" },
    @{ Num=16; Category="Heavyweights & Code Specialists"; Name="GPT-OSS (20B)"; Tag="gpt-oss:20b"; Size="14.0"; Input="Text"; Label="POWERFUL"; Badge="OPEN" },
    @{ Num=17; Category="Heavyweights & Code Specialists"; Name="Qwen 3 Coder"; Tag="qwen3-coder:latest"; Size="19.0"; Input="Text"; Label="STANDARD"; Badge="CODING" }
)

function Get-USBFreeSpaceGB {
    try {
        $driveLetter = (Get-Item $ScriptDir).PSDrive.Name
        $drive = Get-PSDrive $driveLetter -ErrorAction SilentlyContinue
        if ($drive) { return [math]::Round($drive.Free / 1GB, 1) }
    } catch {}
    return -1
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   PORTABLE AI USB - Local Model Setup (Official)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$freeGB = Get-USBFreeSpaceGB
if ($freeGB -gt 0) { Write-Host "  USB Free Space: $freeGB GB" -ForegroundColor DarkGray; Write-Host "" }

Write-Host "[1/4] Choose your AI model(s):" -ForegroundColor Yellow

$currentCategory = ""
foreach ($m in $ModelCatalog) {
    if ($m.Category -ne $currentCategory) {
        $currentCategory = $m.Category
        Write-Host "`n  --- $currentCategory ---" -ForegroundColor Cyan
    }
    
    if ($m.Label -eq "UNCENSORED") { $labelColor = "Red"; $labelStr = " [UNCENSORED]" }
    elseif ($m.Label -in @("UTILITY", "VISION", "POWERFUL")) { $labelColor = "DarkYellow"; $labelStr = " [$($m.Label)]" }
    elseif ($m.Label -eq "CLOUD") { $labelColor = "Magenta"; $labelStr = " [CLOUD-API]" }
    else { $labelColor = "DarkCyan"; $labelStr = " [STANDARD]" }
    
    $badgeStr = if ($m.Badge) { " - $($m.Badge)" } else { "" }
    
    $padNum = $m.Num.ToString().PadLeft(2)
    Write-Host "  [$padNum]" -ForegroundColor Yellow -NoNewline
    Write-Host " $($m.Name.PadRight(24))" -ForegroundColor White -NoNewline
    Write-Host ("[" + $m.Input + "]").PadRight(16) -ForegroundColor DarkCyan -NoNewline
    
    $sizeStr = if ($m.Size -eq "-") { " (-)".PadRight(12) } else { " (~$($m.Size) GB)".PadRight(12) }
    Write-Host $sizeStr -ForegroundColor DarkGray -NoNewline
    
    Write-Host $labelStr -ForegroundColor $labelColor -NoNewline
    Write-Host $badgeStr -ForegroundColor Magenta
}

Write-Host "`n  [C] CUSTOM - Enter an Official Ollama Tag" -ForegroundColor Green
Write-Host "      Browse ALL models here: " -ForegroundColor Gray -NoNewline
Write-Host "https://ollama.com/library" -ForegroundColor Blue
Write-Host "`n  ------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Enter number(s) separated by commas  (e.g. 1,13)" -ForegroundColor Gray
Write-Host "  Type 'all' for every preset model, 'c' for custom`n" -ForegroundColor Gray

$UserChoice = Read-Host "  Your choice"
if ([string]::IsNullOrWhiteSpace($UserChoice)) {
    Write-Host "`n  No input! Defaulting to [1] Gemma 4..." -ForegroundColor Yellow
    $UserChoice = "1"
}

$SelectedModels = @()
$HasCustom = $false

if ($UserChoice.Trim().ToLower() -eq "all") { $SelectedModels = @($ModelCatalog) }
else {
    foreach ($t in ($UserChoice -split "," | ForEach-Object { $_.Trim().ToLower() })) {
        if ($t -eq "c" -or $t -eq "custom") { $HasCustom = $true }
        elseif ($t -match '^\d+$') {
            $num = [int]$t
            $found = $ModelCatalog | Where-Object { $_.Num -eq $num }
            if ($found -and -Not ($SelectedModels | Where-Object { $_.Num -eq $num })) { $SelectedModels += $found }
        }
    }
}

if ($HasCustom) {
    Write-Host "`n  ---- Custom Model Setup ----" -ForegroundColor Green
    $customTag = Read-Host "  Ollama Tag (e.g. mistral-nemo, phi3)"
    if ($customTag) {
        $customName = (CultureInfo.CurrentCulture.TextInfo.ToTitleCase($customTag.ToLower()))
        $SelectedModels += @{ Num=99; Name="Custom: $customName"; Tag=$customTag.Trim(); Size="?"; Label="CUSTOM" }
        Write-Host "  Custom model added!" -ForegroundColor Green
    }
}

if ($SelectedModels.Count -eq 0) { Write-Host "`n  ERROR: No models selected!" -ForegroundColor Red; exit 1 }

$totalSizeGB = 0
foreach ($m in $SelectedModels) {
    if ($m.Size -match '\d') { $totalSizeGB += [double]$m.Size }
}

if ($totalSizeGB -ge ($freeGB - 1) -and $freeGB -gt 0 -or $UserChoice.Trim().ToLower() -eq "all") {
    Write-Host "`n  WARNING: These models total ~$([math]::Ceiling($totalSizeGB)) GB. USB drive has $freeGB GB free!" -ForegroundColor Red
    $confirm = Read-Host "  Continue? (yes/no)"
    if ($confirm.Trim().ToLower() -ne "yes" -and $confirm.Trim().ToLower() -ne "y") { exit }
}

# Directories
New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null
New-Item -ItemType Directory -Force -Path "$OllamaDir\data" | Out-Null
Write-Host "`n[2/4] Created storage folders." -ForegroundColor Green

# Ollama Engine Setup
Write-Host "`n[3/4] Setting up Portable Ollama Engine..." -ForegroundColor Yellow
$OllamaURL = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
$OllamaDest = "$OllamaDir\ollama.zip"
$OllamaExe = "$OllamaDir\ollama.exe"

if (Test-Path $OllamaExe) { 
    Write-Host "      Engine already installed!" -ForegroundColor Green 
} else {
    Write-Host "      Downloading Ollama Engine (~100MB)..." -ForegroundColor Yellow
    curl.exe -L --ssl-no-revoke --progress-bar $OllamaURL -o $OllamaDest
    if (Test-Path $OllamaDest) {
        Write-Host "      Extracting to USB..." -ForegroundColor Yellow
        Expand-Archive -Path $OllamaDest -DestinationPath $OllamaDir -Force
        Remove-Item $OllamaDest -Force -ErrorAction SilentlyContinue
        Write-Host "      Engine Installed successfully!" -ForegroundColor Green
    } else { 
        Write-Host "      ERROR: Failed to download engine!" -ForegroundColor Red
        exit 1 
    }
}

# Downloading Models via Ollama
Write-Host "`n[4/4] Pulling Models (This guarantees perfectly configured Tool Support)..." -ForegroundColor Yellow

$downloadErrors = @()

$env:OLLAMA_MODELS = "$OllamaDir\data"
Write-Host "`n      Starting background Ollama server on USB..." -ForegroundColor DarkGray
$ServerProcess = Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 5

$idx = 1
foreach ($m in $SelectedModels) {
    Write-Host "`n  ($idx/$($SelectedModels.Count)) Pulling $($m.Name) [$($m.Tag)]..." -ForegroundColor Yellow
    $idx++
    Write-Host "      Do not close this window! Download may take a while depending on bandwidth." -ForegroundColor Magenta
    
    # Run the pull command directly so the user sees the progress bar
    try {
        & $OllamaExe pull $m.Tag
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE" }
        Write-Host "      Pull complete!" -ForegroundColor Green
    } catch {
        Write-Host "      FAILED to pull model: $($m.Tag)" -ForegroundColor Red
        $downloadErrors += $m.Name
    }
}

Write-Host "`n      Stopping background Ollama server..." -ForegroundColor DarkGray
Stop-Process -Id $ServerProcess.Id -Force -ErrorAction SilentlyContinue

# Record Models for the Dashboard
$installedList = $SelectedModels | ForEach-Object { "$($_.Tag)|$($_.Name)|$($_.Label)" }
if (Test-Path "$ModelsDir\installed-models.txt") {
    $existing = Get-Content "$ModelsDir\installed-models.txt"
    $installedList = ($existing + $installedList) | Select-Object -Unique
}
Set-Content -Path "$ModelsDir\installed-models.txt" -Value ($installedList -join "`n") -Force -Encoding UTF8

Write-Host "`n[5/5] Finalizing Configurations..." -ForegroundColor Yellow

$firstModelTag = $SelectedModels[0].Tag
$configContent = "AI_PROVIDER=ollama`nCLAUDE_CODE_USE_OPENAI=1`nOPENAI_API_KEY=ollama`nOPENAI_BASE_URL=http://localhost:11434/v1`nOPENAI_MODEL=$firstModelTag`nAI_DISPLAY_MODEL=$firstModelTag"
Set-Content -Path $EnvFile -Value $configContent -Force -Encoding Ascii
Write-Host "      Default Model set to: $firstModelTag" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($downloadErrors.Count -gt 0) { Write-Host "   SETUP COMPLETE (with some download errors)" -ForegroundColor Yellow }
else { Write-Host "   SETUP COMPLETE! LOCAL AI AGENTS ARE READY!" -ForegroundColor Green }
Write-Host "==========================================================" -ForegroundColor Cyan
