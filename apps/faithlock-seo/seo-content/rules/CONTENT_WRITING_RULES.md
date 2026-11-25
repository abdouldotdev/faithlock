# FaithLock — Règles de rédaction & cohérence des données (master brief)

*Brief que tout agent rédacteur DOIT suivre. Objectif : contenu qui convertit ET dont chaque chiffre/fait est vérifiable. Un chiffre faux sur une page = perte de confiance + risque (reviewer App Store, concurrent, presse). Adapté du système Montaj (`montaj/website/seo/rules/`), qui a fait ses preuves.*

---

## 0. Les 2 sources de vérité (ne jamais mélanger)

Toute affirmation factuelle appartient à l'une des deux catégories :

**A. Données FaithLock** (nos features, prix, plateformes, mécanique de blocage)
→ Source unique : **`FAITHLOCK_FACTS.md`** (statuts LIVRÉ / PARTIEL / CONÇU / INTERDIT).
→ Règle : on ne communique QUE sur `✅ LIVRÉ`. Le « conçu » se raconte au futur, jamais au présent.

**B. Données externes** (concurrents : prix, features, propriété ; stats de marché ; versets et références bibliques ; specs iOS/Android)
→ Source : **vérifiable en ligne, datée, citée**, ou pas affirmée du tout.
→ Règle : jamais de chiffre inventé. Si non vérifiable aujourd'hui, on ne l'écrit pas.
→ Cas particulier versets : toujours donner la référence exacte (livre chapitre:verset) et la traduction utilisée (NIV, ESV, KJV…). Jamais de verset approximatif ou paraphrasé présenté comme citation.

---

## 1. Architecture anti-erreur : PRÉVENIR puis DÉTECTER (les deux)

Scanner après coup ne suffit pas à l'échelle. On combine :

### 1.1 PRÉVENIR — couche de faits vérifiés (les agents ne réinventent pas)
Les faits ne vivent PAS en texte libre dans chaque page. Ils vivent dans **une couche de données centrale, relue une fois** :
- `COMPETITOR_FACTS.md` (à créer/maintenir dans ce dossier) — par concurrent (Opal, Brick, ScreenZen, one sec, Freedom, Cold Turkey, Forest, Flora, Prayer Lock, Bible Mode, Pray Screen Time, Holy Focus, Covenant Eyes, Bark, Canopy, Truple, Accountable2You…) : `name`, `owner`, `platforms`, `pricingModel` (qualitatif : « free tier + paid », pas un prix figé), `mécanique de blocage`, `keyFeatures[]`, `faithlockAngle`. **Toutes** les pages (comparisons, reviews, listicles) lisent cette couche → un concurrent est décrit **identiquement partout** = cohérence par construction.
- `FAITHLOCK_FACTS.md` — nos features LIVRÉES + claims autorisés. Les pages piochent ici, jamais dans l'imagination de l'agent.
- **Les agents rédigent la PROSE autour de ces points vérifiés. Ils n'inventent aucun fait.** Un fait qui n'est pas dans la couche de données ne va pas sur la page.

### 1.2 DÉTECTER — agent scanner de fact-check (gate avant publication)
Après rédaction, un **agent vérificateur** relit chaque page et :
1. Extrait TOUTE affirmation factuelle (chiffre, prix, feature concurrent, propriété, stat, référence biblique, claim FaithLock).
2. Classe A (FaithLock) ou B (externe).
3. Vérifie : A → contre `FAITHLOCK_FACTS.md` ; B → web search + source datée ; versets → référence + traduction exactes.
4. **Flag** tout ce qui est non sourcé, faux, ou interdit.
5. **Aucune page ne passe en « Publié » avec un flag ouvert.**

---

## 2. Règles de cohérence des chiffres (dures)

