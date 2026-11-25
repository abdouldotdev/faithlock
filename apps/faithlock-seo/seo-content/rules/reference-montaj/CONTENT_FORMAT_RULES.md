# Montaj — Règles par format (à lire avant de rédiger une page)

*Complète `CLAUDE.md` (non-négociables) et `CONTENT_WRITING_RULES.md` (process + cohérence data). Ici : la structure, les mots-clés, les ingrédients et la scorecard de CHAQUE format. Lire la section du format de la page à rédiger.*

Rappels transverses (voir CLAUDE.md) : EN only · §12 bloquant · pas de « iPhone » en positionnement · keyword exact 4-6× aux slots + sous-mots-clés en H2/FAQ · CTA avec `?ct={slug}` · tableau en HTML réel · FAQ + schema · breadcrumb + schema.

---

## 1. COMPARATIF — `/alternatives/[brand]` et `/vs/[a]-vs-[b]`

**Anatomie** : Header + smart banner → Hero (H1 = requête + angle on-device + CTA) → Verdict TL;DR (choose X if / choose Montaj if) → **Tableau comparatif** (ligne 1 = « Where your video goes → Nowhere ») → 3 blocs détaillés (avec « Winner: » par section) → mini-FAQ (schema) → maillage vers pages sœurs → CTA final.

**Keywords** : principal = la paire/marque exacte (`capcut alternative`, `inshot vs capcut`). Variante inverse en H2 (`capcut vs inshot`). Modificateurs : `free`, `which is better`, `for tiktok`. Sous : features comparées (subtitles, silence removal, on-device, price).

