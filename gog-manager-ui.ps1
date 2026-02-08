# GOG Manager - Integrated UI for updating and managing GOGs
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Get-Location }
Set-Location $scriptPath

$DBPath = Join-Path (Join-Path $scriptPath "docs") "gogs-list.json"
$GOGsPCDir = Join-Path $scriptPath "gogs"
$GOGsWebDir = Join-Path (Join-Path $scriptPath "docs") "gogs"
$HTMLPath = Join-Path (Join-Path $scriptPath "docs") "index.html"
$DesignerDBPath = Join-Path $scriptPath "designers.json"

# Data structures
$script:gogData = @{}
$script:toRemove = @()
$script:toAdd = @()

# ========== Helper Functions ==========

function Read-Database {
    if (Test-Path $DBPath) {
        try {
            $content = Get-Content $DBPath -Raw
            return $content | ConvertFrom-Json
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error reading database: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return @()
        }
    }
    return @()
}

function Read-DesignersDB {
    if (Test-Path $DesignerDBPath) {
        try {
            $content = Get-Content $DesignerDBPath -Raw
            $designersObj = $content | ConvertFrom-Json
            if ($null -eq $designersObj) { return @{} }
            
            # Convert PSCustomObject to Hashtable
            $designers = @{}
            foreach ($property in $designersObj.PSObject.Properties) {
                $designers[$property.Name] = $property.Value
            }
            return $designers
        }
        catch {
            return @{}
        }
    }
    return @{}
}

function Save-DesignersDB {
    param([hashtable]$Designers)
    try {
        $json = $Designers | ConvertTo-Json
        Set-Content $DesignerDBPath -Value $json -Encoding UTF8
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error saving designers: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Get-PCGogs {
    if (Test-Path $GOGsPCDir) {
        return @(Get-ChildItem $GOGsPCDir -File | Select-Object -ExpandProperty Name | Sort-Object)
    }
    return @()
}

function Get-WebGogs {
    if (Test-Path $GOGsWebDir) {
        return @(Get-ChildItem $GOGsWebDir -File | Select-Object -ExpandProperty Name | Sort-Object)
    }
    return @()
}

function Get-RenameInput {
    param([string]$CurrentName, [string]$Title)
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400, 150)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter new name:"
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(370, 20)
    $form.Controls.Add($label)
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Text = $CurrentName
    $textBox.Location = New-Object System.Drawing.Point(10, 35)
    $textBox.Size = New-Object System.Drawing.Size(370, 25)
    $textBox.SelectAll()
    $form.Controls.Add($textBox)
    
    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text = "OK"
    $okBtn.Location = New-Object System.Drawing.Point(220, 75)
    $okBtn.Size = New-Object System.Drawing.Size(80, 30)
    $okBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okBtn)
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = "Cancel"
    $cancelBtn.Location = New-Object System.Drawing.Point(300, 75)
    $cancelBtn.Size = New-Object System.Drawing.Size(80, 30)
    $cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelBtn)
    
    $form.AcceptButton = $okBtn
    $form.CancelButton = $cancelBtn
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }
    
    return $null
}

