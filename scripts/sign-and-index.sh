#!/usr/bin/env bash
# Local signing for the AROKI TEST feed. No GitHub secrets, no workflow.
#   scripts/sign-and-index.sh [path-to-private-key] [path-to-vireo-tool]
# Copies source/<id>.json byte-for-byte to connectors/<id>/releases/<sha256>/connector.json,
# signs each manifest, rebuilds index.json (generatedAt strictly increases) and signs it,
# then runs `vireo-tool verify-repository`. The private key never enters this repo.
set -euo pipefail
cd "$(dirname "$0")/.."
KEY_FILE="${1:-$HOME/.aroki-test-signing/test-private.key}"
TOOL="${2:-${VIREO_TOOL:-}}"
[[ -f "$KEY_FILE" && -n "$TOOL" && -x "$TOOL" ]] || { echo "usage: $0 <private-key-file> <vireo-tool>" >&2; exit 64; }
KEY="$(tr -d '\n' < "$KEY_FILE")"
PUB_FILE="$(dirname "$KEY_FILE")/test-public.key"
PUBKEY="$(tr -d '\n' < "$PUB_FILE")"
export PUBKEY
for f in source/*.json; do
  id="$(basename "$f" .json)"
  sha="$("$TOOL" sha256 "$f")"
  dest="connectors/$id/releases/$sha"
  mkdir -p "$dest"
  if [[ -f "$dest/connector.json" ]] && ! cmp -s "$f" "$dest/connector.json"; then echo "refusing to replace immutable artifact" >&2; exit 1; fi
  cp "$f" "$dest/connector.json"
  "$TOOL" sign-manifest "$KEY" "$dest/connector.json" > "$dest/.sig.tmp"
done
python3 - <<'PY'
import hashlib, json, os, time
from pathlib import Path
repo = json.load(open("repository.json"))
try: old_gen = int(json.load(open("index.json")).get("generatedAt", 0))
except Exception: old_gen = 0
entries = []
for f in sorted(Path("source").glob("*.json")):
    m = json.load(open(f)); cid = f.stem
    assert m["id"] == cid
    sha = hashlib.sha256(f.read_bytes()).hexdigest()
    d = Path(f"connectors/{cid}/releases/{sha}")
    sig = (d / ".sig.tmp").read_text().strip(); (d / ".sig.tmp").unlink()
    entries.append({
        "contentRating": m.get("contentRating", "unknown"), "contentType": m.get("contentType", "video"),
        "familyID": m["familyID"], "id": m["id"], "language": m.get("language", "en"),
        "manifest": {"path": f"connectors/{cid}/releases/{sha}/connector.json", "sha256": sha, "signature": sig},
        "minimumAppVersion": m["minimumAppVersion"], "name": m["name"], "releaseNotes": m.get("releaseNotes", ""),
        "releaseTrack": m.get("releaseTrack", "beta"), "status": m.get("status", "active"), "version": m["version"]})
index = {"schemaVersion": 1, "repositoryID": repo["repositoryID"], "name": repo["name"], "enabled": repo["enabled"],
         "generatedAt": max(old_gen + 1, int(time.time())), "publicKey": os.environ["PUBKEY"], "connectors": entries}
Path("index.json").write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n")
PY
"$TOOL" sign-index "$KEY" index.json
"$TOOL" verify-repository index.json
