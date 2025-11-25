# 🎨 GOG Database Auto-Update Script

## How to Use

### **Option 1: Double-Click (Easiest)**
Simply double-click `update-gogs.bat` in the project folder. A window will open and automatically:
1. Sync all GOG images from `gogs/` to `docs/gogs/`
2. Generate the GOGS array for the website
3. Update `docs/index.html` with new GOGs
4. Commit and push changes to GitHub
5. Show you the results

### **Option 2: PowerShell (Advanced)**
If you prefer using PowerShell directly:
```powershell
cd path/to/Gog-Database
./update-gogs.ps1
```

#### Skip Git Commit (just sync files)
```powershell
./update-gogs.ps1 -NoGit
```

## What It Does

1. **Copies GOG Files** - Syncs all images from `gogs/` → `docs/gogs/`
2. **Generates GOGS Array** - Creates JavaScript array from your GOG filenames
3. **Updates HTML** - Modifies `docs/index.html` with the new array
4. **Git Operations** - Commits and pushes to GitHub Pages
5. **Shows Summary** - Displays how many GOGs were processed

## Workflow

1. Add new GOG images to the `gogs/` folder
2. Double-click `update-gogs.bat`
3. Wait for it to complete
4. Your website will auto-update in ~30-60 seconds!

## Naming Tips

- Use clear, descriptive names for GOGs (e.g., `cute-gog.png`, `angry-gog.png`)
- Spaces in filenames work fine! (e.g., `my cool gog.png`)
- Supported formats: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`

## Troubleshooting

**Script won't run?**
- Windows might block PowerShell scripts. If prompted, click "More info" → "Run anyway"
- Or right-click update-gogs.bat → "Run as administrator"

**Git error?**
- Make sure you have Git installed: `git --version` in Command Prompt
- Ensure you're in the correct folder with the `.git` directory
- Or use `-NoGit` flag to just update files without Git

**Need to test without pushing?**
```powershell
./update-gogs.ps1 -NoGit
```

Then you can manually review the changes and commit when ready!

---

**Questions?** Check the script comments for more details!