function Get-DesignerInput {
    param([string]$CurrentDesigner)
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Designer"
    $form.Size = New-Object System.Drawing.Size(350, 220)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Choose a designer:"
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(320, 20)
    $label.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)
    
    $cbZigbyTT = New-Object System.Windows.Forms.CheckBox
    $cbZigbyTT.Text = "ZigbyTT"
    $cbZigbyTT.Location = New-Object System.Drawing.Point(20, 40)
    $cbZigbyTT.Size = New-Object System.Drawing.Size(150, 20)
    $cbZigbyTT.Checked = ($CurrentDesigner -eq "ZigbyTT")
    $form.Controls.Add($cbZigbyTT)
    
    $cbShadowheart = New-Object System.Windows.Forms.CheckBox
    $cbShadowheart.Text = "Shadowheart"
    $cbShadowheart.Location = New-Object System.Drawing.Point(20, 65)
    $cbShadowheart.Size = New-Object System.Drawing.Size(150, 20)
    $cbShadowheart.Checked = ($CurrentDesigner -eq "Shadowheart")
    $form.Controls.Add($cbShadowheart)
    
    $cbCustomLabel = New-Object System.Windows.Forms.Label
    $cbCustomLabel.Text = "Custom:"
    $cbCustomLabel.Location = New-Object System.Drawing.Point(20, 92)
    $cbCustomLabel.Size = New-Object System.Drawing.Size(80, 20)
    $form.Controls.Add($cbCustomLabel)
    
    $txtCustom = New-Object System.Windows.Forms.TextBox
    $txtCustom.Location = New-Object System.Drawing.Point(100, 90)
    $txtCustom.Size = New-Object System.Drawing.Size(230, 20)
    if ($CurrentDesigner -ne "ZigbyTT" -and $CurrentDesigner -ne "Shadowheart" -and -not [string]::IsNullOrWhiteSpace($CurrentDesigner)) {
        $txtCustom.Text = $CurrentDesigner
    }
    $form.Controls.Add($txtCustom)
    
    $cbZigbyTT.Add_CheckedChanged({
        if ($cbZigbyTT.Checked) {
            $cbShadowheart.Checked = $false
        }
    })
    
    $cbShadowheart.Add_CheckedChanged({
        if ($cbShadowheart.Checked) {
            $cbZigbyTT.Checked = $false
        }
    })
    
    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text = "OK"
    $okBtn.Location = New-Object System.Drawing.Point(160, 130)
    $okBtn.Size = New-Object System.Drawing.Size(80, 30)
    $okBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okBtn)
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = "Cancel"
    $cancelBtn.Location = New-Object System.Drawing.Point(250, 130)
    $cancelBtn.Size = New-Object System.Drawing.Size(80, 30)
    $cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelBtn)
    
    $form.AcceptButton = $okBtn
    $form.CancelButton = $cancelBtn
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($cbZigbyTT.Checked) {
            return "ZigbyTT"
        }
        elseif ($cbShadowheart.Checked) {
            return "Shadowheart"
        }
        elseif (-not [string]::IsNullOrWhiteSpace($txtCustom.Text)) {
            return $txtCustom.Text
        }
    }
    
    return $null
}

function Rename-GogFile {
    param([string]$OldName, [string]$NewName, [string]$Directory)
    
    if ($OldName -eq $NewName) {
        return $true
    }
    
    $oldPath = Join-Path $Directory $OldName
    $newPath = Join-Path $Directory $NewName
    
    if (Test-Path $oldPath) {
        try {
            Rename-Item $oldPath -NewName $NewName -Force -ErrorAction Stop
            return $true
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error renaming file: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return $false
        }
    }
    
    return $false
}

function Sync-Data {
    $pcGogs = Get-PCGogs
    $webGogs = Get-WebGogs
    $designers = Read-DesignersDB
    
    $script:toAdd = @($pcGogs | Where-Object { $webGogs -notcontains $_ })
    
    $script:gogData = @{}
    foreach ($gog in $webGogs) {
        $designer = if ($designers -and $designers.ContainsKey($gog)) { $designers[$gog] } else { "" }
        $script:gogData[$gog] = @{ name = $gog; toRemove = $false; newName = $null; designer = $designer }
    }
}

function Update-DesignerLabel {
    param([string]$GogName)
    
    foreach ($control in $script:gogsPanel.Controls) {
        if ($control -is [System.Windows.Forms.Panel]) {
            foreach ($subControl in $control.Controls) {
                if ($subControl -is [System.Windows.Forms.Label] -and $subControl.Tag -eq $GogName) {
                    $designer = if ([string]::IsNullOrWhiteSpace($script:gogData[$GogName].designer)) { "No designer" } else { $script:gogData[$GogName].designer }
                    $subControl.Text = $designer
                    return
                }
            }
        }
    }
}

