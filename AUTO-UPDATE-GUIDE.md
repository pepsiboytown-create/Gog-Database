# 🚀 Auto-Update Script Complete!

## What You Now Have

I've created an **automatic update script** that syncs your GOGs to the website with one click!

### **Files Added:**
1. **`update-gogs.bat`** ← **DOUBLE-CLICK THIS!** (Windows batch wrapper)
2. **`update-gogs.ps1`** (PowerShell script - runs the actual update)
3. **`UPDATE-GOGS-README.md`** (Detailed instructions)

---

## How to Use (Super Simple!)

### **Option 1: Double-Click (EASIEST)**
1. Add new GOG images to the `gogs/` folder
2. **Double-click `update-gogs.bat`** in the project folder
3. A window opens and automatically:
   - Copies GOGs from `gogs/` → `docs/gogs/`
   - Updates the website HTML
   - Commits and pushes to GitHub
   - Shows you the results

That's it! Your GOGs are live in ~30-60 seconds ⚡

### **Option 2: PowerShell (if you prefer)**
```powershell
cd path/to/Gog-Database
./update-gogs.ps1
```

### **Option 3: Test without Git Push**
```powershell
./update-gogs.ps1 -NoGit
```

---

## What the Script Does

1. **Syncs Files** - Copies all GOGs from `gogs/` to `docs/gogs/`
2. **Updates HTML** - Automatically updates the GOGS array in `docs/index.html`
3. **Git Commit** - Commits the changes with a timestamp
4. **Pushes to GitHub** - Deploys to Pages (auto-updates in 30-60 sec)
5. **Shows Summary** - Tells you how many GOGs were processed

---

## Your Current GOGs (15 Total!)

✅ bunnygog.png
✅ deditated gog.png
✅ dont smoke.png
✅ elvis gogley.png
✅ emo gog.png
✅ fnogs.png
✅ gog mold.png
✅ gogbytt.png
✅ goggle helios.png
✅ huh gog.png
✅ mushroom gog.png
✅ shadowgog.png
✅ thirsty gog.png
✅ war gogger.png
✅ warhammer 39999.png

---

## Workflow from Now On

**When you create new GOGs:**

```
1. Draw a GOG ✏️
2. Save it to gogs/ folder 📁
3. Double-click update-gogs.bat ⚡
4. Watch it auto-update! 🚀
```

That's literally it. No more manual copying or editing!

---

## Troubleshooting

**"Script won't run"**
- Windows might block it. If prompted, click "More info" → "Run anyway"
- Or right-click the .bat file → "Run as administrator"

**"Git error"**
- Make sure you have Git installed
- Use the `-NoGit` flag to just update files locally first
- Then you can commit manually later

**"Want to verify changes first?"**
```powershell
./update-gogs.ps1 -NoGit
```
Review the changes, then use Git commands manually

---

## File Locations

```
Gog-Database/
├── gogs/                    ← Add your GOG images here
├── docs/gogs/               ← Auto-synced (don't edit)
├── docs/index.html          ← Auto-updated (don't edit the GOGS array)
├── update-gogs.bat          ← DOUBLE-CLICK THIS!
├── update-gogs.ps1          ← PowerShell script (runs from .bat)
└── UPDATE-GOGS-README.md    ← This file
```

---

## Pro Tips

- **Naming Convention**: Use clear names like `cute-gog.png`, `angry-gog.png`
- **Spaces Work**: Filenames like `my cool gog.png` work fine
- **File Formats**: PNG, JPG, GIF, SVG all supported
- **Batch Operations**: Add 5 new GOGs, run script once - all upload together!
- **Speed**: Script runs in ~5-10 seconds, Pages updates in 30-60 seconds

---

Happy GOG creating! 🎨✨
