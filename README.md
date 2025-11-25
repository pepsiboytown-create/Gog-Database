# GOG Characters Site

Small demo site for "GOGs" — cute little characters that do silly things. Includes a protected upload feature so only people with the upload code can add images.

Quick start

1. Install dependencies

```powershell
npm install
```

2. Copy `.env.example` to `.env` and optionally change `UPLOAD_CODE`

3. Start the site

```powershell
npm start
```

4. Open http://localhost:3000

Upload code

The default upload code is `letmein` (change it in `.env`). The frontend will send the code along with the file; the server will reject uploads with an incorrect code.

Notes

- Uploaded files are saved to `uploads/` and served from `/uploads/`.
- This is a simple demo; for production harden the server, validate file types, and add auth.

GitHub Pages

This repository includes a static copy of the frontend in the `docs/` folder that can be published to GitHub Pages (Settings → Pages → Source: `main` branch / `docs/` folder). To publish:

1. Push your branch to GitHub.
2. In repository Settings → Pages, select `main` branch and `/docs` folder and save.

Limitations on Pages

- GitHub Pages only serves static files — it cannot run the Node/Express server used for uploads. The `docs/` site will therefore show a demo gallery and will disable uploads while running on `github.io`.
- If you want the protected upload feature to work, deploy the `server.js` app to a platform that runs Node (for example: Render, Railway, Vercel (serverless function), or a small VPS). Then update the frontend to point to that server URL instead of `/upload` and `/files`.

Recommended quick paths to keep uploads:

- Deploy the Express app to Render or Railway (they accept a GitHub repo and host Node apps). Keep `UPLOAD_CODE` in environment settings on the host.
- Use Netlify or Vercel functions as a lightweight serverless upload endpoint and connect to an object store (S3) — this requires extra config.

If you'd like, I can:

- Add a Dockerfile so you can run the server in a container and deploy it to any host that supports Docker.
- Add instructions and a simple GH Action that deploys the `docs/` folder to the `gh-pages` branch automatically.

