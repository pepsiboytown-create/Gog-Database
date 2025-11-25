# GOG Database Auto-Update Script
# Double-click update-gogs.bat to run this automatically

param([switch]$NoGit)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host ""
Write-Host "===== GOG Database Auto-Update =====" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy GOGs
Write-Host "Step 1: Syncing GOG files..." -ForegroundColor Yellow
try {
    Copy-Item "gogs/*" "docs/gogs/" -Force -ErrorAction Stop
    $gogCount = (Get-ChildItem "gogs/" | Measure-Object).Count
    Write-Host "Success: Copied $gogCount GOG files" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Generate GOGS array
Write-Host "Step 2: Generating GOGS array..." -ForegroundColor Yellow
try {
    $gogFiles = Get-ChildItem "gogs/" -File | Sort-Object Name
    $gogArray = @()
    
    foreach ($file in $gogFiles) {
        $name = $file.BaseName
        # Use double quotes to properly handle apostrophes
        $name = $name -replace '"', '\"'
        $entry = "            { name: `"$name`", url: `"./gogs/$($file.Name)`" }"
        $gogArray += $entry
    }
    
    $gogArrayString = $gogArray -join ",`n"
    Write-Host "Success: Generated array for $($gogFiles.Count) GOGs" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Update HTML
Write-Host "Step 3: Updating index.html..." -ForegroundColor Yellow
try {
    $htmlPath = "docs/index.html"
    $htmlContent = Get-Content $htmlPath -Raw
    $pattern = "const GOGS = \[[\s\S]*?\];"
    $replacement = "const GOGS = [`n$gogArrayString`n        ];"
    $newContent = $htmlContent -replace $pattern, $replacement
    
    if ($newContent -ne $htmlContent) {
        Set-Content $htmlPath -Value $newContent -Encoding UTF8
        Write-Host "Success: Updated index.html" -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not find GOGS array in HTML" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Git commit
if (-not $NoGit) {
    Write-Host "Step 4: Committing to Git..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        & git add docs/gogs/ docs/index.html 2>&1 | Out-Null
        & git commit -m "Auto-update: $($gogFiles.Count) GOGs [$timestamp]" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
        Write-Host "Success: Pushed to GitHub" -ForegroundColor Green
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Skipped: Git operations (NoGit flag used)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "===== Complete! =====" -ForegroundColor Cyan
Write-Host "Total GOGs: $($gogFiles.Count)" -ForegroundColor Cyan
Write-Host "URL: https://pepsiboytown-create.github.io/Gog-Database/" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Enter to close..."
Read-Host
