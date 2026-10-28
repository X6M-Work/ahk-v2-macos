# Phase 3 — preuve d'architecture et limites de la phase 5

## Verdict

**La fidélité stricte à AHK 2.0.31 est bloquée par la gestion actuelle de la durée de vie des objets.** Le backend macOS ne corrige pas ce problème commun au moteur. Les cinq contre-exemples exécutables de `compat/phase15-architecture` passent avec AutoHotkey officiel 2.0.31 et échouent avec le binaire Keysharp Windows reconstruit. Aucune modification du runtime de destruction n'est revendiquée ici.

| Contrat observable | AutoHotkey 2.0.31 | Keysharp observé |
|---|---|---|
| Dernier alias libéré | `__Delete` avant l'instruction suivante | Aucun appel à cet instant |
| Variable locale en fin de fonction | `__Delete` avant le retour à l'appelant | Aucun appel à cet instant |
| Argument temporaire libéré | `__Delete` avant l'instruction suivante | Aucun appel à cet instant |
| Objet ressuscité puis libéré à nouveau | Deux appels à `__Delete` | Zéro appel aux deux points observés |
| Fichier local en fin de fonction | Données lisibles, handle libéré | Fichier encore verrouillé sur Windows |

Sources de preuve actualisées : ahk-v2-macos-validation/current-official/phase15-architecture.json et current-windows/phase15-architecture.json, livrés à côté du checkout. Les rapports incluent les empreintes des assemblages reconstruits, les sources, les sorties et les délais. Les cinq échecs sont confirmés sur Windows après les autres corrections. Le corpus complet natif reste à exécuter ; la CI Mac du corpus initial et des tests NUnit est consignée dans `validation.md`.

## Cause et décision

`Keysharp.Core/Builtins/ObjectBase/Any.cs` attache un `GCCleanupSentinel` aux objets nécessitant une destruction. Son finalizer transmet l'objet à `Keysharp.Core/Internals/Scripting/DestructorPump.cs`. Le pump exécute les destructeurs sur le thread du script après une collection. `Any.ArmAgain` et le drapeau `Again` évitent actuellement un deuxième `__Delete` après résurrection, ce qui diffère aussi du contrat observé d'AutoHotkey.

`Keysharp.Core/Runtime/Script/Lifetime.cs` et les `GC.KeepAlive` du lowerer maintiennent des références en vie ; ils ne produisent pas le comptage de références nécessaire. La collecte au moment de `ExitAppInternal` ne peut pas réparer les effets qui devaient se produire avant l'instruction suivante. Une collecte forcée, un délai, un appel manuel à `__Delete` ou une fermeture ajoutée au fixture masqueraient l'écart.

Pour franchir ce gate, la durée de vie des objets script doit être pilotée explicitement par leurs références script. Les affectations, alias, champs, tableaux, maps, closures, VarRef, retours et temporaires doivent tous conserver et libérer ces références au bon point du langage. La libération finale doit être synchrone, permettre la résurrection et préserver les ressources encore utilisées par `__Delete`. Le GC .NET peut rester responsable du stockage du moteur, mais ne peut plus décider seul de la destruction observable. Cette modification touche le lowerer et tous les conteneurs ; elle nécessite une migration cohérente, pas un ajout isolé dans le pump.

Critère de passage : les cinq fixtures stricts passent inchangés, puis des tests couvrent les chaînes de destruction, exceptions dans `__Delete`, références circulaires, closures et ressources natives. Les passages obtenus seulement après `Collect()` restent insuffisants. La phase 3 reste ouverte tant que ce critère n'est pas atteint.

## Appels natifs macOS

`compat/phase15-architecture/macos` contient quatre prototypes locaux : `getpid`, `strlen` ASCII, `qsort` avec callback script et retour Float32 de `sqrtf`. Ils utilisent explicitement `/usr/lib/libSystem.B.dylib`. Les résultats attendus décrivent les contrats C ; ils n'ont pas été confirmés sur Mac. Ils ne chargent aucune DLL Windows et n'assimilent pas les conventions Windows aux conventions ARM64 Darwin.

Les vérifications à réaliser sur Intel et Apple Silicon comprennent les callbacks, tailles `size_t`/pointeurs, flottants, agrégats, erreurs de chargement, durée de validité des chaînes et pointeurs, et appels réentrants. Les prototypes limités ne prouvent pas une ABI complète. Les tests Windows de `StrPtr`, encodages et `NumGet`/`NumPut` appartiennent à un autre corpus ; ils ne remplacent pas ces essais natifs.

`VarSetStrCapacity` conserve aussi des différences d'allocation observables. Le stockage natif de Keysharp réserve au moins 259 caractères dès certains appels `StrPtr`, alors qu'AutoHotkey peut exposer une capacité plus petite ; sa capacité allouée et sa capacité logique ne sont pas encore alignées. La mémoire située après le premier terminateur ne possède pas de contenu garanti : une nouvelle allocation AutoHotkey peut contenir des octets résiduels, et une réservation réutilisée peut conserver l'ancienne fin du texte. Le fixture `string-pointer-contracts` écrit donc explicitement `A` **et son terminateur**, puis demande la mise à jour de la longueur. Il ne déduit aucun effacement du reste du buffer d'un passage observé.

## Phase 5 : ce qui est prouvé

`compat/phase15-runtime` caractérise neuf scénarios publics : timer unique ; suppression avant lancement ; arrêt d'un timer répétitif ; absence de réentrance pendant un dépassement ; report d'un timer pendant Critical ; Pause du thread sous-jacent ; Pause sans thread sous-jacent ; ordre, retrait et veto des handlers OnExit ; options Hotkey et validation avant mutation. Les délais servent de garde-fou ; aucune fréquence exacte n'est promise.

Trois processus séparés vérifient aussi le code de sortie 17 transmis à OnExit, un handler OnError avec stderr et code 23, et la continuation d'une TypeError. Leur runner réutilise la création d'un processus isolé, le timeout et la fermeture de tous ses descendants. Tous les scripts installent un handler de sécurité ou le handler explicitement testé. Ils ne demandent aucune entrée utilisateur.

Ces scénarios passent avec AutoHotkey 2.0.31. Les rapports actualisés confirment neuf scénarios et trois processus réussis sur Keysharp Windows. Un échec intermittent distinct du test NUnit `FlowTryInterrupt` reste à caractériser ; il n'est pas compté comme une correction acquise du scheduler.

`compat/phase15-reload/run_reload.py` ajoute un processus contrôleur qui reste vivant pendant un Reload réel. Le cas vérifie OnExit avec la raison Reload, le renouvellement de l'état, la fin du processus précédent, un timer dans son remplaçant, puis sa sortie effective. Il passe avec AutoHotkey 2.0.31 et le moteur Keysharp reconstruit sur Windows. Tous les descendants restent dans le Job Object ; l'entrée standard est fermée et le délai total est borné. Cela ne valide pas la conservation des arguments ni du répertoire de travail initial.

La phase 5 demeure partielle : exécution Mac, Reload natif macOS, interruption sous charge, menus, hotkeys et nettoyage déterministe des ressources ne sont pas entièrement validés. La fermeture automatique d'un File local dépend directement du gate de durée de vie ci-dessus. Les corrections de bibliothèque standard et les résultats de leurs corpus sont suivis séparément.
