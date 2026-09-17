# SACO ERP — production deploy & updates

ERPNext v16 + **saco_management** custom app.

Production URL example: **http://YOUR_VPS_IP:8080**  
Site name: must match `FRAPPE_SITE_NAME_HEADER` in `saco.env`

Custom app source: **[saco_erp](https://github.com/ahmed-ahsan2001/saco_erp)** (baked into Docker image at build time).

Same pattern as Hamza printing: **one clone on the VPS** (`hamza-enterprises-ERP-NEXT`). You do **not** clone `saco_erp` on the server — Docker pulls it from GitHub during the image build.

## First-time deploy (new SACO VPS)

```bash
git clone https://github.com/ahmed-ahsan2001/hamza-enterprises-ERP-NEXT.git
cd hamza-enterprises-ERP-NEXT
```

1. Copy env: `cp saco/env.example saco.env` and set `DB_PASSWORD`, `FRAPPE_SITE_NAME_HEADER`, `HTTP_PUBLISH_PORT`.
2. Put a GitHub PAT in **`apps.json`** at the repo root (replace `ghp_REPLACE_ME`) with read access to `saco_erp`.
3. Open the HTTP port: `ufw allow 8080/tcp || true` (use `8082` only if Hamza/Looms share the same VPS).
4. Deploy:

```bash
bash saco/update-app.sh
```

Or manually:

```bash
set -a && source saco.env && set +a
COMPOSE="-f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.noproxy.yaml"

docker build --network=host \
  --build-arg=ERPNEXT_VERSION=v16.27.0 --build-arg=CACHE_BUST="$(date +%s)" \
  --secret=id=apps_json,src=apps.json \
  --tag=saco-erpnext:16 --file=images/saco/Containerfile .

mkdir -p /opt/saco
docker compose -p saco $COMPOSE --env-file saco.env config > /opt/saco/docker-compose.yml
docker compose -p saco -f /opt/saco/docker-compose.yml --env-file saco.env up -d --force-recreate

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

5. Open **http://YOUR_VPS_IP:8080** → login `Administrator` / `admin` → complete Setup Wizard.

## Update after pushing app changes

**Workflow:** push to `saco_erp` on GitHub → run update on VPS.

```bash
cd ~/hamza-enterprises-ERP-NEXT
bash saco/update-app.sh
```

## Notes

- App code is **inside the image**, cloned from GitHub at build time — rebuild after every app push.
- Do not run `docker compose down -v` unless you intend to wipe the database.

## Daily backup

Reuse the Hamza backup pattern from `hamza/BACKUP.md` with `COMPOSE_PROJECT_NAME=saco` and your SACO site name.
