# PowerShell script for installing Atlassian Marketplace Scraper on Windows
# Run: .\install.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Atlassian Marketplace Scraper - Installer" -ForegroundColor Cyan
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
    exit 1
}

# Create virtual environment
Write-Host ""
Write-Host "[2/5] Creating virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "[OK] Virtual environment already exists" -ForegroundColor Green
} else {
    python -m venv venv
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Virtual environment created" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
}

# Install dependencies
Write-Host ""
Write-Host "[3/5] Installing dependencies..." -ForegroundColor Yellow
if (Test-Path "requirements.txt") {
    & "venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
    & "venv\Scripts\python.exe" -m pip install -r requirements.txt
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[ERROR] requirements.txt not found" -ForegroundColor Red
    exit 1
}

# Install Playwright browser
Write-Host ""
Write-Host "[4/5] Installing Playwright browser (Chromium)..." -ForegroundColor Yellow
& "venv\Scripts\python.exe" -m playwright install chromium
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Playwright Chromium installed" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Failed to install Playwright browser" -ForegroundColor Yellow
    Write-Host "  You can install it manually later with: playwright install chromium" -ForegroundColor Yellow
}

# Create .env file
Write-Host ""
Write-Host "[5/5] Configuring..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "[WARNING] .env file already exists, skipping creation" -ForegroundColor Yellow
    Write-Host "  Edit .env manually if needed" -ForegroundColor Yellow
} else {
    # Check if .env.example exists
    if (-not (Test-Path ".env.example")) {
        Write-Host "[ERROR] .env.example not found!" -ForegroundColor Red
        Write-Host "  Cannot create .env file without template" -ForegroundColor Red
        exit 1
    }

    # Copy .env.example to .env
    Copy-Item ".env.example" ".env"

    # Generate SECRET_KEY and replace in .env
    try {
        $secretKey = & "venv\Scripts\python.exe" -c "import secrets; print(secrets.token_hex(32))" 2>$null
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
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[OK] Installation completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env file with your credentials and settings" -ForegroundColor White
Write-Host "2. Run launcher: .\start.ps1 or start.bat" -ForegroundColor White
Write-Host "   OR activate venv and run manually: venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Yellow
Write-Host "  .\start.ps1                    - Start web interface" -ForegroundColor White
Write-Host "  python run_scraper.py          - Scrape apps" -ForegroundColor White
Write-Host "  python run_version_scraper.py  - Scrape versions" -ForegroundColor White
Write-Host "  python run_downloader.py       - Download binaries" -ForegroundColor White
Write-Host ""
