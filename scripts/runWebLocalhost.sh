#!/usr/bin/env bash
# Desde la raiz del repo (carpeta atlas), equivalente:
#   flutter run -d web-server --web-hostname localhost --web-port 8080
set -euo pipefail
cd "$(dirname "$0")/.."
exec flutter run -d web-server --web-hostname localhost --web-port 8080
