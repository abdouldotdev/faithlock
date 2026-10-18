# ABD-40 — Brief vérifiable de préparation Preview

Date de vérification : 2026-10-18T04:54:18Z
Projet Paperclip : FaithLock (`7c431866-02a3-4dbd-9476-87da653a2d2c`)
Portée : préparation et vérification locale du contrat `faithlock_store_click`; aucune publication, aucun déploiement et aucune preuve de production revendiqués.

## Disposition

Artefact prêt pour Orion et pour une relecture humaine de la Preview. La vérification interactive Preview n'est pas concluante dans ce runtime : l'URL Vercel redirige vers l'authentification Vercel (HTTP 302), donc aucun clic, rendu ou événement distant n'est inventé.

Classification actuelle : HUMAN_DECISION pour fournir une Preview accessible ou un accès de test contrôlé. Aucun défaut de code reproduit. La réception PostHog reste à confirmer par Orion dans le projet web `324483`; si la relecture fraîche confirme l'absence de l'événement, classer alors `DATA_ABSENT` / `INSTRUMENTATION_MISSING` et ne pas l'interpréter comme installation, abonnement ou revenu.

## Preuves locales exécutées

Répertoire : `apps/faithlock-seo`

Commande : `corepack pnpm test:tracking`
Résultat réel : PASS, 7 tests, 0 échec. Node émet seulement un avertissement `MODULE_TYPELESS_PACKAGE_JSON` pour le fichier TypeScript importé.

Commande : `./node_modules/.bin/tsc --noEmit`
Résultat réel : PASS, code retour 0.

Commit contrôlé : `9fa210519a2410ae82e48f23fdcc4d98eec88370` sur `fix/faithlock-store-click-measurement`.

Les tests locaux vérifient :
- exactement un événement par clic éligible traité;
- zéro événement pour le lien App Store homonyme/tiers `id6786329834` et les domaines trompeurs;
- absence de `preventDefault()` et conservation de la navigation native;
- chemin clavier via clic DOM délégué;
- ordinal limité aux liens éligibles dans l'article, sans décalage par un header/menu mobile hors article;
- propriétés minimales : `cta_id`, `page_path`, `link_position`, `market=US`, `source=resource_page`, `destination_url`, `destination_type`.

## Vérification d'accès Preview

Preview attendue : `https://faithlock-git-fix-faithlock-store-c60ba0-prodevking1s-projects.vercel.app`

Commande exécutée :
`curl -sS -I -L --max-redirs 3 --max-time 20 'https://faithlock-git-fix-faithlock-store-c60ba0-prodevking1s-projects.vercel.app/resources/best-bible-verse-lock-screen-apps'`

Résultat réel : la Preview renvoie HTTP 302 vers `vercel.com/sso-api`, puis vers `/login`; le contenu de la page FaithLock n'est donc pas accessible sans authentification. Aucun cookie, jeton ou secret n'a été collecté ni affiché.

## Procédure Preview à exécuter après ouverture contrôlée

1. Ouvrir chacune des deux pages `/resources/best-bible-verse-lock-screen-apps` et `/resources/best-christian-app-blocker` dans la Preview, avec DevTools Network ouvert et le projet PostHog web `324483` confirmé.
2. Cliquer une fois sur chaque destination officielle (`https://pim.ms/kTxgKF4` puis l'URL App Store terminant par `/id6754208209`); relever exactement un `faithlock_store_click` par clic et les sept propriétés attendues.
3. Refaire l'essai sur un lien focalisé au clavier; confirmer un seul événement et la navigation vers la destination.
4. Passer en viewport mobile; confirmer qu'un lien header/menu hors `article.cozy-page` ne produit aucun événement et ne modifie pas l'ordinal des liens de l'article.
5. Cliquer un lien App Store tiers/homonyme; confirmer zéro `faithlock_store_click`.
6. Bloquer ou faire échouer le transport analytics; confirmer que la navigation native reste effective.
7. Orion relit ensuite l'événement dans le projet web `324483`, avec horodatage, URL Preview et propriétés contrôlées. Ne pas relire le projet app `239251` par confusion.

## Prochaine action prête

Jupiter/approbateur humain : fournir une URL Preview accessible ou une session de test contrôlée, sans modifier de secret. Orion : exécuter la relecture PostHog immédiatement après les clics et joindre la preuve fraîche. À défaut d'accès, conserver l'artefact et la classification `HUMAN_DECISION`; ne pas clôturer comme validation Preview positive.
