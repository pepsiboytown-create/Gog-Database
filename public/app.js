async function fetchFiles() {
  // legacy gallery (uploads)
  const el = document.getElementById('files');
  el.innerHTML = '<p class="muted">Loading uploads…</p>';
  try {
    const r = await fetch('/files');
    const items = await r.json();
    if (!items || items.length === 0) {
      el.innerHTML = '<p class="muted">No uploads yet — be first!</p>';
      return;
    }
    el.innerHTML = '';
    for (const it of items) {
      const img = document.createElement('img');
      img.src = it.url;
      img.alt = it.name;
      el.appendChild(img);
    }
  } catch (err) {
    el.innerHTML = '<p class="muted">Failed to load uploads</p>';
    console.error(err);
  }
}

document.getElementById('uploadForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const fileInput = document.getElementById('file');
  const codeInput = document.getElementById('code');
  const msg = document.getElementById('uploadMsg');
  msg.textContent = '';
  if (!fileInput.files || fileInput.files.length === 0) return (msg.textContent = 'Choose a file');
  const fd = new FormData();
  fd.append('file', fileInput.files[0]);
  fd.append('code', codeInput.value);
  try {
    const res = await fetch('/upload', { method: 'POST', body: fd });
    const j = await res.json();
    if (!res.ok) {
      msg.textContent = j.error || 'upload failed';
      msg.style.color = '#ffb4b4';
      return;
    }
    msg.textContent = 'Upload successful!';
    msg.style.color = '#bff0c5';
    fileInput.value = '';
    codeInput.value = '';
    await fetchFiles();
  } catch (err) {
    msg.textContent = 'Upload error';
    msg.style.color = '#ffb4b4';
    console.error(err);
  }
});

// --- New: GOG Database UI ---
function showPage(name) {
  document.querySelectorAll('.page').forEach(p => p.style.display = 'none');
  const el = document.getElementById(name);
  if (el) el.style.display = '';
}

async function loadGogGrid() {
  const grid = document.getElementById('gogGrid');
  grid.innerHTML = '<p class="muted">Loading GOGs…</p>';
  try {
    const res = await fetch('/gogs-list');
    const items = await res.json();
    if (!items || items.length === 0) {
      grid.innerHTML = '<p class="muted">No GOGs found in the server gogs/ folder.</p>';
      return;
    }
    grid.innerHTML = '';
    for (const it of items) {
      const card = document.createElement('div');
      card.className = 'gog-item';
      const img = document.createElement('img');
      img.className = 'gog-thumb';
      img.src = it.url;
      img.alt = it.name;
      img.loading = 'lazy';
      const label = document.createElement('div');
      label.className = 'gog-label';
      label.textContent = it.name;
      card.appendChild(img);
      card.appendChild(label);
      card.addEventListener('click', () => showLarge(it));
      grid.appendChild(card);
    }
  } catch (err) {
    grid.innerHTML = '<p class="muted">Failed to load GOG database</p>';
    console.error(err);
  }
}

function showLarge(item) {
  const w = window.open(item.url, '_blank');
  if (!w) alert(item.name);
}

async function loadRandomGog() {
  const box = document.getElementById('randomBox');
  box.innerHTML = '<p class="muted">Finding a random GOG…</p>';
  try {
    const res = await fetch('/gogs-list');
    const items = await res.json();
    if (!items || items.length === 0) {
      box.innerHTML = '<p class="muted">No GOGs available</p>';
      return;
    }
    const pick = items[Math.floor(Math.random() * items.length)];
    box.innerHTML = '';
    const img = document.createElement('img');
    img.src = pick.url;
    img.alt = pick.name;
    const name = document.createElement('div');
    name.className = 'gog-label';
    name.textContent = pick.name;
    box.appendChild(img);
    box.appendChild(name);
  } catch (err) {
    box.innerHTML = '<p class="muted">Failed to load random GOG</p>';
  }
}

// navigation
document.querySelectorAll('.nav button').forEach(b => b.addEventListener('click', async (e) => {
  const page = e.currentTarget.dataset.page;
  showPage(page);
  if (page === 'db') await loadGogGrid();
  if (page === 'random') await loadRandomGog();
}));

// start on About
showPage('about');

// also load legacy uploads gallery
fetchFiles();
