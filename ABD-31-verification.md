# ABD-31 — vérification du contrat d’identité App Store

Projet : FaithLock (Paperclip 7c431866-02a3-4dbd-9476-87da653a2d2c)
Agent : Dev (d7e6853c-cb45-41a1-94d6-834592bc04a9)
Run : 500715b5-2cc6-4ef4-b4f2-73e346aeb251

État vérifié sur la branche `fix/faithlock-store-click-measurement` :
- Contrat officiel dans `apps/faithlock-seo/lib/resource-store-click.ts` : ID 6754208209, Appbiz Studio, LLC, URL canonique `https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209`.
- Test statique `apps/faithlock-seo/tests/app-store-identity-contract.test.mjs` intégré à `test:tracking`.
- L’homonyme 6786329834 est explicitement rejeté et n’existe que dans les fixtures négatives prévues.

Preuves exécutées :
- `corepack pnpm test:tracking` : PASS, 7/7.
- `./node_modules/.bin/tsc --noEmit` : PASS.
- Sabotage temporaire vers 6786329834 : échec des tests confirmé, puis restauration et nouveau passage au vert.
- `git diff --check` : PASS dans le run précédent.
- Aucun CODE_DEFECT de production trouvé dans les références contrôlées.
- Aucun merge ni déploiement effectué par Dev. La PR #1 est déjà MERGED selon GitHub ; ce contrôle reste hors production.

Disposition attendue : `done`.

Limite de persistance Paperclip : la tentative de mise à jour atomique de l’issue ABD-31 avec `X-Paperclip-Run-Id: 500715b5-2cc6-4ef4-b4f2-73e346aeb251` a été refusée HTTP 403 (`cross_issue_influence_run_context_required`) malgré la présence du run dans `GET /api/companies/{companyId}/heartbeat-runs` avec statut `running`. Le helper task bridge indiqué par TOOLS.md (`/srv/paperclip-hermes/dev/paperclip_issue.py`) est absent. À reprendre par Jupiter/Board : autoriser la mutation avec le contexte du run courant ou fournir le helper, puis relire ABD-31 après mise à jour.
