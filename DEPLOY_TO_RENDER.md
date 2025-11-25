# Deploy to Render

Render is a simple platform to deploy Node apps. You can deploy this GOG site with uploads enabled in minutes.

## Quick steps

1. Push your repo to GitHub (if not already there).
2. Go to [render.com](https://render.com) and sign in with GitHub.
3. Create a new "Web Service" → select your `Gog-Database` repo → choose `main` branch.
4. Configure:
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Environment Variables**: add `UPLOAD_CODE=yourSecretCode` (change to your desired upload code)
   - Keep the default Node.js environment.
5. Deploy. Render will build and start your server.
6. Update the frontend if needed: in `public/app.js` or `public/index.html`, replace `/upload` and `/files` with your Render URL (e.g., `https://your-gog-site.onrender.com/upload`). By default, if you're on the same domain, the relative paths `/upload` and `/files` will work.

Your GOG site will then support uploads on your Render URL. Combine with GitHub Pages:
- Publish `docs/` to GitHub Pages for the static site.
- Deploy the server to Render for the upload feature.

## Other hosting options

- **Railway** (railway.app): Similar to Render, accepts GitHub repos and runs Node.
- **Vercel** (vercel.com): Can deploy the `server.js` as a serverless function (extra config needed).
- **Heroku** (heroku.com): Requires an account and credit card, but has a free tier alternative with other platforms now.
- **Docker + any host**: Use the provided `Dockerfile` to run the app in a container (Fly.io, AWS ECS, etc.).

