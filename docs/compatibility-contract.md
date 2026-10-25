# Contrat de compatibilité

Référence figée : AutoHotkey **2.0.31 Windows x64**, documentation officielle au commit `c9c15a922fa91b69095e4d6225c6691c4d959175`. Cibles : macOS 15+, Apple Silicon et Intel. Provenance : `UPSTREAM.lock.json`. Contrat lisible par machine : `compat/contract.json`.

L'objectif reste l'exécution des scripts AHK v2 sans modification. Une extension Keysharp, une réécriture du script ou un résultat approximatif ne constituent pas une compatibilité acquise. Les comportements v2.1 de la base amont ne servent pas de référence aux corrections v2.0.

Le contrat comprend la syntaxe, les portées, les valeurs, conversions, objets, propriétés, énumérateurs, erreurs, encodages, fichiers, processus, événements et interfaces natives. Il comprend les effets observables : sortie, code de fin, moment de destruction et validité des adresses mémoire. Les durées exactes d'ordonnancement ne sont pas des résultats déterministes ; ordre, annulation, absence de réentrance et livraison différée se testent avec des délais bornés.

Les scripts dépendant de DLL Windows, COM, registre, messages et contrôles Win32 restent des exigences non résolues. AppKit/Accessibility ne reproduisent pas automatiquement ces interfaces. Sans couche Windows équivalente, la compatibilité globale à 100 % ne peut pas être annoncée. Aucun retrait de ces exigences ne doit servir à présenter un pourcentage artificiel.

| Étape | Critère de validation |
|---|---|
| 1. Contrat | Version, périmètre et règles de preuve figés ici et dans le JSON |
| 2. macOS natif | Compilation et exécution locales sur Intel puis Apple Silicon, rapports avec architecture et empreintes |
| 3. Architecture | Destruction immédiate, alias/résurrection, fermeture des ressources ; mémoire UTF-16 ; ABI, appels et callbacks natifs |
| 4. Langage | Même source et sorties vérifiées avec l'exécutable officiel et le candidat |
| 5. Bibliothèque et exécution | Fichiers/encodages, processus, timers, Sleep/Pause/Critical, OnExit et arrêt, puis tests de régression |

L'étape 3 bloque une déclaration de compatibilité complète, même si d'autres corrections peuvent avancer indépendamment. Forcer un GC ou ajouter un délai dans les tests masque le problème de destruction et ne valide pas le contrat.

Les corpus ne couvrent qu'une sélection de comportements. Le nombre de lignes de `capabilities.json` n'est ni une couverture d'API, ni un taux de compatibilité. Un statut amont `full` n'est pas une preuve d'exécution de ce fork sur macOS.

Chaque test de conformité exige le même script, une attente revue et validée par AHK officiel, un délai maximal, une capture UTF-8 sans altération autre que CRLF → LF, et un nettoyage du processus. Les erreurs runtime des fixtures utilisent `OnError` pour quitter sans dialogue. Les erreurs attendues sont capturées dans le script ; les tests de codes de sortie ont un runner distinct.

Tout reste local. Aucun dépôt GitHub ni exécution distante ne sont nécessaires. Le build et les tests macOS seront marqués « non exécutés » tant qu'aucun Mac local n'aura fourni de rapport. Les instructions et rapports se trouvent dans `docs/validation.md` et `compat/README.md`.
