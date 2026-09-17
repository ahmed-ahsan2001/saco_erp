# SACO ERP — deploy configs

Deploy configs for **SACO** live in this monorepo folder (`saco/`), same as `hamza/` for printing.

| File (repo root) | Purpose |
|------------------|---------|
| `apps.json` | GitHub PAT + `saco_erp` repo URL for Docker build |
| `saco.env` | Site name, DB password, port |

## VPS deploy

```bash
git clone https://github.com/ahmed-ahsan2001/hamza-enterprises-ERP-NEXT.git
cd hamza-enterprises-ERP-NEXT
cp saco/env.example saco.env && nano saco.env
nano apps.json   # GitHub PAT for saco_erp
bash saco/update-app.sh
```

See [DEPLOY.md](./DEPLOY.md).

## Dev sync (Mac)

```bash
rsync -a --exclude '.git' apps/saco_management/ ~/saco_erp/
rsync -a --exclude '.git' saco/ ~/saco_erp/
cd ~/saco_erp && git add . && git commit && git push
```