**Ingrédients de persuasion** : tableau dont on écrit les 2 colonnes (✓ Montaj / ◐ concurrent) · ligne 1 = axe on-device qu'on gagne contre tous · **concéder honnêtement** ce qu'on n'a pas (Android/desktop, templates) = crédibilité · « Winner » par section · mantra d'ancrage répété ×4 (« never leaves your device ») · preuve sociale si dispo. Biais = choix des axes, jamais mensonge.
Paires tierces (`/vs/x-vs-y` sans Montaj) : Montaj = **arbitre / 3ᵉ option, CTA doux** (pas d'install forcé).

**Definition of Done (≥ 80/100)** : SEO/50 (keyword title+H1+meta 15 · variantes H2 5 · phrase exacte 4-6× 5 · FAQ verbatim+schema 5 · tableau HTML 5 · breadcrumb+schema 3 · maillage ≥3 3 · alt 2 · slug+date 2) · Conversion/50 (ligne 1 on-device 10 · killer sans scroll 8 · Winner/section 6 · concessions honnêtes 6 · mantra ×4 5 · TL;DR 5 · CTA×3 +ct= 7 · preuve sociale 3). **§12 bloquant** : pas de templates/4K/publication/autonome ; captures livrées ; pas de « for pc/android ».

---

## 2. OUTIL GRATUIT — `/tools/[tool]` (+ `/tools/[tool]/[platform]`)

**Anatomie** : Hero (H1 = requête, mini-outil visible tout de suite) → zone outil (dépose vidéo → résultat) = donnée unique → « How it works » (3 étapes) → « Why Montaj » (on-device, no upload) → cas d'usage par plateforme → FAQ + CTA download.

**Keywords** : principal exact (`video to text`, `subtitle generator`, `resize video`, `video resizer`). Sous : ai/auto/free/online + variantes (`video transcript generator`, `audio to text`…). Combinatoire par plateforme.

**Ingrédients** : utilité immédiate = aimant à backlinks · angle **on-device / sans upload** en avant (personne d'autre) · CTA download **après** le résultat. 100% navigateur (ffmpeg.wasm / Whisper / rnnoise).

**Definition of Done (≥ 80/100)** : SEO/50 (keyword title+H1+meta 15 · variantes H2 5 · H2 How it works + Why Montaj 5 · FAQ+schema 5 · schema SoftwareApplication 5 · breadcrumb 3 · maillage 3 · alt 2 · slug+date 2) · Conversion/50 (**résultat réel immédiat** — sinon 0 — 15 · angle on-device 10 · CTA après résultat +ct= 10 · asset linkable 8 · killer sans scroll 7). **§12** : ne promet que sous-titres/transcription/silences/débruitage/recadrage 9:16/découpe/texte. Pas de 4K/templates/publication.

---

## 3. LISTICLE — `/best/[usage]`

**Anatomie** : Intro (critères de sélection = crédibilité) → classement (Montaj en tête MAIS cite honnêtement les autres) → mini-fiche par outil → tableau récap → FAQ + CTA.

**Keywords** : principal `best [X]` (best ai video editor, best capcut alternatives). Sous : top/free/2026/for tiktok + noms des outils listés.

**Ingrédients** : **méthodologie affichée** (sinon = thin content) · se classer en citant les concurrents (paraît objectif) · angle on-device de Montaj mis en avant dans sa fiche · MAJ régulière (année dans le title). C'est ICI qu'on « range » les marques à faible volume (inshot, kinemaster, klap…) — une mention, pas une page dédiée.

**Definition of Done (≥ 80/100)** : SEO/50 (keyword « best [X] » 15 · chaque item H2/H3 10 · tableau récap 7 · FAQ+schema 5 · breadcrumb/ItemList 5 · maillage 3 · alt+slug+date 5) · Conversion/50 (méthodologie affichée 12 · Montaj en tête + concurrents cités 12 · critères objectifs 8 · angle on-device 8 · CTA +ct= 10). **§12** : fiche Montaj = livré uniquement.

---

## 4. HOW-TO — `/blog/how-to-[action]-[context]`

**Anatomie** : H1 = « How to [task] [context] » → réponse rapide (featured snippet) → **étapes numérotées avec captures réelles** (donnée unique) → astuce « do it automatically in Montaj » → FAQ + CTA.

**Keywords** : principal = la requête exacte (`how to trim a video`, `how to add subtitles to a tiktok`). Sous : variantes de la question. Le mot-clé « on iphone » vit dans une **FAQ** (règle CLAUDE.md), pas le H1.

**Ingrédients** : procédure réelle par contexte = évite le thin content (modèle ReSubs) · pattern combinatoire [action] × [contexte] · insertion douce de Montaj (« the easiest way… »), pas agressif.

**Definition of Done (≥ 80/100)** : SEO/50 (keyword title+H1+meta 15 · **schema HowTo** 10 · réponse rapide en haut 7 · FAQ+schema 5 · breadcrumb 3 · maillage tools/comparatifs 5 · alt+slug+date 5) · Conversion/50 (procédure réelle + captures 15 · insertion douce Montaj 10 · astuce « auto in Montaj » 10 · CTA +ct= 15). **§12** : étapes = vrai parcours, aucune fonction non livrée.

---

## 5. ON-DEVICE / PRIVÉ — `/[angle]` (private-video-editor, offline-video-editor, no-watermark)

**Anatomie** : Hero (« Edit without your video ever leaving your device ») → le problème (RGPD, contenu sensible) → comment Montaj le résout (on-device, hors ligne, zéro upload) → preuves techniques (Whisper + DeepFilterNet on-device) → CTA.

**Keywords** : principal (`private video editor`, `offline video editor`, `video editor without watermark`). Sous : no-upload / edit video without uploading / secure.

**Ingrédients** : on gagne cet axe contre TOUS (Captions/Submagic/CapCut = cloud) · cible verticale (avocat, coach, RH) → pages `/solutions/` possibles · ton sérieux, pas « viral ».

**Definition of Done (≥ 80/100)** : SEO/50 (keyword exact 15 · variantes H2 8 · FAQ+schema 7 · breadcrumb 5 · maillage 5 · alt+slug+date 10) · Conversion/50 (problème confidentialité posé 12 · preuve technique on-device 12 · cible verticale nommée 8 · ton pro 8 · CTA +ct= 10). **§12** : on-device = livré, rester **factuel** sur le RGPD (pas de certification non prouvée).

---

## 6. HUB / ANNUAIRE — `/comparisons` (index) + `/apps/[brand]`

**Anatomie** : `/comparisons` = index maillé de toutes les paires. `/apps/[brand]` = fiche profil concurrent (note, pricing qualitatif, features Yes/No, avis sourcés, pros/cons) → CTA « Montaj is a better alternative » + liens vers 10-20 pages `/vs`.

**Ingrédients** : features Yes/No (biais par le choix des lignes) · avis négatifs concurrents **avec source** · notes affichées quand ça nous avantage · maillage descendant massif (chaque fiche → dizaines de /vs) = autorité thématique (modèle Submagic).

**Definition of Done (≥ 80/100)** : SEO/50 (index structuré 10 · fiches liées 10 · ancres riches 10 · maillage descendant 10 · breadcrumb 5 · slugs 5) · Conversion/50 (CTA « better alternative » 12 · tableau Yes/No 10 · avis sourcés 8 · note si avantage 5 · CTA +ct= 15). **§12** : jamais de fausse limite inventée ; avis réels + sourcés ; features Montaj livrées.
