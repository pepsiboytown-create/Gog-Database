// GitHub Pages aware frontend
// If running on github.io we disable upload and show bundled demo assets

const isPages = location.hostname.includes('github.io') || location.pathname.startsWith('/');

async function fetchFiles() {
  const el = document.getElementById('files');
  el.innerHTML = '<p class="muted">Loading uploads…</p>';
  if (isPages) {
    // Try to load a static manifest placed in docs/ so Pages can show the DB.
    el.innerHTML = '';
    try {
      const m = await fetch('/docs/gogs-list.json');
      if (m.ok) {
        const items = await m.json();
        if (Array.isArray(items) && items.length) {
          for (const it of items) {
            const img = document.createElement('img');
            img.src = it.url;
            img.alt = it.name;
            el.appendChild(img);
          }
          return;
        }
      }
    } catch (err) {
      // fallback next
      console.warn('No docs manifest or failed to load it, falling back to bundled demo assets', err);
    }

    // Fallback demo assets (bundled)
    const demo = [
      '/docs/assets/gog1.svg',
      '/docs/assets/gog2.svg',
      '/docs/assets/gog3.svg'
    ];
    for (const src of demo) {
      const img = document.createElement('img');
      img.src = src;
      img.alt = 'GOG demo';
      el.appendChild(img);
    }
    return;
  }

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
  const msg = document.getElementById('uploadMsg');
  if (isPages) {
    msg.textContent = 'Uploads are unavailable on GitHub Pages. Deploy the server elsewhere to enable uploads.';
    msg.style.color = '#ffd1a8';
    return;
  }
  const fileInput = document.getElementById('file');
  const codeInput = document.getElementById('code');
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

fetchFiles();
