#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

// Copy gogs/ folder into docs/gogs/ and generate docs/gogs-list.json
const srcDir = path.join(__dirname, 'gogs');
const destDir = path.join(__dirname, 'docs', 'gogs');

if (!fs.existsSync(destDir)) {
  fs.mkdirSync(destDir, { recursive: true });
}

const files = fs.readdirSync(srcDir).filter(f => /\.(png|jpe?g|gif|svg|webp)$/i.test(f));

// Copy files
files.forEach(f => {
  const src = path.join(srcDir, f);
  const dst = path.join(destDir, f);
  fs.copyFileSync(src, dst);
});

// Generate manifest
const manifest = files.map(f => ({
  name: f.replace(/\.[^/.]+$/, ''),
  file: f,
  url: `/docs/gogs/${encodeURIComponent(f)}`
}));

fs.writeFileSync(
  path.join(__dirname, 'docs', 'gogs-list.json'),
  JSON.stringify(manifest, null, 2)
);

console.log(`✓ Synced ${files.length} GOG images to docs/gogs/ and generated docs/gogs-list.json`);
