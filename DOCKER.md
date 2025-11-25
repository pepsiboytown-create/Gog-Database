# Docker

Build and run the GOG site in a container.

## Build the image

```bash
docker build -t gog-site .
```

## Run locally

```bash
docker run -p 3000:3000 -e UPLOAD_CODE=letmein gog-site
```

Then open http://localhost:3000.

## Environment variables

- `UPLOAD_CODE` (default: `letmein`) — the code required to upload images.
- `PORT` (default: `3000`) — the port to listen on.

## Deploy to a host

You can push the Docker image to Docker Hub or a registry and deploy it to:
- **Fly.io** (`fly deploy` after login)
- **AWS** (ECR + ECS or AppRunner)
- **Google Cloud** (Cloud Run)
- **Azure** (Container Instances)
- **DigitalOcean** (App Platform)

Example with Fly.io:
```bash
fly auth login
fly launch   # creates fly.toml
fly deploy
```

