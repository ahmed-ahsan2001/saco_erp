# SACO ERP — production deploy & updates

ERPNext v16 + **saco_management** custom app.

Production URL example: **http://YOUR_VPS_IP:8082**  
Site name: must match `FRAPPE_SITE_NAME_HEADER` in `saco.env`

Everything lives in one repo: **[saco_erp](https://github.com/ahmed-ahsan2001/saco_erp)** — deploy scripts and Frappe app source (`~/saco_erp`).

## Prerequisites

On the VPS you need the **frappe_docker** repo (this monorepo):

```bash
git clone https://github.com/ahmed-ahsan2001/hamza-enterprises-ERP-NEXT.git
cd hamza-enterprises-ERP-NEXT
```

Clone the SACO repo (app + deploy):

```bash
git clone https://github.com/ahmed-ahsan2001/saco_erp.git ~/saco_erp
```

## First-time deploy

1. Copy env: `cp saco/env.example saco.env` and set `DB_PASSWORD`, `FRAPPE_SITE_NAME_HEADER`, `HTTP_PUBLISH_PORT`.
2. Put a GitHub PAT in `saco/apps.json` (replace `ghp_REPLACE_ME`) with read access to `saco_erp`.
3. Open the HTTP port (example for 8082): `ufw allow 8082/tcp || true`
4. Deploy:

```bash
cd ~/hamza-enterprises-ERP-NEXT
ENV_FILE=saco.env bash ~/saco_erp/update-app.sh
```

Or manually:

```bash
set -a && source saco.env && set +a
COMPOSE="-f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.noproxy.yaml"

docker build --network=host \
  --build-arg=ERPNEXT_VERSION=v16.27.0 --build-arg=CACHE_BUST="$(date +%s)" \
  --secret=id=apps_json,src=saco/apps.json \
  --tag=saco-erpnext:16 --file=images/saco/Containerfile .

mkdir -p /opt/saco
docker compose -p saco $COMPOSE --env-file saco.env config > /opt/saco/docker-compose.yml
docker compose -p saco -f /opt/saco/docker-compose.yml --env-file saco.env up -d --force-recreate

# Wait for MariaDB, then create the site (first time only)
sleep 30
docker compose -p saco -f /opt/saco/docker-compose.yml --env-file saco.env exec backend \
  bench new-site YOUR_VPS_IP \
    --mariadb-user-host-login-scope='%' \
    --admin-password=admin \
    --db-root-username=root \
    --db-root-password="$DB_PASSWORD" \
    --install-app erpnext \
    --install-app saco_management \
    --set-default
```

5. Open **http://YOUR_VPS_IP:8082** → login `Administrator` / `admin` → complete Setup Wizard.

6. Run SACO setup (when implemented):

```bash
docker compose -p saco -f /opt/saco/docker-compose.yml --env-file saco.env exec backend \
  bench --site YOUR_VPS_IP execute saco_management.setup.saco_setup.run
```

## Update after pushing app changes

**Workflow:** push to `saco_erp` → run update on VPS.

```bash
cd ~/hamza-enterprises-ERP-NEXT
ENV_FILE=saco.env bash ~/saco_erp/update-app.sh
```

Change `ERPNEXT_VERSION` / `CUSTOM_TAG` in `saco.env` when bumping ERPNext.

## Notes

- App code is **inside the image**, cloned from `saco_erp` at build time — rebuild after every push.
- Use `CACHE_BUST=$(date +%s)` so Docker pulls the latest `main` from GitHub.
- Do **not** use `--build-arg=FRAPPE_BRANCH=...` / `bench init` — that path fails on ERPNext `banking` yarn install on many VPS networks.
- Do not run `docker compose down -v` unless you intend to wipe the database.
- Hamza (printing) and Looms (textile) are **separate** Compose projects — do not overwrite their `.env` files.

## Daily backup

Reuse the Hamza backup pattern from `hamza/BACKUP.md` with `COMPOSE_PROJECT_NAME=saco` and your SACO site name.
