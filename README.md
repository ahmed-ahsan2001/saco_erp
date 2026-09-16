# SACO ERP

Single repo for **SACO** — deploy scripts + `saco_management` Frappe app.

Synced to `~/saco_erp/` (GitHub: [saco_erp](https://github.com/ahmed-ahsan2001/saco_erp.git)).

Same pattern as Hamza printing: local folder `~/printing_management-ERP`, GitHub repo `printing_management` — one repo holds the app; deploy configs for SACO live in the same `saco_erp` repo.

## Repo layout (`~/saco_erp`)

```
saco_erp/
  update-app.sh          # deploy / update script
  DEPLOY.md              # production guide
  env.example            # copy to saco.env in monorepo root
  apps.json              # GitHub PAT for Docker build
  pyproject.toml         # Frappe app package
  saco_management/       # app source (hooks, doctypes, setup, …)
```

## Development (monorepo)

Edit app code in `apps/saco_management/` and deploy configs in `saco/`, then sync both into `~/saco_erp/`:

```bash
rsync -a --exclude '__pycache__' --exclude '.DS_Store' --exclude '.git' \
  apps/saco_management/ ~/saco_erp/

rsync -a --exclude '__pycache__' --exclude '.DS_Store' --exclude '.git' \
  saco/ ~/saco_erp/
```

## Deploy

```bash
cd ~/hamza-enterprises-ERP-NEXT
cp saco/env.example saco.env   # first time only
ENV_FILE=saco.env bash ~/saco_erp/update-app.sh
```

See [DEPLOY.md](./DEPLOY.md) for first-time site creation and troubleshooting.