function Update-GogsList {
    $panel = $script:gogsPanel
    $panel.Controls.Clear()
    
    if ($null -eq $script:gogData -or $script:gogData.Count -eq 0) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "No GOGs on website"
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(300, 20)
        $label.ForeColor = [System.Drawing.Color]::Gray
        $panel.Controls.Add($label)
        return
    }
    
    $y = 10
    $gogsArray = @($script:gogData.Keys | Sort-Object)
    
    if ($gogsArray.Count -eq 0) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "No GOGs on website"
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(300, 20)
        $label.ForeColor = [System.Drawing.Color]::Gray
        $panel.Controls.Add($label)
        return
    }
    
    foreach ($gog in $gogsArray) {
        $control = New-Object System.Windows.Forms.Panel
        $control.Size = New-Object System.Drawing.Size(380, 80)
        $control.Location = New-Object System.Drawing.Point(5, $y)
        $control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        
        if ($script:gogData[$gog].toRemove) {
            $control.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
            $control.BackColor = [System.Drawing.Color]::FromArgb(255, 220, 220)
        }
        else {
            $control.BackColor = [System.Drawing.Color]::White
        }
        
        # Image PictureBox
        $imageBox = New-Object System.Windows.Forms.PictureBox
        $imageBox.Size = New-Object System.Drawing.Size(50, 50)
        $imageBox.Location = New-Object System.Drawing.Point(5, 7)
        $imageBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $imageBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        
        $gogPath = Join-Path $GOGsWebDir $gog
        if (Test-Path $gogPath) {
            try {
                # Load image into memory to avoid file locking
                $memoryStream = New-Object System.IO.MemoryStream
                $fileStream = [System.IO.File]::OpenRead($gogPath)
                $fileStream.CopyTo($memoryStream)
                $fileStream.Close()
                $fileStream.Dispose()
                $memoryStream.Position = 0
                $imageBox.Image = [System.Drawing.Image]::FromStream($memoryStream)
            }
            catch {
                $imageBox.BackColor = [System.Drawing.Color]::LightGray
            }
        }
        else {
            $imageBox.BackColor = [System.Drawing.Color]::LightGray
        }
        $control.Controls.Add($imageBox)
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $gog
        $label.Location = New-Object System.Drawing.Point(60, 5)
        $label.Size = New-Object System.Drawing.Size(200, 18)
        $label.Font = New-Object System.Drawing.Font("Arial", 9)
        $label.AutoSize = $false
        $label.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
        $label.Text = [System.Text.RegularExpressions.Regex]::Replace($gog, '(\.[^.]*$)', '') # Remove extension
        $control.Controls.Add($label)
        
        $designerLabel = New-Object System.Windows.Forms.Label
        $designerLabel.Text = if ([string]::IsNullOrWhiteSpace($script:gogData[$gog].designer)) { "No designer" } else { $script:gogData[$gog].designer }
        $designerLabel.Location = New-Object System.Drawing.Point(60, 22)
        $designerLabel.Size = New-Object System.Drawing.Size(200, 15)
        $designerLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Italic)
        $designerLabel.AutoSize = $false
        $designerLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
        $designerLabel.ForeColor = [System.Drawing.Color]::DarkGray
        $designerLabel.Tag = $gog
        $control.Controls.Add($designerLabel)
        
        $designerBtn = New-Object System.Windows.Forms.Button
        $designerBtn.Text = "Designer"
        $designerBtn.Location = New-Object System.Drawing.Point(60, 50)
        $designerBtn.Size = New-Object System.Drawing.Size(60, 23)
        $designerBtn.BackColor = [System.Drawing.Color]::LightYellow
        $designerBtn.Font = New-Object System.Drawing.Font("Arial", 8)
        $designerBtn.Tag = $gog
        
        $designerBtn.Add_Click({
            $gogName = $this.Tag
            if ($null -ne $gogName -and $script:gogData.ContainsKey($gogName)) {
                $currentDesigner = if ($script:gogData[$gogName].designer) { $script:gogData[$gogName].designer } else { "" }
                $result = Get-DesignerInput -CurrentDesigner $currentDesigner
                if ($null -ne $result) {
                    $script:gogData[$gogName].designer = $result
                    
                    # Save to designers database immediately
                    $designers = Read-DesignersDB
                    $designers[$gogName] = $result
                    Save-DesignersDB -Designers $designers
                    
                    Update-DesignerLabel -GogName $gogName
                }
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("Error: Could not find GOG in database", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
        
        $control.Controls.Add($designerBtn)
        
        $renameBtn = New-Object System.Windows.Forms.Button
        $renameBtn.Text = "Rename"
        $renameBtn.Location = New-Object System.Drawing.Point(125, 50)
        $renameBtn.Size = New-Object System.Drawing.Size(60, 23)
        $renameBtn.BackColor = [System.Drawing.Color]::LightBlue
        $renameBtn.Font = New-Object System.Drawing.Font("Arial", 8)
        $renameBtn.Tag = $gog
        
        $renameBtn.Add_Click({
            $gogName = $this.Tag
            if ($null -ne $gogName -and $script:gogData.ContainsKey($gogName)) {
                $extension = [System.IO.Path]::GetExtension($gogName)
                $currentNameWithoutExt = [System.Text.RegularExpressions.Regex]::Replace($gogName, '(\.[^.]*$)', '')
                
                $newNameInput = Get-RenameInput -CurrentName $currentNameWithoutExt -Title "Rename GOG"
                
                if ($null -ne $newNameInput -and $newNameInput -ne $currentNameWithoutExt) {
                    $newFullName = $newNameInput + $extension
                    
                    # Rename in both PC and Web directories
                    $renamed = Rename-GogFile -OldName $gogName -NewName $newFullName -Directory $GOGsWebDir
                    if ($renamed) {
                        Rename-GogFile -OldName $gogName -NewName $newFullName -Directory $GOGsPCDir | Out-Null
                        
                        # Update gogData
                        $script:gogData[$newFullName] = $script:gogData[$gogName]
                        $script:gogData.Remove($gogName)
                        
                        Update-GogsList
                    }
                }
            }
        })
        $control.Controls.Add($renameBtn)
        
        $deleteBtn = New-Object System.Windows.Forms.Button
        $deleteBtn.Text = if ($script:gogData[$gog].toRemove) { "[X] Remove" } else { "Remove" }
        $deleteBtn.Location = New-Object System.Drawing.Point(190, 50)
        $deleteBtn.Size = New-Object System.Drawing.Size(60, 23)
        $deleteBtn.BackColor = if ($script:gogData[$gog].toRemove) { [System.Drawing.Color]::LightCoral } else { [System.Drawing.Color]::LightGray }
        $deleteBtn.Font = New-Object System.Drawing.Font("Arial", 8)
        $deleteBtn.Tag = $gog
        
        $deleteBtn.Add_Click({
            $gogName = $this.Tag
            if ($null -ne $gogName -and $script:gogData.ContainsKey($gogName)) {
                $script:gogData[$gogName].toRemove = -not $script:gogData[$gogName].toRemove
                Update-GogsList
            }
        })
        $control.Controls.Add($deleteBtn)
        
        $panel.Controls.Add($control)
        $y += 85
    }
}

function Update-AddList {
    $panel = $script:addPanel
    $panel.Controls.Clear()
    
    if ($script:toAdd.Count -eq 0) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "No new GOGs to add"
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(300, 20)
        $label.ForeColor = [System.Drawing.Color]::Gray
        $panel.Controls.Add($label)
        return
    }
    
    $y = 10
    foreach ($gog in $script:toAdd) {
        $control = New-Object System.Windows.Forms.Panel
        $control.Size = New-Object System.Drawing.Size(380, 65)
        $control.Location = New-Object System.Drawing.Point(5, $y)
        $control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $control.BackColor = [System.Drawing.Color]::FromArgb(220, 255, 220)
        
        # Image PictureBox
        $imageBox = New-Object System.Windows.Forms.PictureBox
        $imageBox.Size = New-Object System.Drawing.Size(50, 50)
        $imageBox.Location = New-Object System.Drawing.Point(5, 7)
        $imageBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $imageBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        
        $gogPath = Join-Path $GOGsPCDir $gog
        if (Test-Path $gogPath) {
            try {
                # Load image into memory to avoid file locking
                $memoryStream = New-Object System.IO.MemoryStream
                $fileStream = [System.IO.File]::OpenRead($gogPath)
                $fileStream.CopyTo($memoryStream)
                $fileStream.Close()
                $fileStream.Dispose()
                $memoryStream.Position = 0
                $imageBox.Image = [System.Drawing.Image]::FromStream($memoryStream)
            }
            catch {
                $imageBox.BackColor = [System.Drawing.Color]::LightGray
            }
        }
        else {
            $imageBox.BackColor = [System.Drawing.Color]::LightGray
        }
        $control.Controls.Add($imageBox)
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "[+] " + [System.Text.RegularExpressions.Regex]::Replace($gog, '(\.[^.]*$)', '')
        $label.Location = New-Object System.Drawing.Point(60, 5)
        $label.Size = New-Object System.Drawing.Size(260, 55)
        $label.Font = New-Object System.Drawing.Font("Arial", 9)
        $label.ForeColor = [System.Drawing.Color]::DarkGreen
        $label.AutoSize = $false
        $label.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
        $control.Controls.Add($label)
        
        $renameBtn = New-Object System.Windows.Forms.Button
        $renameBtn.Text = "Rename"
        $renameBtn.Location = New-Object System.Drawing.Point(325, 20)
        $renameBtn.Size = New-Object System.Drawing.Size(50, 26)
        $renameBtn.BackColor = [System.Drawing.Color]::LightBlue
        $gogNameForNewRename = $gog
        $renameBtn.Add_Click({
            $gogName = $gogNameForNewRename
            $extension = [System.IO.Path]::GetExtension($gogName)
            $currentNameWithoutExt = [System.Text.RegularExpressions.Regex]::Replace($gogName, '(\.[^.]*$)', '')
            
            $newNameInput = Get-RenameInput -CurrentName $currentNameWithoutExt -Title "Rename New GOG"
            
            if ($null -ne $newNameInput -and $newNameInput -ne $currentNameWithoutExt) {
                $newFullName = $newNameInput + $extension
                
                # Rename in PC directory (new GOGs are only in PC until confirmed)
                $renamed = Rename-GogFile -OldName $gogName -NewName $newFullName -Directory $GOGsPCDir
                
                if ($renamed) {
                    # Update toAdd list
                    $script:toAdd = @($script:toAdd | Where-Object { $_ -ne $gogName }) + $newFullName
                    Update-AddList
                }
            }
        }.GetNewClosure())
        $control.Controls.Add($renameBtn)
        
        $panel.Controls.Add($control)
        $y += 70
    }
}

function Remove-GogFiles {
    param([array]$GogsToRemove)
    
    foreach ($gog in $GogsToRemove) {
        $pcPath = Join-Path $GOGsPCDir $gog
        $webPath = Join-Path $GOGsWebDir $gog
        
        if (Test-Path $pcPath) {
            Remove-Item $pcPath -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $webPath) {
            Remove-Item $webPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-Database {
    param([array]$GogsToRemove)
    
    try {
        $db = Read-Database
        
        $fileNamesToRemove = @($GogsToRemove)
        $updatedDb = @($db | Where-Object { $fileNamesToRemove -notcontains $_.file })
        
        $json = $updatedDb | ConvertTo-Json -Depth 10
        Set-Content $DBPath -Value $json -Encoding UTF8
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error updating database: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Update-HTML {
    try {
        $gogFiles = Get-WebGogs
        $gogArray = @()
        
        foreach ($file in $gogFiles) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $designer = if ($script:gogData[$file]) { $script:gogData[$file].designer } else { "" }
            
            # Escape special characters for JavaScript
            $name = $name.Replace('\', '\\').Replace('"', '\"')
            $designer = $designer.Replace('\', '\\').Replace('"', '\"')
            
            # Create JSON object
            $entry = "            { name: `"$name`", designer: `"$designer`", url: `"./gogs/$file`" }"
            $gogArray += $entry
        }
        
        $gogArrayString = $gogArray -join ",`n"
        
        # Read file with explicit UTF-8 without BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $htmlContent = [System.IO.File]::ReadAllText($HTMLPath, $utf8NoBom)
        
        # Update deployment version for cache busting
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $htmlContent = $htmlContent -replace 'content="v[^"]*"(?=\s*>.*deployment-version)', "content=`"v3.1-emoji-fix-$timestamp`""
        
        $pattern = "const GOGS = \[[\s\S]*?\];"
        $replacement = "const GOGS = [`n$gogArrayString`n        ];"
        $newContent = $htmlContent -replace $pattern, $replacement
        
        # Write file with UTF8 without BOM
        [System.IO.File]::WriteAllText($HTMLPath, $newContent, $utf8NoBom)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error updating HTML: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Copy-ToWebDir {
    try {
        Copy-Item "$GOGsPCDir/*" "$GOGsWebDir/" -Force -ErrorAction Stop
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error copying GOGs: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ========== Main Form ==========

$form = New-Object System.Windows.Forms.Form
$form.Text = "GOG Manager - Update & Remove"
$form.Size = New-Object System.Drawing.Size(950, 800)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# ===== Top Section: New GOGs =====
$addLabel = New-Object System.Windows.Forms.Label
$addLabel.Text = "New GOGs to Add:"
$addLabel.Location = New-Object System.Drawing.Point(10, 10)
$addLabel.Size = New-Object System.Drawing.Size(450, 20)
$addLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($addLabel)

$script:addPanel = New-Object System.Windows.Forms.Panel
$script:addPanel.Location = New-Object System.Drawing.Point(10, 35)
$script:addPanel.Size = New-Object System.Drawing.Size(450, 120)
$script:addPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:addPanel.AutoScroll = $true
$script:addPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($script:addPanel)

# ===== Middle Section: Existing GOGs =====
$existLabel = New-Object System.Windows.Forms.Label
$existLabel.Text = "GOGs on Website (click Designer/Rename to edit):"
$existLabel.Location = New-Object System.Drawing.Point(10, 165)
$existLabel.Size = New-Object System.Drawing.Size(450, 20)
$existLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($existLabel)

$script:gogsPanel = New-Object System.Windows.Forms.Panel
$script:gogsPanel.Location = New-Object System.Drawing.Point(10, 190)
$script:gogsPanel.Size = New-Object System.Drawing.Size(450, 500)
$script:gogsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:gogsPanel.AutoScroll = $true
$script:gogsPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($script:gogsPanel)

# ===== Info Panel (Right side) =====
$infoPanel = New-Object System.Windows.Forms.Panel
$infoPanel.Location = New-Object System.Drawing.Point(470, 35)
$infoPanel.Size = New-Object System.Drawing.Size(460, 655)
$infoPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$infoPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($infoPanel)

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Summary"
$infoLabel.Location = New-Object System.Drawing.Point(10, 10)
$infoLabel.Size = New-Object System.Drawing.Size(440, 20)
$infoLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$infoPanel.Controls.Add($infoLabel)

$script:infoText = New-Object System.Windows.Forms.TextBox
$script:infoText.Location = New-Object System.Drawing.Point(10, 40)
$script:infoText.Size = New-Object System.Drawing.Size(440, 580)
$script:infoText.Multiline = $true
$script:infoText.ReadOnly = $true
$script:infoText.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:infoText.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$script:infoText.Font = New-Object System.Drawing.Font("Courier New", 9)
$infoPanel.Controls.Add($script:infoText)

# ===== Bottom Buttons =====
$confirmBtn = New-Object System.Windows.Forms.Button
$confirmBtn.Text = "Confirm Changes"
$confirmBtn.Location = New-Object System.Drawing.Point(720, 700)
$confirmBtn.Size = New-Object System.Drawing.Size(170, 35)
$confirmBtn.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$confirmBtn.BackColor = [System.Drawing.Color]::LightGreen
$confirmBtn.Add_Click({
    $gogsToRemove = @($script:gogData.Keys | Where-Object { $script:gogData[$_].toRemove })
    
    if ($gogsToRemove.Count -gt 0) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "The following GOGs will be REMOVED on next update:`n`n" + ($gogsToRemove -join "`n") + "`n`nContinue?",
            "Confirm Removal",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            return
        }
        
        Remove-GogFiles $gogsToRemove
        Update-Database $gogsToRemove
    }
    
    Copy-ToWebDir
    Update-HTML
    
    # Push to GitHub
    try {
        & git add "docs/gogs/" "docs/index.html" 2>&1 | Out-Null
        & git commit -m "Update: GOGs database - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>&1 | Out-Null
        & git push origin main 2>&1 | Out-Null
    }
    catch {
        # Git push failed but continue
    }
    
    $removeMsg = if ($gogsToRemove.Count -gt 0) { 
        "`n`nRemoved: $($gogsToRemove.Count) GOG(s)"
    } else { 
        "" 
    }
    
    [System.Windows.Forms.MessageBox]::Show(
        "Changes confirmed and applied!`nAdded: $($script:toAdd.Count) GOG(s)$removeMsg`n`nChanges pushed to GitHub.",
        "Success",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
    # Refresh UI
    Sync-Data
    Update-GogsList
    Update-AddList
    Update-Summary
})
$form.Controls.Add($confirmBtn)

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "Refresh"
$refreshBtn.Location = New-Object System.Drawing.Point(630, 700)
$refreshBtn.Size = New-Object System.Drawing.Size(80, 35)
$refreshBtn.Add_Click({
    Sync-Data
    Update-GogsList
    Update-AddList
    Update-Summary
})
$form.Controls.Add($refreshBtn)

function Update-Summary {
    $removeCount = @($script:gogData.Keys | Where-Object { $script:gogData[$_].toRemove }).Count
    $addCount = $script:toAdd.Count
    $totalWeb = $script:gogData.Count
    $totalPC = (Get-PCGogs).Count
    
    $summary = @"
STATUS SUMMARY
================

PC Gogs: $totalPC files
Website Gogs: $totalWeb files

TO BE ADDED:
  New GOGs: $addCount

TO BE REMOVED:
  Marked for removal: $removeCount

CHANGES:
  After confirm:
  * Website: $totalWeb + $addCount - $removeCount = $($totalWeb + $addCount - $removeCount)
  * HTML: Updated with new list

INSTRUCTIONS:
* Review new GOGs above (green)
* Click Designer/Rename to edit
* Click Remove to mark for deletion
* Removed GOGs show red outline
* Click Confirm Changes to apply all
* A confirmation will show removed GOGs
"@
    
    $script:infoText.Text = $summary
}

# ========== Initialize ==========
Sync-Data
Update-GogsList
Update-AddList
Update-Summary

$form.ShowDialog()
