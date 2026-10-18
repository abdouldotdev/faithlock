# ABD-37 — Suivi du contrôle navigateur production

Date : 2026-10-18 UTC
Projet : FaithLock (`7c431866-02a3-4dbd-9476-87da653a2d2c`)
Portée : contrôle réversible d’un clic CTA sur le domaine public ; ceci ne constitue pas une preuve de réception PostHog ni une validation Preview.

## Résultat observé

- URL : `https://www.getfaithlock.com/resources/best-bible-verse-lock-screen-apps`.
- Le runtime navigateur a chargé le DOM FaithLock sans Vercel Security Checkpoint.
- Le clic contrôlé sur le CTA article `Try Free` (`https://pim.ms/kTxgKF4`) a été intercepté une fois pour conserver la page ouverte pendant l’observation.
- Le lien est bien dans `article.cozy-page`, mais aucun appel observable `faithlock_store_click`/PostHog n’a été émis pendant ce parcours.
- Le lien cible est le short-link officiel attendu. Le clic séparé du CTA header a navigué vers `https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209`; la fiche affiche « Faith Lock: Bible Prayer Focus » et le vendeur « Appbiz Studio, LLC », conformément à l’identité produit vérifiée.

## Limites et classification

- `INSTRUMENTATION_MISSING` côté production : la réception PostHog et l’émission de l’événement ne sont pas prouvées ; aucun nombre d’événements ni baseline n’est revendiqué.
- Inspection des scripts JavaScript servis par la page : aucun bundle chargé ne contient les marqueurs de l’intégration `ResourceStoreClickTracker`, `faithlock_store_click` ou `resource_page`, alors que le workspace contient cette intégration dans `GlossaryTemplate.tsx` et les tests associés. Cela indique une divergence entre le code local/PR et le bundle public servi, à confirmer par Data/Release.
- Le contrôle Preview reste non concluant : la Preview Vercel est protégée par authentification. Les tests locaux précédemment exécutés restent le substitut code : 7/7 tests tracking PASS et TypeScript PASS.

## Disposition

Résultat partiel uniquement. Ne pas clôturer ABD-37 comme validation complète. Prochaine action propriétaire Jupiter/Release : confirmer le commit réellement déployé et fournir une Preview/production dont le bundle inclut l’intégration. Ensuite Orion/Data relit fraîchement le projet PostHog landing page `324483` pour `faithlock_store_click` et les propriétés (`cta_id`, `page_path`, `link_position`, `market`, `source`, `destination_url`, `destination_type`).
