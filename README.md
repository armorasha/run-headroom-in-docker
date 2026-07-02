# Run Headroom in Docker

[Headroom](https://github.com/headroomlabs-ai/headroom) is a context compression proxy for Claude Code. It intercepts API traffic between Claude Code and Anthropic and compresses large tool outputs before they enter the context window.  

Headroom's own documentation cites a 60–95% reduction in token usage from this; the figure hasn't been independently benchmarked in this project, but it lines up with the compression happening on typically-verbose tool output.

This project runs the proxy as a standalone Docker container via Docker Compose, so it can be started once and shared by any project that points `ANTHROPIC_BASE_URL` at it.

> **Do not route this project itself through headroom.** This repo only exists to host and manage the proxy container — its own `.claude/settings.local.json` must never set `ANTHROPIC_BASE_URL` to the proxy. Point *other* projects at it instead.

## Platform

Built and tested for this specific setup:

- **Claude Code VSCode extension** — routing is configured per-project through `.claude/settings.local.json`, which VSCode reads on window reload. A different Claude Code client (CLI-only, JetBrains) may need a different config mechanism.
- **Ubuntu** — the reboot-survival setup in [STARTUP.md](STARTUP.md) relies on Ubuntu's systemd-managed `docker.service` starting on boot. Other OS (or Docker Desktop) may need a different approach there.

## How it works

```
Claude Code → http://headroom.local:8787 (headroom proxy) → https://api.anthropic.com
```
The proxy compresses large tool outputs (file reads, search results, bash output) before they reach the model.

## Quick Start
### Point `headroom.local` at localhost (one-time)

`headroom.local` must resolve to `127.0.0.1`. Add this line to `/etc/hosts` (one-time, requires sudo):

```bash
echo "127.0.0.1 headroom.local" | sudo tee -a /etc/hosts
```

### Start headroom

```bash
docker compose up headroom -d
```

The container restarts automatically on crash and survives machine reboots (`restart: unless-stopped`) — see [STARTUP.md](STARTUP.md) for how that works and how to verify it.

### Stop headroom

```bash
docker compose stop headroom
```

### Build the image (first time or after Dockerfile changes)

```bash
docker compose build headroom
```

### Dashboard

Start the proxy first, then open:

```
http://headroom.local:8787/dashboard
```

Shows live compression stats, token savings, and session history.

### Enable / disable routing in a project

Add (or uncomment) this in the target project's `.claude/settings.local.json`:

```jsonc
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://headroom.local:8787"
  }
}
```

Remove or comment it out, then reload the VSCode window, to bypass the proxy and go directly to `api.anthropic.com`.

> **Warning:** Claude Code will fail to connect if this headroom container is not running while a project has `ANTHROPIC_BASE_URL` pointed at it. Start it first and keep it running for the lifetime of your session.

#### Per-project tracking

To attribute compression stats to a specific project in the dashboard, append a project name or code to the path instead of pointing at the bare host:

```jsonc
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://headroom.local:8787/p/<project-name>"
  }
}
```

Use a distinct `<project-name>` per project (e.g. `p/proj-a`, `p/proj-b`) — the proxy is shared across projects, so this is what separates their usage in the dashboard and session history.

## Files

| File | Purpose |
|---|---|
| `infra/headroom.Dockerfile` | Builds the headroom proxy image |
| `docker-compose.yml` → `headroom` service | Runs the proxy on port 8787 |
| [`STARTUP.md`](STARTUP.md) | How the container survives reboots, and how to verify it did |
