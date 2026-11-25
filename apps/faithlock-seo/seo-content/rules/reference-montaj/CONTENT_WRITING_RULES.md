# Montaj — Règles de rédaction & cohérence des données (master brief)

*Brief que Claude Code + ses agents rédacteurs DOIVENT suivre. Objectif : contenu qui convertit ET dont chaque chiffre/fait est vérifiable. Un chiffre faux sur une page = perte de confiance + risque (reviewer App Store, concurrent, presse).*

---

## 0. Les 2 sources de vérité (ne jamais mélanger)

Toute affirmation factuelle appartient à l'une des deux catégories :

**A. Données Montaj** (nos features, on-device, prix, formats, plateformes)
→ Source unique : **`MONTAJ.md` §12** (statuts LIVRÉ / PARTIEL / CONÇU / INTERDIT).
→ Règle : on ne communique QUE sur `✅ LIVRÉ`. Jamais montage autonome, templates, publication, 4K, musique. Le « conçu » se raconte au futur.

**B. Données externes** (concurrents : prix, features, propriété ; stats de marché ; specs techniques)
→ Source : **vérifiable en ligne, datée, citée** — ou pas affirmée du tout.
→ Règle : jamais de chiffre inventé. Si non vérifiable aujourd'hui, on ne l'écrit pas.

---

## 1. Architecture anti-erreur : PRÉVENIR puis DÉTECTER (les deux)

Scanner après coup ne suffit pas à l'échelle. On combine :

### 1.1 PRÉVENIR — couche de faits vérifiés (les agents ne réinventent pas)
Les faits ne vivent PAS en texte libre dans chaque page. Ils vivent dans **une couche de données centrale, relue une fois** :
- `content/competitors.ts` — par concurrent : `name`, `owner`, `hosting` (cloud/desktop/on-device), `platforms`, `pricingModel` (qualitatif : "free tier + paid", pas un prix figé), `keyFeatures[]`, `montajAngle`. **Toutes** les pages (`/alternatives/*`, `/vs/*`, `/apps/*`) lisent ce fichier → un concurrent est décrit **identiquement partout** = cohérence par construction.
- `content/montaj-facts.ts` — nos features LIVRÉES + claims autorisés, dérivé de MONTAJ.md §12. Les pages piochent ici, jamais dans l'imagination de l'agent.
- **Les agents rédigent la PROSE autour de ces points vérifiés. Ils n'inventent aucun fait.** Un fait qui n'est pas dans la couche de données ne va pas sur la page.

### 1.2 DÉTECTER — agent scanner de fact-check (gate avant publication)
Après rédaction, un **agent vérificateur** relit chaque page et :
1. Extrait TOUTE affirmation factuelle (chiffre, prix, feature concurrent, propriété, stat, claim Montaj).
2. Classe A (Montaj) ou B (externe).
3. Vérifie : A → contre `MONTAJ.md` §12 ; B → web search + source datée.
4. **Flag** tout ce qui est non sourcé, faux, ou §12-interdit.
5. **Aucune page ne passe en « Publié » avec un flag ouvert.**

---

## 2. Règles de cohérence des chiffres (dures)

1. **Zéro chiffre inventé.** Chaque nombre a une source (MONTAJ.md, ou URL datée).
2. **Prix concurrents : éviter les montants figés.** Ils changent → qualitatif (« has a free tier; paid plans for pro features ») plutôt que « $19/mo ». Si un prix est cité, il porte une date et une source, et est marqué à re-vérifier.
3. **Nos volumes de recherche / KD / data DataForSEO = INTERNES.** Jamais dans la copie publique.
4. **Stats de marché** (« 90% watch muted », « X spend $Y ») : uniquement avec source réelle citée. Sinon reformuler sans chiffre.
5. **Features concurrents** : uniquement ce qui est dans `competitors.ts` (vérifié). Ne jamais affirmer une limite fausse d'un concurrent (biais = choix des axes, pas mensonge).
6. **Avis négatifs concurrents** : réels + sourcés (G2/Trustpilot), jamais fabriqués.
7. **Cohérence croisée** : le même fait doit être identique sur toutes les pages (garanti par la couche de données §1.1).

---

## 3. Process de rédaction par page (chaque agent)

1. **Lire le brief de la page** dans Notion (Content Pipeline) : format, mot-clé principal + sous-mots-clés, killer element, URL.
2. **Charger la structure du format** (Notion Formats & Structures) + la scorecard.
3. **Piocher les faits** dans `competitors.ts` / `montaj-facts.ts` (jamais inventer).
4. **Rédiger** en suivant : keyword aux slots (title/H1/1 H2/1 FAQ/CTA, 4-6×), sous-mots-clés foldés en H2/FAQ, ligne 1 du tableau = on-device, concessions honnêtes, FAQ verbatim + schema, CTA `ct=` par page, maillage ancres exactes.
5. **Signer la page** — signature auteur en tête + verdict en pied (§3.1, obligatoire).
6. **Auto-scorecard** (≥ 80/100, §12 bloquant).
7. **Passer à l'agent fact-check** → si flags, corriger → sinon « prêt ».

---

## 3.1 Signature humaine & verdict (obligatoire sur toute page de contenu)

Une page de contenu sans auteur identifiable et sans avis tranché se lit comme
du texte généré — pour un lecteur comme pour un moteur. Deux blocs, tous les
deux rendus par du code, jamais écrits à la main dans le corps :

