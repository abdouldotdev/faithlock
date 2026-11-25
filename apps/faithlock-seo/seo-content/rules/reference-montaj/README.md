# SEO — dossier de pilotage & rédaction

Tout le SEO programmatique de Montaj vit ici. Ordre de lecture pour rédiger une page :

1. **`../CLAUDE.md`** (racine) — règles non-négociables (chargées en mémoire) : anglais only, §12, cohérence des chiffres, pas d'« iPhone » en positionnement, keyword-slots.
2. **`rules/CONTENT_WRITING_RULES.md`** — le process de rédaction + le système de cohérence des données (prévenir avec `competitors.ts`/`montaj-facts.ts` + détecter avec l'agent fact-check).
3. **`rules/CONTENT_FORMAT_RULES.md`** — les règles du format de la page (anatomie, mots-clés + sous-mots-clés, ingrédients, scorecard Definition of Done).
4. **`plan/content-pipeline.xlsx`** — la liste des ~197 pages (export Notion) : format, mot-clé, volume/KD, priorité, step, URL, killer element. C'est le quoi/dans quel ordre.
5. **`../MONTAJ.md` §12** — les faits produit autorisés.

## Structure
```
seo/
├── README.md                     ← ce fichier (index)
├── rules/
│   ├── CONTENT_WRITING_RULES.md   process + cohérence data
│   ├── CONTENT_FORMAT_RULES.md    règles des 6 formats + scorecards
│   └── FIX_ENGLISH_TOOLS.md       brief : passer les pages outils en EN
├── plan/
│   ├── MASTER_PAGES_PLAN.md        les tiers (d'où viennent les centaines)
│   ├── SEO_CALENDAR.md             cadence de publication
│   └── content-pipeline.xlsx       les 197 pages (export Notion)
└── pilot/                         les 10 pages étalon (à rédiger en premier)
```

## Workflow de rédaction (résumé)
Pour chaque page : lire son entrée dans `content-pipeline.xlsx` → charger la fiche de son format (`CONTENT_FORMAT_RULES.md`) → piocher les faits dans `content/competitors.ts` / `content/montaj-facts.ts` (jamais inventer) → rédiger (keyword-slots + sous-mots-clés + schema + CTA `ct=`) → auto-scorecard ≥ 80 → agent fact-check (0 flag) → `Step = 7. Publié`.

## Pilote
Les 10 pages étalon (couvrant chaque format) sont dans `pilot/`. On valide la qualité dessus AVANT d'industrialiser les ~190 restantes via Claude Code.
