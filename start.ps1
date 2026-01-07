# PowerShell script to check, install dependencies and run app.py
# Run: .\start.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Atlassian Marketplace Scraper - Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "[1/5] Checking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found! Install Python 3.8+ from python.org" -ForegroundColor Red
    Write-Host "Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    pause
    exit 1
}

# Check/create virtual environment
Write-Host ""
Write-Host "[2/5] Checking virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "[OK] Virtual environment found" -ForegroundColor Green
} else {
    Write-Host "[INFO] Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create virtual environment" -ForegroundColor Red
        pause
        exit 1
    }
    Write-Host "[OK] Virtual environment created" -ForegroundColor Green
}

# Check if requirements.txt exists
if (-not (Test-Path "requirements.txt")) {
    Write-Host "[ERROR] requirements.txt not found!" -ForegroundColor Red
    pause
    exit 1
}

# Check/install dependencies
Write-Host ""
Write-Host "[3/5] Checking dependencies..." -ForegroundColor Yellow
$venvPython = "venv\Scripts\python.exe"
$venvPip = "venv\Scripts\pip.exe"

# Check if pip is installed
if (-not (Test-Path $venvPip)) {
    Write-Host "[INFO] Installing pip..." -ForegroundColor Yellow
    & $venvPython -m ensurepip --upgrade
}

# Check if packages are installed
$needsInstall = $false
try {
    & $venvPython -c "import flask" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $needsInstall = $true
    }
} catch {
    $needsInstall = $true
}

if ($needsInstall) {
    Write-Host "[INFO] Installing dependencies from requirements.txt..." -ForegroundColor Yellow
    & $venvPython -m pip install --upgrade pip --quiet
    & $venvPython -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        pause
        exit 1
    }
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Dependencies already installed" -ForegroundColor Green
}

# Check Playwright browser (optional, but recommended)
Write-Host ""
Write-Host "[4/5] Checking Playwright browser..." -ForegroundColor Yellow
try {
    & $venvPython -c "from playwright.sync_api import sync_playwright; sync_playwright().start().chromium.launch()" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Playwright browser not installed"
    }
    Write-Host "[OK] Playwright browser found" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Playwright browser not installed" -ForegroundColor Yellow
    Write-Host "  Installing Playwright Chromium (this may take a few minutes)..." -ForegroundColor Yellow
    & $venvPython -m playwright install chromium
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Playwright Chromium installed" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Failed to install Playwright browser" -ForegroundColor Yellow
        Write-Host "  You can install it manually later with: venv\Scripts\python.exe -m playwright install chromium" -ForegroundColor Yellow
    }
}

# Check/create .env file
Write-Host ""
Write-Host "[5/5] Checking configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "[OK] Configuration file (.env) found" -ForegroundColor Green
} else {
    Write-Host "[INFO] .env file not found, creating from template..." -ForegroundColor Yellow

    # Check if .env.example exists
    if (-not (Test-Path ".env.example")) {
        Write-Host "[ERROR] .env.example not found!" -ForegroundColor Red
        Write-Host "  Cannot create .env file without template" -ForegroundColor Red
        pause
        exit 1
    }

    # Copy .env.example to .env
    Copy-Item ".env.example" ".env"

    # Generate SECRET_KEY and replace in .env
    try {
        $secretKey = & $venvPython -c "import secrets; print(secrets.token_hex(32))" 2>$null
        if (-not $secretKey -or $secretKey -eq "") {
            throw "Failed to generate"
        }
        $secretKey = $secretKey.Trim()

        # Read .env content
        $envContent = Get-Content ".env" -Raw

        # Replace SECRET_KEY placeholder
        $envContent = $envContent -replace 'SECRET_KEY=change-this-to-a-random-secret-key', "SECRET_KEY=$secretKey"

        # Write back to .env
        [System.IO.File]::WriteAllText((Join-Path $PWD ".env"), $envContent, [System.Text.Encoding]::UTF8)

        Write-Host "[OK] .env file created from .env.example" -ForegroundColor Green
        Write-Host "  [OK] SECRET_KEY automatically generated" -ForegroundColor Green
    } catch {
        Write-Host "[OK] .env file created from .env.example" -ForegroundColor Green
        Write-Host "  [WARNING] Could not generate SECRET_KEY automatically" -ForegroundColor Yellow
        Write-Host "  Generate manually with: python -c `"import secrets; print(secrets.token_hex(32))`"" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "[IMPORTANT] Edit .env file to configure:" -ForegroundColor Yellow
    Write-Host "  - MARKETPLACE_USERNAME and MARKETPLACE_API_TOKEN (your credentials)" -ForegroundColor White
    Write-Host "  - ADMIN_USERNAME and ADMIN_PASSWORD (for management interface)" -ForegroundColor White
    Write-Host "  - Storage paths if you want to use custom locations" -ForegroundColor White
    Write-Host ""
}

# Launch application
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Flask application..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Web interface will be available at: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Run app.py using venv Python
& $venvPython app.py

# If we get here, the app has stopped
Write-Host ""
Write-Host "Application stopped." -ForegroundColor Yellow
pause

