#!/usr/bin/env python3
"""Construit le suivi d'indexation : les nouvelles pages en lots de 10 par jour.

Usage :
    python3 scripts/build-index-tracker.py            # (re)génère le suivi
    python3 scripts/build-index-tracker.py --start 2026-08-18   # date de départ

Le fichier produit est seo-content/index-tracker.csv. Il est fait pour être
relu et complété par check-indexation.py, qui remplit la colonne `indexed`
depuis Search Console sans écraser les colonnes tenues à la main.
"""
import csv, os, re, subprocess, sys, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGES = os.path.join(ROOT, "seo-content", "new-pages")
OUT = os.path.join(ROOT, "seo-content", "index-tracker.csv")
BASE = "https://www.getfaithlock.com/resources/"
PER_DAY = 10

# Ordre de publication : le commercial d'abord, il convertit et il est le plus
# dur à faire indexer ; les pages de volume pur passent en dernier.
PRIORITY = [
    ("commercial", r"^(reviews|comparisons|content-blocking)/|^(best-|apps-that-|screen-time-management|brick-app-blocker|opal-screen-time|freedom-app-blocker)"),
    ("outils",     r"^(how-to-block|platform-guides)/|widget|wallpaper|screensaver|lock-screen|home-screen|daily-bible-verse-app|bible-app-with"),
    ("addiction",  r"^addiction-guides/"),
    ("niche",      r"^(catholic|bible-study)/"),
    ("audience",   r"^(audience-guides|devotionals)/"),
    ("scripture",  r"^(bible-verses|prayers)/"),
]
PRIORITY = [(n, re.compile(p)) for n, p in PRIORITY]

def tier(rel):
    for i, (name, rx) in enumerate(PRIORITY):
        if rx.search(rel):
            return i, name
    return len(PRIORITY), "autre"

def new_pages():
    """Les pages ajoutées sur la branche seo par rapport à main."""
    try:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", "--diff-filter=A", "main..seo",
             "--", "apps/faithlock-seo/seo-content/new-pages"],
            cwd=os.path.dirname(os.path.dirname(ROOT)), text=True)
    except subprocess.CalledProcessError:
        print("git diff a échoué, repli sur tous les fichiers du dossier", file=sys.stderr)
        out = ""
    rels = [l.split("new-pages/", 1)[1] for l in out.splitlines() if l.strip()]
    if not rels:
        for dirpath, _, files in os.walk(PAGES):
            for f in files:
                if f.endswith(".md"):
                    rels.append(os.path.relpath(os.path.join(dirpath, f), PAGES))
    return sorted(set(rels))

def slug_of(rel):
    p = os.path.join(PAGES, rel)
    try:
        m = re.search(r"^slug:\s*(\S+)", open(p).read(), re.M)
        if m:
            return m.group(1).strip().strip('"').strip("'")
    except OSError:
        pass
    return os.path.basename(rel)[:-3]

def main():
    start = datetime.date.today()
    if "--start" in sys.argv:
        start = datetime.date.fromisoformat(sys.argv[sys.argv.index("--start") + 1])

    rows = []
    for rel in new_pages():
        t, tname = tier(rel)
        rows.append({"tier": t, "cluster": tname, "rel": rel, "slug": slug_of(rel)})
    rows.sort(key=lambda r: (r["tier"], r["rel"]))

    # état déjà saisi à la main, à préserver
    prev = {}
    if os.path.exists(OUT):
        for r in csv.DictReader(open(OUT)):
            prev[r["url"]] = r

    out = []
    for i, r in enumerate(rows):
        day = i // PER_DAY
        date = start + datetime.timedelta(days=day)
        url = BASE + r["slug"]
        old = prev.get(url, {})
        out.append({
            "batch": f"J{day+1:02d}",
            "date_prevue": date.isoformat(),
            "cluster": r["cluster"],
            "slug": r["slug"],
            "url": url,
            "publie": old.get("publie", ""),
            "soumis_gsc": old.get("soumis_gsc", ""),
            "indexed": old.get("indexed", "?"),
            "date_check": old.get("date_check", ""),
            "impressions": old.get("impressions", ""),
            "position": old.get("position", ""),
            "notes": old.get("notes", ""),
        })

    with open(OUT, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        w.writerows(out)

    days = (len(out) + PER_DAY - 1) // PER_DAY
    print(f"{len(out)} pages -> {days} lots de {PER_DAY} -> {OUT}")
    print(f"du {out[0]['date_prevue']} au {out[-1]['date_prevue']}")
    from collections import Counter
    for c, n in Counter(r["cluster"] for r in out).most_common():
        print(f"  {c:<12} {n}")

if __name__ == "__main__":
    main()
