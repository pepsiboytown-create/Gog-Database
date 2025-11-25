async function fetchFiles() {
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

fetchFiles();
