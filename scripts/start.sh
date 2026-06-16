#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ ! -f .env ]; then
  echo "[laoz] .env not found. Copying from .env.template..."
  cp .env.template .env
  echo "[laoz] Fill in .env before restarting."
  exit 1
fi

echo "[laoz] Starting stack..."
docker compose up -d --build
echo "[laoz] Stack up. Gateway at http://localhost:9000"
echo "[laoz] Portal   at http://localhost:80"
echo "[laoz] Docs     at http://localhost:7000"
