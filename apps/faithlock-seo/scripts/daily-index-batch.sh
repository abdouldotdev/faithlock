#!/bin/bash
# Indexation quotidienne : soumet le prochain lot de 10 URLs et met à jour le suivi.
# Lancé par launchd chaque nuit à minuit (voir scripts/install-index-cron.sh).
#
# Ce script ne pilote PAS le navigateur : Google n'expose pas la demande
# d'indexation en API, et automatiser l'interface avec la session Google du
# propriétaire casse au premier changement d'UI. Il prépare le lot, vérifie
# l'état d'indexation réel via l'API Search Console (lecture, officielle), met
# à jour le CSV de suivi, et laisse la soumission manuelle au propriétaire avec
# la liste prête à coller.

set -euo pipefail

REPO="/Users/abdoul/development/appbiz-studio/faithlock-seo"
APP="$REPO/apps/faithlock-seo"
TRACKER="$APP/seo-content/index-tracker.csv"
LOGDIR="$APP/seo-content/index-logs"
TODAY=$(date +%Y-%m-%d)
LOG="$LOGDIR/$TODAY.log"

mkdir -p "$LOGDIR"
exec >>"$LOG" 2>&1
echo "=== $(date '+%Y-%m-%d %H:%M:%S') démarrage ==="

cd "$REPO"

# 1. Vérifie l'état d'indexation du lot de la veille et met à jour le CSV.
python3 "$APP/scripts/check-indexation.py" --tracker "$TRACKER" || echo "check-indexation a échoué, on continue"

# 2. Prépare le lot du jour : les 10 prochaines URLs non encore soumises.
python3 - "$TRACKER" "$TODAY" <<'PY'
import csv, sys
tracker, today = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(tracker)))
todo = [r for r in rows if r.get("soumis_gsc", "").strip() == ""][:10]
if not todo:
    print("aucune URL en attente, le suivi est à jour")
    raise SystemExit
print(f"LOT DU JOUR ({len(todo)} URLs) à soumettre dans Search Console :")
for r in todo:
    print("  " + r["url"])
out = tracker.replace(".csv", f"-batch-{today}.txt")
open(out, "w").write("\n".join(r["url"] for r in todo) + "\n")
print(f"liste écrite dans {out}")
PY

# 3. Commit du suivi mis à jour, pour que l'état vive dans git et pas sur ce Mac.
if ! git -C "$REPO" diff --quiet -- "$TRACKER" 2>/dev/null; then
    git -C "$REPO" add "$TRACKER"
    git -C "$REPO" commit -m "Update indexation tracker ($TODAY)" >/dev/null
    echo "suivi commité"
else
    echo "suivi inchangé, rien à commiter"
fi

echo "=== terminé ==="
