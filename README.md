# seerr-manage-own-requests

A standalone patch that adds a **Manage Own Requests** permission to
[Seerr](https://github.com/seerr-team/seerr), so users can delete their own
requests and remove that media from Radarr/Sonarr — without granting them the
all-powerful `Manage Requests` permission.

This is **not** an official Seerr plugin and is not affiliated with the Seerr
team. See [Why a patch?](#why-a-patch) below.

## What it does

Seerr's `Manage Requests` permission is all-or-nothing: it lets a user view and
delete *everyone's* requests. This patch adds a child permission,
`Manage Own Requests`, that grants only:

- deleting your own media requests (any status), and
- deleting the media file from Radarr/Sonarr when you are the **only** user
  with an active request for that title/resolution.

`Manage Requests` continues to work exactly as before. Admins are unaffected.

The permission shows up under **Settings > Users > Permissions > Manage
Requests**, and the relevant buttons appear only on your own requests.

## Install

The pinned Seerr release is in `install.sh` / `install.ps1` / `Dockerfile`
(currently **v3.5.0**). If you run a different Seerr version, check the
compatibility note under [Updating](#updating).

### Docker (recommended)

A prebuilt image is published to GHCR by
[`.github/workflows/docker.yml`](.github/workflows/docker.yml):

```yaml
# docker-compose.yml
services:
  seerr:
    image: ghcr.io/draand28/seerr-manage-own-requests:latest
    ports: ["30357:5055"]
    volumes: ["./config:/app/config"]
    restart: unless-stopped
```

Change the left side of `ports` to whatever host port you use. The image
listens on **5055** internally (upstream default); to make the app itself
listen elsewhere, set `PORT` and map the same number on both sides (e.g.
`PORT=30357` with `30357:30357`).

Or build the image yourself:

```sh
docker build -t seerr-manage-own-requests .
```

See [`docker-compose.example.yml`](docker-compose.example.yml).

### From source (Linux/macOS)

```sh
./install.sh            # clones ./seerr, applies the patch, builds
./seerr && pnpm start
```

### From source (Windows)

```powershell
.\install.ps1
cd seerr; pnpm start
```

Both scripts clone Seerr at the pinned commit if it is not already present,
apply the patch (idempotently), install dependencies and build.

## Usage

1. Log in as an admin.
2. Go to **Settings > Users > Permissions** and edit a user (or set it as a
   default permission).
3. Enable **Manage Own Requests**.
4. That user can now delete their own requests and, when they are the sole
   requester, remove the file from Radarr/Sonarr.

## Updating

The patch is built against a specific upstream release because Seerr has no
plugin API.

[`.github/workflows/auto-update.yml`](.github/workflows/auto-update.yml) runs
nightly and keeps the pin current automatically:

- It looks up the latest Seerr **release**.
- If the patch still applies to it, it bumps `SEERR_REF` in
  `install.sh`/`install.ps1`/`Dockerfile`, commits, and rebuilds `:latest`.
- If the patch **no longer applies** (upstream changed the same lines), it
  opens an issue instead of pushing a broken build. Someone then rebases
  [`patches/0001-manage-own-requests.patch`](patches/0001-manage-own-requests.patch).

To pull the update: `docker pull ghcr.io/draand28/seerr-manage-own-requests:latest`
and recreate the container. For a source install, re-run the installer after
setting the new ref:

```sh
SEERR_REF=<new-commit> ./install.sh path-to-seerr
```

To move manually, rebase the patch onto the target release and update the
`SEERR_REF` value in `install.sh`/`install.ps1`/`Dockerfile`.

## Uninstall

The change is a source patch, so restore your checkout:

```sh
cd seerr && git checkout -- .
```

## Tests

The patch adds its own unit tests. After installing:

```sh
cd seerr
pnpm test server/entity/Media.test.ts server/routes/media.test.ts server/routes/request.test.ts
```

## Why a patch?

Seerr is a monolithic Next.js + Express app. It has **no plugin system** — no
extension loader, no hooks — and both the server (`dist/`) and frontend
(`.next/`) are compiled artifacts, so nothing can be injected at runtime. A
self-contained, independently distributable add-on therefore has to carry a
source patch and a rebuild step. That is what this repo is.

## License

MIT. See [LICENSE](LICENSE).
