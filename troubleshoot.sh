#!/usr/bin/env bash
# Run on VPS when SACO ERP is unreachable after deploy.
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

COMPOSE_FILE="${COMPOSE_FILE:-/opt/saco/docker-compose.yml}"
PROJECT="${COMPOSE_PROJECT_NAME:-saco}"
SITE="${FRAPPE_SITE_NAME_HEADER:-YOUR_VPS_IP}"
PORT="${HTTP_PUBLISH_PORT:-8082}"

dc() {
	docker compose -p "$PROJECT" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"
}

echo "=== Container status ==="
dc ps -a || docker ps -a --filter "name=saco"

echo
echo "=== Published ports (frontend) ==="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'saco|NAMES' || true

echo
echo "=== Local curl frontend (on VPS) ==="
curl -sS -o /dev/null -w "localhost:$PORT -> HTTP %{http_code}\n" "http://127.0.0.1:$PORT/" || echo "curl failed — frontend not listening"

echo
echo "=== Backend health ==="
dc logs backend --tail 40 2>&1 || true

echo
echo "=== Frontend health ==="
dc logs frontend --tail 30 2>&1 || true

echo
echo "=== Configurator (must succeed once) ==="
dc logs configurator --tail 20 2>&1 || true

echo
echo "=== Site list ==="
dc exec -T backend bench --site all list 2>&1 || echo "backend exec failed"

echo
echo "=== Firewall (ufw) ==="
if command -v ufw >/dev/null 2>&1; then
	sudo ufw status || ufw status || true
else
	echo "ufw not installed"
fi

echo
echo "=== Quick fixes to try ==="
cat <<EOF
1. If containers are Exited/Created:
   bash saco/update-app.sh

2. If port $PORT closed in ufw:
   sudo ufw allow ${PORT}/tcp

3. If site exists but 404/502, clear cache:
   docker compose -p $PROJECT -f $COMPOSE_FILE --env-file $ENV_FILE exec backend \\
     bench --site $SITE clear-cache
EOF
