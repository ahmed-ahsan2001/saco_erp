#!/usr/bin/env bash
# Update SACO production after pushing saco_erp to GitHub.
# Run from frappe_docker repo root:
#   ENV_FILE=saco.env bash ~/saco_erp/update-app.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-saco.env}"

if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$ENV_FILE"
	set +a
elif [[ -f "$SCRIPT_DIR/../saco.env" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$SCRIPT_DIR/../saco.env"
	set +a
fi

FRAPPE_DOCKER_ROOT="${FRAPPE_DOCKER_ROOT:-$HOME/hamza-enterprises-ERP-NEXT}"
FRAPPE_DOCKER_ROOT="${FRAPPE_DOCKER_ROOT/#\~/$HOME}"
cd "$FRAPPE_DOCKER_ROOT"

if [[ ! -f compose.yaml ]]; then
	echo "Missing compose.yaml in $FRAPPE_DOCKER_ROOT — clone hamza-enterprises-ERP-NEXT first."
	exit 1
fi

SITE="${FRAPPE_SITE_NAME_HEADER:?Set FRAPPE_SITE_NAME_HEADER in saco.env}"
PROJECT="${COMPOSE_PROJECT_NAME:-saco}"
COMPOSE_FILE="${COMPOSE_FILE:-/opt/saco/docker-compose.yml}"
APPS_JSON="${APPS_JSON:-saco/apps.json}"
IMAGE="${CUSTOM_IMAGE:-saco-erpnext}:${CUSTOM_TAG:-16}"

if [[ ! -f "$APPS_JSON" ]]; then
	echo "Missing $APPS_JSON"
	exit 1
fi

if grep -q 'ghp_REPLACE_ME' "$APPS_JSON"; then
	echo "Update GitHub PAT in $APPS_JSON before building (replace ghp_REPLACE_ME)."
	exit 1
fi

CONTAINERFILE="${CONTAINERFILE:-images/saco/Containerfile}"
if [[ ! -f "$CONTAINERFILE" ]]; then
	echo "Missing $CONTAINERFILE"
	exit 1
fi
if grep -q 'bench init' "$CONTAINERFILE"; then
	echo "ERROR: $CONTAINERFILE still uses bench init."
	echo "It must start with: FROM frappe/erpnext:\${ERPNEXT_VERSION}"
	exit 1
fi
if ! grep -q '^FROM frappe/erpnext:' "$CONTAINERFILE"; then
	echo "ERROR: $CONTAINERFILE must use the pre-built frappe/erpnext base image."
	exit 1
fi

echo "==> Using Containerfile: $(head -1 "$CONTAINERFILE")"
git pull --ff-only || true

echo "==> Build image (official ERPNext base + latest saco_erp from GitHub)"
docker build --network=host \
	--build-arg=ERPNEXT_VERSION="${ERPNEXT_VERSION:-v16.27.0}" \
	--build-arg=CACHE_BUST="$(date +%s)" \
	--secret=id=apps_json,src="$APPS_JSON" \
	--tag="$IMAGE" \
	--file="$CONTAINERFILE" .

echo "==> Refresh compose file"
mkdir -p "$(dirname "$COMPOSE_FILE")"
COMPOSE="-f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.noproxy.yaml"
docker compose -p "$PROJECT" $COMPOSE --env-file "$ENV_FILE" config >"$COMPOSE_FILE"

echo "==> Recreate containers"
docker compose -p "$PROJECT" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --force-recreate

echo "==> Wait for backend"
sleep 15

echo "==> Migrate site $SITE"
if docker compose -p "$PROJECT" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T backend \
	bench --site all list 2>/dev/null | grep -q "$SITE"; then
	docker compose -p "$PROJECT" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T backend \
		bench --site "$SITE" migrate
	docker compose -p "$PROJECT" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T backend \
		bench --site "$SITE" clear-cache
else
	echo "Site $SITE not found — run bench new-site once (see DEPLOY.md)."
fi

PORT="${HTTP_PUBLISH_PORT:-8082}"
echo "==> Done. Open http://${SITE}:${PORT}"
