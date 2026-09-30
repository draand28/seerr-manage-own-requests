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

The pinned Seerr commit is in `install.sh` / `install.ps1` / `Dockerfile` as
`e959062`. If you run a different Seerr version, check the compatibility note
under [Updating](#updating).

### Docker (recommended)

A prebuilt image is published to GHCR by
[`.github/workflows/docker.yml`](.github/workflows/docker.yml):

```yaml
# docker-compose.yml
services:
  seerr:
    image: ghcr.io/draand28/seerr-manage-own-requests:latest
    ports: ["5055:5055"]
    volumes: ["./config:/app/config"]
    restart: unless-stopped
```

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

The patch is built against a specific upstream commit because Seerr has no
plugin API. To move to a newer Seerr, rebase
[`patches/0001-manage-own-requests.patch`](patches/0001-manage-own-requests.patch)
onto the target commit and refresh the `SEERR_REF` value in
`install.sh`/`install.ps1`/`Dockerfile`.

To update a source install after that:

```sh
SEERR_REF=<new-commit> ./install.sh path-to-seerr
```

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
