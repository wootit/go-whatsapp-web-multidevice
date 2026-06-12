#!/bin/sh
set -e

# Some hosts (e.g. Railway) allow only ONE persistent volume per service, mounted at
# /app/storages. Symlink statics into that volume so QR codes, send-items, and downloaded
# media persist across restarts/redeploys alongside the SQLite DB. The app uses the relative
# path "statics/..." from WORKDIR /app, which the symlink transparently resolves into the volume.
if [ ! -L /app/statics ]; then
	rm -rf /app/statics
	ln -s /app/storages/statics /app/statics
fi

# Bind mounts / volumes are often root-owned on the host; the app runs as gowauser and SQLite
# needs write access (DB + WAL). Fix ownership at start (requires container root).
for d in /app/storages /app/storages/statics /app/storages/statics/qrcode /app/storages/statics/senditems /app/storages/statics/media; do
	[ -d "$d" ] || mkdir -p "$d"
done
chown -R gowauser:gowa /app/storages 2>/dev/null || true
chown -h gowauser:gowa /app/statics 2>/dev/null || true

exec su-exec gowauser /app/whatsapp "$@"
