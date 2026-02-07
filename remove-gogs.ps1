# GOG Removal Tool
param(
    [switch]$Help
)

if ($Help) {
    Write-Host "GOG Removal Tool - Remove GOGs from your PC and website"
    Write-Host "Usage: .\remove-gogs.ps1"
    exit
}

$DBPath = Join-Path $PSScriptRoot "docs" "gogs-list.json"
$GOGsPCDir = Join-Path $PSScriptRoot "gogs"
$GOGsWebDir = Join-Path $PSScriptRoot "docs" "gogs"

function Read-Database {
    if (Test-Path $DBPath) {
        try {
            $content = Get-Content $DBPath -Raw
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Host "Error reading database: $_" -ForegroundColor Red
            return @()
        }
    }
    return @()
}

function Get-LocalGogs {
    if (Test-Path $GOGsPCDir) {
        try {
            return @(Get-ChildItem $GOGsPCDir -File | Select-Object -ExpandProperty Name | Sort-Object)
        }
        catch {
            Write-Host "Error reading local GOGs: $_" -ForegroundColor Red
            return @()
        }
    }
    return @()
}

function Show-GogList {
    param([array]$Gogs)
    
    for ($i = 0; $i -lt $Gogs.Count; $i++) {
        Write-Host "  $($i + 1). $($Gogs[$i])"
    }
}

function Get-Selection {
    param([array]$Gogs)
    
    Write-Host "`n========== GOG REMOVAL TOOL ==========" -ForegroundColor Cyan
    Write-Host "Select GOGs to remove (enter numbers, comma-separated, or 'all' for all):" -ForegroundColor Yellow
    Write-Host "Type 'cancel' to exit without deleting.`n"
    
    Show-GogList $Gogs
    
    while ($true) {
        $input = Read-Host "`nEnter selection"
        
        if ($input -eq 'cancel') {
            Write-Host "Cancelled. No GOGs were removed." -ForegroundColor Yellow
            return $null
        }
        
        if ($input -eq 'all') {
            return $Gogs
        }
        
        try {
            $indices = @($input -split ',' | ForEach-Object { [int]$_.Trim() - 1 })
            
            if ($indices | Where-Object { $_ -lt 0 -or $_ -ge $Gogs.Count }) {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                continue
            }
            
            $selected = @()
            foreach ($idx in $indices) {
                if ($idx -ge 0 -and $idx -lt $Gogs.Count) {
                    $selected += $Gogs[$idx]
                }
            }
            
            if ($selected.Count -gt 0) {
                return $selected
            }
            else {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Invalid input. Please enter numbers separated by commas." -ForegroundColor Red
        }
    }
}

function Show-Confirmation {
    param([array]$SelectedGogs)
    
    Write-Host "`n========== CONFIRMATION ==========" -ForegroundColor Cyan
    Write-Host "`nThe following $($SelectedGogs.Count) GOG(s) will be PERMANENTLY DELETED:`n" -ForegroundColor Red
    
    for ($i = 0; $i -lt $SelectedGogs.Count; $i++) {
        Write-Host "  $($i + 1). $($SelectedGogs[$i])"
    }
    
    $confirm = Read-Host "`nAre you SURE you want to delete these? (yes/no)"
    
    if ($confirm -ne 'yes') {
        Write-Host "Cancelled. No GOGs were removed." -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

function Remove-GogFiles {
    param([array]$SelectedGogs)
    
    Write-Host "`n========== DELETING ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $deletedCount = 0
    
    foreach ($gog in $SelectedGogs) {
        $pcPath = Join-Path $GOGsPCDir $gog
        $webPath = Join-Path $GOGsWebDir $gog
        
        $pcDeleted = $false
        $webDeleted = $false
        
        if (Test-Path $pcPath) {
            try {
                Remove-Item $pcPath -Force -ErrorAction Stop
                $pcDeleted = $true
            }
            catch {
                Write-Host "✗ Error deleting PC version: $gog" -ForegroundColor Red
            }
        }
        
        if (Test-Path $webPath) {
            try {
                Remove-Item $webPath -Force -ErrorAction Stop
                $webDeleted = $true
            }
            catch {
                Write-Host "✗ Error deleting web version: $gog" -ForegroundColor Red
            }
        }
        
        if ($pcDeleted -or $webDeleted) {
            $deletedCount++
            Write-Host "✓ Deleted: $gog" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Failed to delete: $gog" -ForegroundColor Red
        }
    }
    
    return $deletedCount
}

function Update-Database {
    param([array]$GogsToRemove)
    
    try {
        $db = Read-Database
        $initialCount = $db.Count
        
        # Filter out the GOGs to remove
        $fileNamesToRemove = @()
        foreach ($gog in $GogsToRemove) {
            $fileNamesToRemove += $gog
        }
        
        $updatedDb = @($db | Where-Object { $fileNamesToRemove -notcontains $_.file })
        
        $json = $updatedDb | ConvertTo-Json -Depth 10
        Set-Content $DBPath -Value $json -Encoding UTF8
        
        return $initialCount - $updatedDb.Count
    }
    catch {
        Write-Host "Error updating database: $_" -ForegroundColor Red
        return 0
    }
}

# Main execution
$allGogs = Get-LocalGogs

if ($allGogs.Count -eq 0) {
    Write-Host "No GOGs found in the gogs directory." -ForegroundColor Yellow
    exit
}

$selectedGogs = Get-Selection $allGogs

if ($null -eq $selectedGogs) {
    exit
}

if (-not (Show-Confirmation $selectedGogs)) {
    exit
}

$deletedCount = Remove-GogFiles $selectedGogs
$dbUpdated = Update-Database $selectedGogs

Write-Host "`n========== COMPLETE ==========" -ForegroundColor Cyan
Write-Host "✓ Deleted $deletedCount GOG file(s) from disk" -ForegroundColor Green
Write-Host "✓ Updated database (removed $dbUpdated entries)" -ForegroundColor Green
Write-Host "`nRemoval complete!" -ForegroundColor Green