**a. Signature — `<AuthorByline />`**, juste sous le H1.
Rend « Written by *Nom*, *titre* » + la bio + un JSON-LD `Person`.
- L'auteur vient de **`content/authors.ts`** : `author: <id>` en frontmatter,
  ou l'auteur par défaut si le champ est absent.
- ⛔️ **Un auteur doit être une personne réelle**, avec un titre exact et, idéalement,
  une `url` publique (profil, page équipe) qui alimente le `sameAs`. **Inventer
  une signature** (« Sarah Miller, professional video editor ») est une fausse
  attribution : ça trompe le lecteur, et Google traite une Person sans aucune
  empreinte vérifiable comme un signal E-E-A-T frauduleux. Si personne de réel
  ne peut signer, on n'affiche pas de signature — on ne fabrique pas d'auteur.
- Renseigner `updated:` dès qu'une page est révisée (la date de révision est un
  signal de fraîcheur, et elle doit être vraie).

**a-bis. Répartition des auteurs entre les pages d'un cluster.**
Plusieurs relecteurs couvrent le même cluster. Une page qui ne déclare pas
`author:` reçoit le sien via `resolveAuthorId(explicit, slug, zone)`
(`content/authors.ts`), qui répartit les pages entre les auteurs dont le champ
`zones` contient ce cluster.

- ⛔️ **Le tirage est DÉTERMINISTE, jamais `Math.random()`.** Il dérive d'un hash
  FNV-1a du slug, donc une URL affiche toujours le même nom, build après build.
  Un tirage aléatoire changerait la signature à chaque déploiement : incohérent
  pour le lecteur qui revient, contradictoire avec le `Person` du JSON-LD, et
  illisible pour un moteur qui recroise auteur et contenu dans le temps.
- Le pool est trié par `id` : ajouter un auteur rebat les cartes de façon
  reproductible, sans dépendre de l'ordre d'écriture dans le registre.
- **Un `author:` explicite l'emporte toujours.** Une page réellement écrite par
  quelqu'un de précis le déclare et sort de la répartition.
- ⛔️ **La répartition suppose que chaque relecteur couvre vraiment son `zones`.**
  Elle répartit une charge de relecture réelle, elle ne fabrique pas une
  paternité : n'inscrire un cluster dans `zones` que si la personne y intervient
  effectivement. Un nom réel posé sur des pages jamais relues est une fausse
  attribution au même titre qu'un auteur inventé, avec en plus l'identité d'un
  tiers engagée.
- `verified: false` retire la personne de tous les pools et n'affiche aucune
  signature : une fiche incomplète ne doit jamais atteindre une page indexable.

**b. Verdict — `<Verdict />`**, avant le CTA final.
Champ `verdict:` en frontmatter (blog) ou `verdict` dans le data file
(`competitors.ts`, `comparisons.ts`, `listicles.ts`).
- **2 à 4 phrases, à la première personne**, qui **tranchent** : « pour tel
  usage, prends tel outil ».
- **La recommandation doit pouvoir ne pas être Montaj.** Un verdict qui conclut
  sur Montaj à chaque page n'est pas un avis, c'est un slogan répété : il
  détruit la crédibilité de la page et duplique le même bloc sur tout le site.
  Sur les pages où Montaj ne fait pas l'action (cf. les 5 how-to à concession),
  le verdict dit explicitement quoi utiliser à la place.
- **Aucun fait nouveau** : le verdict conclut sur ce que la page a déjà établi
  et sourcé, il n'introduit ni chiffre ni claim supplémentaire (§12 s'applique).
- **Unique à la page** — deux verdicts interchangeables = du find-replace, donc
  un échec du gate G4.
- Pas de verdict honnête à écrire ? On n'en met pas. Mieux vaut l'absence qu'une
  conclusion creuse.

---

## 4. Pilote : 10 pages d'abord (le calibre qualité)

Choisir 10 pages représentatives des formats (pas 10 how-to identiques) :
- 2 alternatives : `/alternatives/capcut`, `/alternatives/canva`
- 2 vs : `/vs/inshot-vs-capcut`, `/vs/opus-clip-vs-capcut`
- 1 listicle : `/best-ai-video-editors`
- 3 how-to : `/blog/how-to-trim-a-video-on-iphone`, `/blog/how-to-crop-a-video-on-iphone`, `/blog/how-to-add-text-to-a-video`
- 2 outils (copy) : `/tools/video-to-text`, `/tools/resize-video`

→ Ces 10 valident : chaque format, la couche de données, et le gate fact-check. On mesure la qualité, on ajuste les règles, PUIS on industrialise.

---

## 5. Spec de l'agent fact-check (scanner)

**Input** : une page rédigée (draft).
**Fait** :
- Liste toutes les affirmations factuelles avec leur type (A/B).
- A (Montaj) → vérifie contre `MONTAJ.md §12`. Flag si non-LIVRÉ affirmé au présent.
- B (externe) → web search, exige une source datée. Flag si non trouvable / contradictoire.
- Vérifie : aucun volume/KD interne exposé ; aucun prix figé non sourcé ; avis concurrents sourcés.
**Output** : rapport `{claim, type, verdict: ok/flag, source, fix suggéré}`. Une page avec ≥ 1 flag ne publie pas.

---

## 6. Garde-fous §12 (rappel — bloquant)

Ne JAMAIS affirmer, sur aucune page : montage autonome, « choisir un template », publication/programmation réseaux, B-roll IA, tout prix/plan Pro, zoom automatique, 4K, multilingue de transcription, bibliothèque de sons, « testé/prêt production ». Captures = fonctions livrées uniquement. Le « conçu » (templates éditables, mouvement au doigt) = au futur, jamais au présent.
