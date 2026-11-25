#!/bin/bash
# Installe (ou retire) la tâche quotidienne d'indexation via launchd.
#
#   ./scripts/install-index-cron.sh            installe, exécution chaque nuit à 00:00
#   ./scripts/install-index-cron.sh --uninstall retire la tâche
#   ./scripts/install-index-cron.sh --run       exécute une fois, tout de suite
#
# launchd plutôt que crontab : sur macOS, crontab ne se déclenche pas si la
# machine dort à l'heure prévue, alors que launchd rattrape la tâche au réveil.

set -euo pipefail

LABEL="dev.abdoul.faithlock.indexbatch"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
APP="/Users/abdoul/development/appbiz-studio/faithlock-seo/apps/faithlock-seo"
SCRIPT="$APP/scripts/daily-index-batch.sh"

case "${1:-}" in
  --uninstall)
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    rm -f "$PLIST"
    echo "tâche retirée"
    exit 0
    ;;
  --run)
    exec bash "$SCRIPT"
    ;;
esac

chmod +x "$SCRIPT"
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key><integer>0</integer>
        <key>Minute</key><integer>0</integer>
    </dict>
    <key>StandardOutPath</key><string>$APP/seo-content/index-logs/launchd.out.log</string>
    <key>StandardErrorPath</key><string>$APP/seo-content/index-logs/launchd.err.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLISTEOF

mkdir -p "$APP/seo-content/index-logs"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "tâche installée : $LABEL"
echo "exécution chaque nuit à 00:00"
echo "vérifier   : launchctl list | grep faithlock"
echo "lancer     : $0 --run"
echo "désinstaller: $0 --uninstall"
