const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const UPLOAD_CODE = process.env.UPLOAD_CODE || 'letmein';
const PORT = process.env.PORT || 3000;

const app = express();
app.use(cors());

const PUBLIC_DIR = path.join(__dirname, 'public');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const GOGS_DIR = path.join(__dirname, 'gogs');

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
if (!fs.existsSync(GOGS_DIR)) {
  fs.mkdirSync(GOGS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, UPLOAD_DIR);
  },
  filename: function (req, file, cb) {
    const safe = Date.now() + '-' + file.originalname.replace(/[^a-zA-Z0-9.\-_]/g, '_');
    cb(null, safe);
  }
});

const upload = multer({ storage });

// Serve static frontend
app.use(express.static(PUBLIC_DIR));
// Serve uploaded files
app.use('/uploads', express.static(UPLOAD_DIR));
// Serve gogs assets (GOG database)
app.use('/gogs', express.static(GOGS_DIR));

// List files in the gogs folder for the GOG database
app.get('/gogs-list', (req, res) => {
  fs.readdir(GOGS_DIR, (err, files) => {
    if (err) return res.status(500).json({ error: 'failed to list gogs' });
    const images = files.filter(f => /\.(png|jpe?g|gif|svg|webp)$/i.test(f))
      .map(f => ({ name: f.replace(/\.[^/.]+$/, ''), file: f, url: `/gogs/${encodeURIComponent(f)}` }));
    res.json(images.reverse());
  });
});

app.get('/files', (req, res) => {
  fs.readdir(UPLOAD_DIR, (err, files) => {
    if (err) return res.status(500).json({ error: 'failed to list files' });
    const list = files
      .filter(f => !f.startsWith('.'))
      .map(f => ({ name: f, url: `/uploads/${encodeURIComponent(f)}` }));
    res.json(list.reverse());
  });
});

app.post('/upload', upload.single('file'), (req, res) => {
  const code = req.body.code || '';
  if (code !== UPLOAD_CODE) {
    // remove file if saved
    if (req.file && req.file.path) {
      fs.unlink(req.file.path, () => {});
    }
    return res.status(403).json({ ok: false, error: 'invalid upload code' });
  }
  if (!req.file) return res.status(400).json({ ok: false, error: 'no file' });
  res.json({ ok: true, file: { name: req.file.filename, url: `/uploads/${encodeURIComponent(req.file.filename)}` } });
});

app.get('/health', (req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`GOG site running on http://localhost:${PORT}`);
});
