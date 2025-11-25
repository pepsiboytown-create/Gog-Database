# GOG Database Auto-Update & Validation Script
# Double-click the .bat file to run this script

param([switch]$NoGit)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host ""
Write-Host "===== GOG Database Auto-Update & Validation =====" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy GOGs
Write-Host "Step 1: Syncing GOG files..." -ForegroundColor Yellow
try {
    Copy-Item "gogs/*" "docs/gogs/" -Force -ErrorAction Stop
    $gogCount = (Get-ChildItem "gogs/" | Measure-Object).Count
    Write-Host "✓ Copied $gogCount GOG files" -ForegroundColor Green
} catch {
    Write-Host "✗ Error copying GOGs: $_" -ForegroundColor Red
    Write-Host "Press Enter to close..."
    Read-Host
    exit 1
}

# Step 2: Generate GOGS array with proper escaping (double quotes)
Write-Host "Step 2: Generating GOGS array..." -ForegroundColor Yellow
try {
    $gogFiles = Get-ChildItem "gogs/" -File | Sort-Object Name
    $gogArray = @()
    
    foreach ($file in $gogFiles) {
        $name = $file.BaseName
        # Use double quotes and escape any internal quotes
        $name = $name -replace '"', '\"'
        $entry = "            { name: `"$name`", url: `"./gogs/$($file.Name)`" }"
        $gogArray += $entry
    }
    
    $gogArrayString = $gogArray -join ",`n"
    Write-Host "✓ Generated array for $($gogFiles.Count) GOGs" -ForegroundColor Green
} catch {
    Write-Host "✗ Error generating array: $_" -ForegroundColor Red
    Write-Host "Press Enter to close..."
    Read-Host
    exit 1
}

# Step 3: Update HTML
Write-Host "Step 3: Updating index.html..." -ForegroundColor Yellow
try {
    $htmlPath = "docs/index.html"
    $htmlContent = Get-Content $htmlPath -Raw
    
    # Find and replace the GOGS array
    $pattern = "const GOGS = \[[\s\S]*?\];"
    $replacement = "const GOGS = [`n$gogArrayString`n        ];"
    $newContent = $htmlContent -replace $pattern, $replacement
    
    if ($newContent -ne $htmlContent) {
        Set-Content $htmlPath -Value $newContent -Encoding UTF8
        Write-Host "✓ Updated index.html" -ForegroundColor Green
    } else {
        Write-Host "✗ Could not find GOGS array in HTML" -ForegroundColor Red
        Write-Host "Press Enter to close..."
        Read-Host
        exit 1
    }
} catch {
    Write-Host "✗ Error updating HTML: $_" -ForegroundColor Red
    Write-Host "Press Enter to close..."
    Read-Host
    exit 1
}

# Step 4: Validate HTML syntax
Write-Host "Step 4: Validating HTML..." -ForegroundColor Yellow
try {
    $htmlContent = Get-Content $htmlPath -Raw
    
    # Check for common syntax errors
    $errors = @()
    
    # Check for balanced quotes in GOGS array
    $gogsMatch = $htmlContent | Select-String -Pattern "const GOGS = \[(.*?)\];" -AllMatches
    if ($gogsMatch.Matches) {
        $gogsContent = $gogsMatch.Matches[0].Groups[1].Value
        
        # Count quotes
        $doubleQuotes = ($gogsContent | Select-String '"' -AllMatches).Matches.Count
        if ($doubleQuotes % 2 -ne 0) {
            $errors += "Unbalanced double quotes in GOGS array"
        }
    }
    
    # Check for unclosed braces
    $openBraces = ($htmlContent | Select-String '\{' -AllMatches).Matches.Count
    $closeBraces = ($htmlContent | Select-String '\}' -AllMatches).Matches.Count
    if ($openBraces -ne $closeBraces) {
        $errors += "Unbalanced braces (open: $openBraces, close: $closeBraces)"
    }
    
    # Check for script tag closure
    if (($htmlContent | Select-String '</script>' -AllMatches).Matches.Count -lt 1) {
        $errors += "Missing closing </script> tag"
    }
    
    if ($errors.Count -gt 0) {
        Write-Host "✗ HTML validation errors found:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host "Press Enter to close..."
        Read-Host
        exit 1
    } else {
        Write-Host "✓ HTML validation passed" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Error validating HTML: $_" -ForegroundColor Red
    Write-Host "Press Enter to close..."
    Read-Host
    exit 1
}

# Step 5: Git commit and push
if (-not $NoGit) {
    Write-Host "Step 5: Committing to Git..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        & git add docs/gogs/ docs/index.html 2>&1 | Out-Null
        & git commit -m "Auto-update: $($gogFiles.Count) GOGs [$timestamp]" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
        Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
    } catch {
        Write-Host "✗ Git error (continuing anyway): $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⊘ Git operations skipped (NoGit flag)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "===== Update Complete! =====" -ForegroundColor Green
Write-Host "Total GOGs: $($gogFiles.Count)" -ForegroundColor Cyan
Write-Host "Local Preview: http://localhost:8000" -ForegroundColor Cyan
Write-Host "Live Site: https://pepsiboytown-create.github.io/Gog-Database/" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening site in browser..." -ForegroundColor Yellow

# Open the site
Start-Process "https://pepsiboytown-create.github.io/Gog-Database/"

Write-Host ""
Write-Host "Press Enter to close..."
Read-Host