1. **Zéro chiffre inventé.** Chaque nombre a une source (FAITHLOCK_FACTS.md, ou URL datée).
2. **Prix concurrents : éviter les montants figés.** Ils changent → qualitatif (« has a free tier; paid plans for full blocking ») plutôt que « $6.99/mo ». Si un prix est cité, il porte une date et une source, et est marqué à re-vérifier.
3. **Nos volumes de recherche / KD / données GSC et DataForSEO = INTERNES.** Jamais dans la copie publique.
4. **Stats de marché** (« 57% of Americans feel addicted », temps d'écran moyen…) : uniquement avec source réelle citée. Sinon reformuler sans chiffre.
5. **Features concurrents** : uniquement ce qui est dans `COMPETITOR_FACTS.md` (vérifié). Ne jamais affirmer une limite fausse d'un concurrent (le biais = le choix des axes de comparaison, jamais le mensonge).
6. **Avis négatifs concurrents** : réels + sourcés (App Store reviews, Trustpilot), jamais fabriqués.
7. **Cohérence croisée** : le même fait doit être identique sur toutes les pages (garanti par la couche de données §1.1).
8. **Références bibliques** : livre chapitre:verset + traduction, systématiquement.

---

## 3. Process de rédaction par page (chaque agent)

1. **Lire le brief de la page** (liste batch : format, mot-clé principal + sous-mots-clés, killer element, slug).
2. **Charger la fiche du format** (`CONTENT_FORMAT_RULES.md`) + sa scorecard.
3. **Piocher les faits** dans `COMPETITOR_FACTS.md` / `FAITHLOCK_FACTS.md` (jamais inventer).
4. **Rédiger** en suivant : keyword aux slots (title / H1 / 1 H2 / 1 FAQ / CTA, 4-6× dans le corps), sous-mots-clés foldés en H2/FAQ, tableau en markdown/HTML réel, concessions honnêtes, FAQ verbatim des requêtes réelles, CTA App Store (lien `https://pim.ms/kTxgKF4`), maillage interne ≥ 3 liens à ancres exactes. **Aucun lien vers un concurrent** (site, help center, blog, fiche App Store / Play Store d'une autre app) : on cite le nom en texte brut. Liste et garde-fou au rendu : `lib/competitors.ts`.
5. **Auto-scorecard** (≥ 80/100, claims interdits = bloquant).
6. **Passer à l'agent fact-check** → si flags, corriger → sinon « prêt ».

---

## 3.1 Style d'écriture (obligatoire, anti-détection « texte généré »)

- **⛔ Éviter au maximum les tirets cadratins « — » et doubles tirets « -- ».** C'est le signe le plus reconnaissable du texte généré. Reformuler avec une virgule, deux phrases, ou des parenthèses. Tolérance : zéro dans les titles/metas, exceptionnel dans le corps.
- Pas de « rule of three » systématique, pas de « In today's digital world », pas de « It's important to note », pas de négations parallèles (« not just X, but Y »).
- Phrases courtes, voix active, anglais US naturel. On écrit comme un humain qui a testé les apps, pas comme une brochure.
- Aucune mention d'IA, d'assistant ou d'outil de génération, nulle part (pages, commits, frontmatter).
- Superlatifs vides interdits (« amazing », « game-changer », « revolutionary »).

---

## 3.2 Signature humaine & verdict (sur toute page de contenu)

- **Un auteur doit être une personne réelle**, avec un titre exact et idéalement une URL publique. **Inventer une signature est une fausse attribution** : ça trompe le lecteur et Google traite une Person sans empreinte vérifiable comme un signal E-E-A-T frauduleux. Si personne de réel ne peut signer, pas de signature ; on ne fabrique pas d'auteur.
- Si un système de répartition d'auteurs existe, le tirage doit être **déterministe** (hash du slug), jamais aléatoire : une URL affiche toujours le même nom, build après build.
- **Verdict en fin de page : 2 à 4 phrases à la première personne qui tranchent** (« for this use case, pick X »). **La recommandation doit pouvoir ne pas être FaithLock** : un verdict qui conclut sur FaithLock à chaque page n'est pas un avis, c'est un slogan répété qui détruit la crédibilité. Aucun fait nouveau dans le verdict. Unique à la page : deux verdicts interchangeables = échec. Pas de verdict honnête à écrire ? On n'en met pas.
- Renseigner la date de mise à jour dès qu'une page est révisée, et elle doit être vraie.

---

## 4. Pilote avant industrialisation

Avant tout batch de masse : rédiger **10 pages étalon** couvrant chaque format du lot, les passer au fact-check et à la scorecard, mesurer, ajuster les règles, PUIS industrialiser le reste. On ne lance jamais 650 pages sur un template non validé.

---

## 5. Spec de l'agent fact-check (scanner)

**Input** : une page rédigée (draft).
**Fait** :
- Liste toutes les affirmations factuelles avec leur type (A/B).
- A (FaithLock) → vérifie contre `FAITHLOCK_FACTS.md`. Flag si non-LIVRÉ affirmé au présent.
- B (externe) → web search, exige une source datée. Flag si non trouvable ou contradictoire.
- Versets → vérifie référence + traduction.
- Vérifie : aucun volume/KD interne exposé ; aucun prix figé non sourcé ; avis concurrents sourcés ; zéro « — » dans title/meta.
**Output** : rapport `{claim, type, verdict: ok/flag, source, fix suggéré}`. Une page avec ≥ 1 flag ne publie pas.

---

## 6. Garde-fous claims FaithLock (bloquant)

Ne JAMAIS affirmer sur une page une feature FaithLock absente de `FAITHLOCK_FACTS.md` avec statut `✅ LIVRÉ`. En attendant que ce fichier soit rempli et validé par le fondateur, les seuls claims autorisés sont ceux déjà présents sur les pages publiées du site. Dans le doute : décrire le problème et la catégorie, pas la feature.

### 6.1 Pièges déjà attrapés par le fact-check (à relire avant chaque vague)

1. **Ne JAMAIS dire que FaithLock est gratuit, « at no cost », « without a subscription » ou « without paying »**, même en sous-entendu dans une comparaison de prix. Le modèle gratuit/premium est ❓ À CONFIRMER (bypass paywall non expliqué). Comparer les mécaniques (Bible quiz vs strict mode payant), jamais les prix côté FaithLock.
2. **Covenant Eyes sur iOS** : le VPN de filtrage agit sur TOUT l'appareil (niveau réseau) ; c'est la capture d'écran d'accountability qui est limitée à Safari. Ne jamais écrire « Safari-only VPN ».
3. **Ne pas combler les champs `unknown` de COMPETITOR_FACTS.md** dans les cellules de tableau : écrire « Not confirmed » plutôt qu'inventer un « Available ».
4. **Maillage interne : lier en `/resources/<slug>` directement**, jamais `/learn/` (redirection 308 = budget crawl gaspillé).
5. **« Version complète » d'une prière ou citation célèbre** : vérifier que l'extension est du même auteur que le noyau. Les versions longues les plus diffusées sont souvent des accrétions postérieures (ex. la version longue « Living one day at a time » de la Serenity Prayer vient des cercles AA, pas de Niebuhr). Même piège que les traductions de versets : la mémoire restitue la version populaire, pas la version étiquetée (ex. Psalm 118:24 : « This is the day the Lord has made » = KJV/NIV 1984, PAS le NIV actuel).
6. **Preuve sociale inventée** : ne JAMAIS écrire « several couples use it », « some people set it », « many users find » à propos de FaithLock. Aucune donnée d'usage n'est disponible. Décrire la capacité à la 2e personne (« you can set it »), jamais un comportement d'utilisateurs réels.
7. **Attribution de recherche vague** : « research consistently shows », « it is well documented » sans source = flag. Soit on cite une source datée, soit on formule en observation (« most people notice that… »).
8. **Date de source ≠ date de vérification** : « as reported 2026-08-15 » dans une fiche de faits signifie « vérifié ce jour-là », pas « publié ce jour-là ». Toujours écrire « published <date réelle>, checked <date> ».
9. **Citations entre guillemets = verbatim, sans exception.** Toute phrase entre guillemets doit exister mot pour mot dans la source citée, vérifiée par fetch. Trois fautes déjà attrapées : une citation attribuée à un éditeur qui n'est nulle part dans sa jacket copy, les mots d'un journaliste mis dans la bouche de la personne qu'il décrit, et un sujet remplacé (« it » → « dopamine ») sans ellipse. Si le sens est juste mais les mots approximatifs, on retire les guillemets et on paraphrase. Une citation invérifiable se supprime, elle ne se sauve pas.
10. **Lire la conclusion d'une étude, pas seulement ses chiffres.** Erreur type : citer correctement « 36% » et « 57% » d'une étude PNAS tout en inversant sa hiérarchie causale (le papier conclut que c'est l'option d'abandon qui porte l'effet, la friction n'ajoutant rien par-dessus). Vérifier aussi les conflits d'intérêts : un co-auteur peut être le développeur de l'app étudiée, ce qui se divulgue quand la page recommande ce type d'outil.
11. **Fausse précision non sourcée** : « most people report », « the low point is between 24 and 72 hours », un horaire à la demi-heure près. Une généralisation comportementale sans source se requalifie en observation (« beaucoup de gens décrivent ») ou disparaît.
12. **Notes de process internes** : « nous n'avons pas pu vérifier cette formulation » n'a rien à faire dans une page publiée. Soit on vérifie, soit on supprime le passage.
13. **Étapes techniques iOS/apps** : dater et sourcer chaque parcours de réglages. ⚠️ Apple a renommé le menu Screen Time : le chemin actuel passe par Content & Privacy Restrictions → **App Store, Media, Web, & Games** → Web Content, avec les options « Unrestricted », « Limit Adult Websites », « Only Approved Websites ». Tout guide décrivant « Content Restrictions » ou « Allowed Websites Only » est périmé. Erreurs déjà attrapées : « Allowed Apps » ne bloque pas les apps tierces, Photo Shuffle date d'iOS 16 (pas 17), l'action Shortcuts « Set Wallpaper Photo » existe toujours (instable, pas supprimée).
