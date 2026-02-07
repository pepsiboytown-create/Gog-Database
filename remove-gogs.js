const fs = require('fs');
const path = require('path');
const readline = require('readline');

const DB_PATH = path.join(__dirname, 'docs', 'gogs-list.json');
const GOGS_PC_DIR = path.join(__dirname, 'gogs');
const GOGS_WEB_DIR = path.join(__dirname, 'docs', 'gogs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function readDatabase() {
  try {
    const data = fs.readFileSync(DB_PATH, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Error reading database:', err.message);
    return [];
  }
}

function getLocalGogs() {
  try {
    return fs.readdirSync(GOGS_PC_DIR).sort();
  } catch (err) {
    console.error('Error reading local GOGs:', err.message);
    return [];
  }
}

function question(query) {
  return new Promise((resolve) => {
    rl.question(query, resolve);
  });
}

async function selectGogs(gogs) {
  const selected = [];
  
  console.log('\n========== GOG REMOVAL TOOL ==========\n');
  console.log('Select GOGs to remove (enter numbers, comma-separated, or "all" for all):');
  console.log('Type "cancel" to exit without deleting.\n');
  
  gogs.forEach((gog, index) => {
    console.log(`  ${index + 1}. ${gog}`);
  });
  
  let input;
  while (true) {
    input = await question('\nEnter selection: ');
    
    if (input.toLowerCase() === 'cancel') {
      console.log('\nCancelled. No GOGs were removed.');
      return null;
    }
    
    if (input.toLowerCase() === 'all') {
      return gogs;
    }
    
    try {
      const indices = input.split(',').map(s => parseInt(s.trim()) - 1);
      
      if (indices.every(i => i >= 0 && i < gogs.length)) {
        indices.forEach(i => {
          if (!selected.includes(gogs[i])) {
            selected.push(gogs[i]);
          }
        });
        
        if (selected.length > 0) {
          return selected;
        } else {
          console.log('Invalid selection. Please try again.');
          continue;
        }
      } else {
        console.log('Invalid selection. Please try again.');
      }
    } catch (err) {
      console.log('Invalid input. Please enter numbers separated by commas.');
    }
  }
}

function deleteFile(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return true;
    }
    return false;
  } catch (err) {
    console.error(`Error deleting ${filePath}:`, err.message);
    return false;
  }
}

function updateDatabase(gogsToRemove) {
  try {
    let db = readDatabase();
    const initialCount = db.length;
    
    db = db.filter(entry => !gogsToRemove.includes(entry.file));
    
    fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
    
    return initialCount - db.length;
  } catch (err) {
    console.error('Error updating database:', err.message);
    return 0;
  }
}

async function main() {
  try {
    const allGogs = getLocalGogs();
    
    if (allGogs.length === 0) {
      console.log('No GOGs found in the gogs directory.');
      rl.close();
      return;
    }
    
    const selectedGogs = await selectGogs(allGogs);
    
    if (selectedGogs === null) {
      rl.close();
      return;
    }
    
    // Show confirmation
    console.log('\n========== CONFIRMATION ==========');
    console.log(`\nThe following ${selectedGogs.length} GOG(s) will be PERMANENTLY DELETED:\n`);
    selectedGogs.forEach((gog, index) => {
      console.log(`  ${index + 1}. ${gog}`);
    });
    
    const confirm = await question('\nAre you SURE you want to delete these? (yes/no): ');
    
    if (confirm.toLowerCase() !== 'yes') {
      console.log('\nCancelled. No GOGs were removed.');
      rl.close();
      return;
    }
    
    // Delete GOGs
    console.log('\n========== DELETING ==========\n');
    
    let deletedCount = 0;
    let dbUpdated = 0;
    
    selectedGogs.forEach(gog => {
      const pcPath = path.join(GOGS_PC_DIR, gog);
      const webPath = path.join(GOGS_WEB_DIR, gog);
      
      const pcDeleted = deleteFile(pcPath);
      const webDeleted = deleteFile(webPath);
      
      if (pcDeleted || webDeleted) {
        deletedCount++;
        console.log(`✓ Deleted: ${gog}`);
      } else {
        console.log(`✗ Failed to delete: ${gog}`);
      }
    });
    
    // Update database
    dbUpdated = updateDatabase(selectedGogs);
    
    console.log('\n========== COMPLETE ==========');
    console.log(`✓ Deleted ${deletedCount} GOG file(s) from disk`);
    console.log(`✓ Updated database (removed ${dbUpdated} entries)`);
    console.log('\nRemoval complete!');
    
  } catch (err) {
    console.error('An error occurred:', err.message);
  } finally {
    rl.close();
  }
}

main();
