#!/bin/bash
cd "$(dirname "$0")/.."
echo "[laoz] Stopping stack..."
docker compose down
