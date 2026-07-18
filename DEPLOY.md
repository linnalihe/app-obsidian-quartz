This is a read-only public deployment behind the VPS's existing Traefik. It publishes no host ports and manages no certificates.

---

## Prerequisites

- Hostinger VPS (Debian/Ubuntu) with SSH access as a sudo-capable user.
- **The existing Traefik stack is already running**, and its Docker network named **`proxy`** exists. Verify with: `docker network ls | grep proxy`.
- A **DNS A record** for your subdomain (e.g. `kb.example.com`) pointing at the VPS public IPv4 (add AAAA too if the VPS has IPv6). Traefik's HTTP-01 challenge needs this resolving first.

---

## Step 1 — (If Docker isn't already installed) install Docker

> Traefik is already running, so Docker is almost certainly installed. Skip if `docker` works.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER   # log out/in after this
```

> On Debian, replace `ubuntu` with `debian` in the two URLs above.

---

## Step 2 — Firewall

> Traefik already owns 80/443. Only ensure SSH + those two are allowed; do NOT open anything for this app (it publishes no host ports).

```bash
# If ufw is already configured for the Traefik stack, you likely need to change NOTHING.
sudo ufw status
# If ufw is not yet set up:
# sudo apt-get install -y ufw
# sudo ufw default deny incoming && sudo ufw default allow outgoing
# sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
# sudo ufw enable
```

---

## Step 3 — Confirm the proxy network exists

```bash
docker network ls | grep proxy   # must show a network named exactly "proxy"
```

If it's missing, the Traefik stack isn't up — start it first.

---

## Step 4 — Clone and configure

```bash
git clone https://github.com/linnali577/app-obsidian-quartz.git knowledge-base
cd knowledge-base
cp .env.example .env
nano .env          # set DOMAIN and BASE_URL to your real subdomain, e.g. kb.example.com
```

---

## Step 5 — Launch

```bash
docker compose up -d --build
docker compose logs -f kb            # confirm nginx started
docker logs -f traefik 2>&1 | grep -i acme   # (optional) watch cert issuance on the proxy
```

Visit `https://<your-domain>` — it should load over valid HTTPS issued by Traefik.

---

## Step 6 — Updating content later

Edit notes in Obsidian locally, commit, push. Then on the VPS:

```bash
cd knowledge-base
git pull
docker compose up -d --build         # rebuilds the static site with new notes
```

> Optional automation (cron/webhook) is out of scope for v1.

---

## Troubleshooting

- **404 from Traefik ("no route"):** router rule/host mismatch, or container not on the `proxy` network, or `traefik.enable=true` missing.
- **502 Bad Gateway:** `loadbalancer.server.port` doesn't match nginx's real listen port (should be 8080 for nginx-unprivileged).
- **Cert not issued:** DNS A record not resolving to the VPS yet, or the subdomain wasn't reachable on port 80 for the HTTP-01 challenge.

---

## Optional Hardening (not enabled by default)

### Add a shared password — as a Traefik middleware

Generate an htpasswd hash (bcrypt), then add a basic-auth middleware and attach it to the router. No change to the app image.

```bash
# Generate 'user:hash' (escape $ as $$ if pasting into docker-compose labels)
htpasswd -nbB admin 'YOUR_PASSWORD'
```

Add labels to the `kb` service in `docker-compose.yml`:

```yaml
      - "traefik.http.middlewares.kb-auth.basicauth.users=admin:$$2y$$05$$...."
      - "traefik.http.routers.kb.middlewares=kb-sec,kb-auth"
```

Run `docker compose up -d` to apply.

### Restrict to a specific IP range

Add a Traefik IP-allowlist middleware:

```yaml
      - "traefik.http.middlewares.kb-ip.ipallowlist.sourcerange=203.0.113.0/24,198.51.100.7/32"
      - "traefik.http.routers.kb.middlewares=kb-sec,kb-ip"
```
