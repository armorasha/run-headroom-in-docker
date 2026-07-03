# Auto-start on machine boot

The `headroom` container is configured with `restart: unless-stopped` in `docker-compose.yml`. Combined with the system's Docker daemon (`docker.service`), this is enough to bring it back automatically after a reboot — no extra systemd unit, cron job, or startup script is needed.

## Why this works

- `docker.service` is enabled and active via systemd on this machine, so Docker itself starts on boot without any manual step.
- `restart: unless-stopped` tells Docker to restart the container whenever the daemon (re)starts, for as long as the container wasn't *manually* stopped beforehand (e.g. via `docker compose stop` or `docker stop`).

## The one way this can fail

If the container is in a manually-stopped state when the machine goes down, it stays stopped after reboot — `unless-stopped` respects that last manual action. So the container must be left **running** (`docker compose up -d headroom`) before you shut down or restart.

## Verifying after a reboot

```bash
# from this project folder root
docker compose ps
# or from anywhere
docker ps --filter "name=headroom"
```

Should show `headroom` as `Up`. 

Open the dashboard in a browser:

```
http://headroom.local:8787/dashboard
```

You can confirm if the proxy answers:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://headroom.local:8787
```

If it's not running, start it manually:

```bash
docker compose up -d headroom
```

See [README.md](README.md) for general usage, dashboard, and per-project routing setup.
