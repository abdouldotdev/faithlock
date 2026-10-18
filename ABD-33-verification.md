# ABD-33 — vérification technique du tracking web → App Store

Date de vérification : 2026-10-18T03:57:36Z
Périmètre : FaithLock officiel uniquement, pages `/resources/best-bible-verse-lock-screen-apps` et `/resources/best-christian-app-blocker`, événement `faithlock_store_click`.

## Résultat synthétique

Le contrat est couvert par les tests locaux ciblés : 7 tests passent. Le code émet au plus un événement par appel de traitement de clic éligible, ignore les liens tiers, ne fait pas `preventDefault()` et limite l’ordinal aux liens éligibles contenus dans l’article. Le test d’identité verrouille l’App Store `id6754208209` / `Appbiz Studio, LLC` et exclut `id6786329834`.

La réception PostHog n’est pas démontrée : la lecture contrôlée du connecteur PostHog renvoie une alerte de taxonomie indiquant que `faithlock_store_click` est absent du projet interrogé. Cela doit être traité comme absence de donnée/événement (`DATA_ABSENT` / `INSTRUMENTATION_MISSING`), pas comme preuve d’installation, abonnement ou revenu.

La Preview Vercel est protégée par authentification dans cet environnement : l’URL redirige vers `vercel.com/login`; le test manuel souris/clavier/mobile n’a donc pas pu être exécuté ici. La session navigateur est également indisponible car Chrome échoue au démarrage (`snap-confine` permissions). C’est un blocage d’accès à la Preview, pas un défaut reproduit du code.

## Contrat à vérifier

- Un clic éligible sur l’une des deux pages produit exactement un `faithlock_store_click`.
- Les destinations éligibles sont `https://pim.ms/kTxgKF4` et une URL `apps.apple.com` terminant par `/id6754208209`.
- Le lien homonyme `id6786329834`, les domaines trompeurs et les autres liens App Store n’émettent rien.
- Le tracker écoute le clic délégué et utilise l’ancre la plus proche; un clic clavier qui produit un clic DOM suit le même chemin.
- Aucun `preventDefault`, attente PostHog ou réécriture d’URL : la navigation reste native et fonctionne même si l’analytics est bloquée.
- Les liens du header/menu mobile hors `article.cozy-page` ne décalent pas les `cta_id` et ne sont pas éligibles.
- `destination_type` distingue `short_link` et `app_store`; l’événement mesure un clic sortant web seulement.

## Reproduction locale

Répertoire : `apps/faithlock-seo`

1. `corepack pnpm test:tracking` — PASS, 7/7.
2. `npm run test:tracking` — PASS, 7/7.
3. `./node_modules/.bin/tsc --noEmit` — PASS, code retour 0.
4. `npm run build` — BLOCKED environnement : compilation et contrôle TypeScript réussissent, puis la collecte Next échoue sur `CONTENTFUL_SPACE_ID is not defined` pour `/sitemap.xml`. Aucun secret n’a été ajouté ni imprimé.

Avertissement non bloquant observé dans les tests : Node signale que `package.json` ne déclare pas `type: module` pour le fichier TypeScript importé avec `--experimental-strip-types`.

## Résultats des tests ciblés

- PASS `keeps the FaithLock App Store identity contract pinned`.
- PASS `does not allow the homonymous App Store id in the production tracker`.
- PASS `captures exactly one event per eligible click and preserves navigation`.
- PASS `does not capture third-party store links`.
- PASS `tracks only official FaithLock store destinations on the two approved resources`.
- PASS `distinguishes official direct App Store links and rejects misleading domains`.
- PASS `article-only ordinal ignores a dynamic mobile header link and outside clicks`.

Ces tests sont unitaires/intégration locale; ils ne prouvent ni réception distante PostHog ni comportement de production.

## État PR / Preview observé

- PR #1 : `https://github.com/abdouldotdev/faithlock/pull/1`.
- GitHub la signale `MERGED` le 2026-10-18T02:55:31Z, commit de merge `38d472cc9f77bfc66b257dfa381702951a1b06c3`; le head vérifié était `a602266d7f1e3975296e9a02c60a9b498ba1a774`.
- Checks GitHub observés : Vercel et Vercel Preview Comments en succès.
- Je n’ai effectué aucune fusion ni aucun déploiement dans cette tâche. L’état `MERGED` est une divergence entre la demande « PR brouillon/non fusionnée » et l’état GitHub actuel, à soumettre à Jupiter/à l’approbateur humain.
- URL Preview issue du commentaire Vercel : `https://faithlock-git-fix-faithlock-store-c60ba0-prodevking1s-projects.vercel.app`.
- Accès depuis cet environnement : redirection vers authentification Vercel, donc aucun clic manuel fiable et aucune preuve de rendu Preview n’est revendiquée.

## Procédure manuelle restante, avec approbation humaine

Sur une Preview accessible et PostHog web explicitement configuré dans le bon projet :

1. Ouvrir chacune des deux pages ciblées en fenêtre privée ou session de test.
2. Avec DevTools Network/PostHog, cliquer une fois au pointeur sur chaque destination officielle; vérifier un seul `faithlock_store_click` par clic et conserver les propriétés (`page_path`, `cta_id`, `link_position`, `market=US`, `source=resource_page`, `destination_url`, `destination_type`).
3. Refaire un clic clavier sur le lien focalisé; vérifier un seul événement et la navigation vers la destination.
4. Vérifier en viewport mobile qu’un lien header/menu hors article ne produit pas d’événement et ne change pas l’ordinal des CTA dans l’article.
5. Cliquer un lien App Store tiers/homonyme présent dans le contenu; vérifier zéro `faithlock_store_click`.
6. Vérifier la navigation effective même avec le transport PostHog bloqué ou échoué.
7. Relire l’événement dans le projet PostHog web landing page, avec fenêtre temporelle et environnement de test documentés. Ne pas utiliser le projet app par confusion.

## Prochaine étape et décision demandée

Jupiter/approbateur humain doit d’abord confirmer l’état attendu de PR #1 (elle est déjà `MERGED` selon GitHub) et fournir une Preview accessible ou un accès de test contrôlé. Ensuite, Data doit confirmer le projet PostHog web, le nom exact de l’événement et ses propriétés; le propriétaire produit doit approuver le contrat. Une preuve de clic reçue ne pourra jamais être présentée comme installation, abonnement ou revenu. Toute validation de production reste une décision humaine distincte.
