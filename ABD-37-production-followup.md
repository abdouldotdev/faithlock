# ABD-37 — Suivi du contrôle navigateur production

Date : 2026-10-18 UTC
Projet : FaithLock (`7c431866-02a3-4dbd-9476-87da653a2d2c`)
Portée : contrôle réversible d’un clic CTA sur le domaine public ; ceci ne constitue pas une preuve de réception PostHog ni une validation Preview.

## Résultat observé

- URL : `https://www.getfaithlock.com/resources/best-bible-verse-lock-screen-apps`
- Le runtime navigateur a chargé le DOM FaithLock sans Vercel Security Checkpoint.
- Le CTA header « Download now » a été activé une fois.
- Navigation observée vers `https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209`.
- La fiche cible affiche « Faith Lock: Bible Prayer Focus » et le vendeur « Appbiz Studio, LLC », conformément à l’identité produit vérifiée.

## Limites

- Le runtime n’a pas fourni de capture réseau/PostHog exploitable pour relire `faithlock_store_click`; aucune réception distante ni nombre d’événements n’est revendiqué.
- Le contrôle demandé sur Preview reste non concluant : la Preview Vercel est protégée par authentification. La PR #1 est désormais relue comme fusionnée, donc le parcours production est documenté séparément.
- Les tests locaux précédemment exécutés restent le substitut code : 7/7 tests tracking PASS et TypeScript PASS. Ils ne prouvent ni Preview, ni réception distante.

## Disposition

Résultat partiel uniquement. Ne pas clôturer ABD-37 comme validation complète. Prochaine action : Data/Orion doit relire fraîchement le projet PostHog landing page `324483` pour `faithlock_store_click` et ses propriétés (`cta_id`, `page_path`, `link_position`, `market`, `source`, `destination_url`, `destination_type`). Si cette relecture est impossible, conserver le blocage de preuve distante et demander une voie de capture réseau autorisée ; ne pas classer CODE_DEFECT sur cette seule absence.
