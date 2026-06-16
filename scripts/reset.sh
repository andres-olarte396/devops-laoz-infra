#!/bin/bash
cd "$(dirname "$0")/.."
echo "[laoz] Stopping and removing containers + volumes..."
docker compose down -v --remove-orphans
echo "[laoz] Pruning unused images..."
docker image prune -f
echo "[laoz] Reset complete. Run ./scripts/start.sh to restart."
