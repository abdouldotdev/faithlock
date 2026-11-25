#!/usr/bin/env python3
"""Met à jour la colonne `indexed` du suivi depuis l'API Search Console.

Lecture seule côté Google : on interroge urlInspection.index.inspect, qui est
l'API officielle et ne consomme pas le quota de demande d'indexation.

Usage :
    python3 scripts/check-indexation.py --tracker seo-content/index-tracker.csv
    python3 scripts/check-indexation.py --tracker ... --limit 50

Authentification : réutilise les identifiants du serveur MCP gsc s'ils sont
présents (GOOGLE_APPLICATION_CREDENTIALS ou un client OAuth déjà autorisé).
Sans identifiants, le script sort proprement en le signalant plutôt que
d'échouer bruyamment dans le cron.
"""
import argparse, csv, datetime, json, os, sys, urllib.request, urllib.error

SITE = "sc-domain:getfaithlock.com"
API = "https://searchconsole.googleapis.com/v1/urlInspection/index:inspect"

VERDICT = {
    "Submitted and indexed": "oui",
    "Indexed, not submitted in sitemap": "oui",
    "URL is unknown to Google": "inconnue",
    "Crawled - currently not indexed": "exploree-non-indexee",
    "Discovered - currently not indexed": "decouverte-non-exploree",
    "Page with redirect": "redirection",
    "Duplicate, Google chose different canonical than user": "doublon-canonique",
}


def token():
    """Jeton d'accès, via compte de service si disponible."""
    cred = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred or not os.path.exists(cred):
        return None
    try:
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
        creds = service_account.Credentials.from_service_account_file(
            cred, scopes=["https://www.googleapis.com/auth/webmasters.readonly"])
        creds.refresh(Request())
        return creds.token
    except Exception as e:
        print(f"auth impossible : {e}", file=sys.stderr)
        return None


def inspect(url, tok):
    body = json.dumps({"inspectionUrl": url, "siteUrl": SITE}).encode()
    req = urllib.request.Request(API, data=body, headers={
        "Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            d = json.load(r)
        return (d.get("inspectionResult", {})
                 .get("indexStatusResult", {})
                 .get("coverageState", ""))
    except urllib.error.HTTPError as e:
        return f"erreur-http-{e.code}"
    except Exception as e:
        return f"erreur-{type(e).__name__}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tracker", required=True)
    ap.add_argument("--limit", type=int, default=40,
                    help="nombre d'URLs à vérifier par passage")
    args = ap.parse_args()

    tok = token()
    if not tok:
        print("aucun identifiant Search Console : vérification sautée.")
        print("Renseigne GOOGLE_APPLICATION_CREDENTIALS avec un compte de service "
              "ayant accès à la propriété, ou lance la vérification depuis Claude "
              "Code, qui utilise le serveur MCP gsc déjà authentifié.")
        return 0

    rows = list(csv.DictReader(open(args.tracker)))
    today = datetime.date.today().isoformat()

    # On vérifie en priorité ce qui a été soumis et jamais confirmé.
    todo = [r for r in rows
            if r.get("soumis_gsc", "").strip()
            and r.get("indexed", "?") not in ("oui",)][:args.limit]

    checked = 0
    for r in todo:
        state = inspect(r["url"], tok)
        r["indexed"] = VERDICT.get(state, state or "?")
        r["date_check"] = today
        checked += 1
        print(f'  {r["indexed"]:<24} {r["url"]}')

    if checked:
        with open(args.tracker, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
    print(f"{checked} URLs vérifiées")
    return 0


if __name__ == "__main__":
    sys.exit(main())
