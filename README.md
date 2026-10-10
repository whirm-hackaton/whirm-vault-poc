# Coffre bancaire local — Vaultwarden

POC autonome pour Kalamar, hors des modules frontend et backend de l’équipe. Une instance Vaultwarden avec quatre comptes personnels. Le serveur tourne sur le PC ; aucun tunnel ni service de stockage distant n’est configuré.

## État au moment de la préparation

Adresse Wi-Fi observée sur la machine de démonstration : **172.20.10.2** ; passerelle : **172.20.10.1**. Adapter cette adresse au PC qui lance le projet. Les deux services ont été lancés et la réponse du coffre a été vérifiée en HTTPS avec validation du certificat sous Windows. Le téléchargement du certificat public depuis Safari iPhone a été confirmé. L’accès au coffre HTTPS et la synchronisation sur iPhone restent à confirmer. La création d’une règle pare-feu a été refusée par Windows faute de droits administrateur ; aucune règle n’a été ajoutée par l’agent.

## Lancer

Ouvrir Docker Desktop et attendre que le moteur soit disponible. Dans PowerShell 7, ouvrir ce dossier puis lancer :

```powershell
./Start-Poc.ps1 -Ip 172.20.10.2 -TrustWindows
```

Le script utilise uniquement les deux conteneurs de ce projet. Il crée les volumes persistants, attend la réponse de Vaultwarden, exporte le certificat public et, avec `-TrustWindows`, ajoute cette autorité locale au magasin de certificats de l’utilisateur Windows. Les premières images nécessitent Internet pour être téléchargées.

Adresse du coffre sur Windows et iPhone : **https://172.20.10.2:8443**. Utiliser la même adresse dans l’extension Windows et l’application Bitwarden iPhone, dans le choix « serveur auto-hébergé ».

Si l’IP du PC change, relancer avec la nouvelle IP et mettre à jour les clients. Les volumes conservent le coffre et l’autorité de certification. Un changement de réseau peut changer l’IP ; il ne doit pas entraîner une suppression des volumes.

## Installer le certificat sur iPhone

1. Garder le partage de connexion actif et le PC connecté.
2. Dans Safari, ouvrir **http://172.20.10.2:8081/bank-poc-root.cer**. Cette adresse HTTP ne sert que le certificat public ; elle ne sert pas le coffre.
3. Autoriser le téléchargement, puis installer le profil dans Réglages → Général → VPN et gestion de l’appareil (ou « Profil téléchargé »).
4. Dans Réglages → Général → Informations → Réglages des certificats, activer la confiance complète pour l’autorité locale Caddy de ce POC.
5. Ouvrir **https://172.20.10.2:8443** et vérifier l’absence d’erreur de certificat.

Si Safari ne peut pas atteindre le PC, il faut résoudre la connectivité du partage de connexion et le pare-feu avant de tester le coffre. Installer le certificat n’ouvre aucun port réseau.

Le certificat est public. Les clés privées de l’autorité restent dans le volume Caddy ; ne jamais exporter ou partager ce volume pour installer un certificat sur un téléphone. Vérifier qu’on installe bien le certificat généré par ce PC. La confiance accordée à une autorité est une modification de sécurité de l’appareil ; retirer cette autorité après la démo.

Source : [installation et confiance iOS](https://support.apple.com/en-us/102390).

## Autoriser le réseau si le pare-feu bloque

Depuis un PowerShell **administrateur**, créer une règle limitée au réseau actuellement observé :

```powershell
New-NetFirewallRule -Name 'HackathonBankPoc' -DisplayName 'Hackathon Bank POC' -Direction Inbound -Action Allow -Protocol TCP -LocalAddress 172.20.10.2 -LocalPort 8443,8081 -RemoteAddress 172.20.10.0/28 -Profile Any
```

Ne pas désactiver le pare-feu. Adapter IP et sous-réseau si le réseau change. Même avec cette règle, le chemin iPhone → PC doit être vérifié : les caractéristiques du partage de connexion peuvent empêcher certaines communications locales.

## Créer quatre comptes

**Une instance commune, un compte par client.** Les quatre membres de la démonstration représentent quatre clients et créent quatre comptes séparés. Un même client utilise le même compte sur Windows et iPhone : il n’y a pas un nouveau compte par appareil, ni un compte partagé par toute l’équipe.

1. Ouvrir **https://172.20.10.2:8443** après reconnaissance du certificat.
2. Choisir l’action de création de compte du coffre web Vaultwarden.
3. Saisir son email et choisir son mot de passe maître personnel, distinct du mot de passe bancaire.
4. Configurer l’application/extension Bitwarden avec le serveur auto-hébergé, puis se connecter à ce même compte.
5. Créer ensuite la passkey depuis l’application wallet ou une page WebAuthn adaptée et la conserver dans Bitwarden.

Le client web sur l’appareil initialise le chiffrement ; le serveur enregistre le compte et le coffre chiffré. L’inscription du coffre n’est pas automatisée par la connexion bancaire dans ce POC. La création effective des quatre comptes reste à confirmer.

Chaque membre s’inscrit avec une adresse email valide qu’il contrôle et un mot de passe maître qu’il choisit lui-même. Aucun mot de passe n’est créé par le script. Aucun SMTP n’est configuré : les fonctions nécessitant un email ne sont pas validées dans ce POC.

Les inscriptions sont ouvertes pour ce démarrage sur le réseau local. Après création des quatre comptes :

```powershell
./Start-Poc.ps1 -Ip 172.20.10.2 -CloseSignups -TrustWindows
```

Les coffres restent personnels. Pas de création d’organisation, pas d’invitations, pas d’accès d’urgence et pas de panneau administrateur configuré. Le fait que le serveur héberge quatre comptes ne donne pas aux membres accès aux coffres des autres. Le compte administrateur Windows et les logiciels clients restent dans le modèle de confiance.

## Test de démonstration

1. Ouvrir deux comptes distincts et vérifier qu’ils présentent des coffres distincts.
2. Ajouter un élément de test dans le compte de Kalamar sur Windows et vérifier sa synchronisation sur iPhone.
3. Activer Bitwarden comme fournisseur de passkeys sur iPhone, et utiliser l’extension sur Windows. La compatibilité entre les versions choisies doit être testée.
4. Créer une passkey dans une page wallet/test adaptée, puis vérifier son utilisation sur le deuxième appareil avec le premier indisponible.

**L’adresse IP HTTPS ci-dessus convient au coffre et à sa synchronisation. Elle ne définit pas le RP ID du wallet.** Les cérémonies WebAuthn du wallet demandent un nom de domaine admissible et stable, accessible depuis les deux appareils. Une page wallet sur `localhost` n’est pas automatiquement réutilisable sur iPhone. Ce composant n’est pas déployé par cette configuration.

Le succès de synchronisation d’un élément ne prouve pas encore une signature passkey ni le contrôle du même smart account. Ces preuves doivent être collectées séparément.

## Arrêt et conservation

```powershell
docker compose stop
```

Cette commande conserve les volumes. Éviter toute commande supprimant les volumes : ils contiennent les coffres et l’autorité locale. Après la démo, retirer le profil de certificat sur iPhone et la règle `HackathonBankPoc` si elle a été créée. Le certificat public exporté peut être ouvert sous Windows pour relever son empreinte et supprimer uniquement cette autorité du magasin utilisateur.

## Configuration et références

Images fixées : Vaultwarden **1.37.4** et Caddy **2.11.7-alpine**, versions publiées consultées le 10 octobre 2026. La résolution effective des images sera vérifiée au téléchargement. HTTPS est terminé par Caddy ; Vaultwarden n’a aucun port publié directement sur l’hôte. Seuls 8443 (coffre HTTPS) et 8081 (certificat public HTTP) sont publiés sur l’adresse Wi-Fi choisie ; 8443 est aussi disponible en boucle locale.

* [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
* [Version Vaultwarden](https://github.com/dani-garcia/vaultwarden/releases/tag/1.37.4)
* [Proxy recommandé](https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples)
* [Autorité locale Caddy](https://caddyserver.com/docs/caddyfile/directives/tls)

Ce POC illustre l’hébergement d’un coffre chiffré par la banque ; il ne démontre pas à lui seul une garantie absolue de confidentialité, une récupération après perte totale ou la sécurité d’une application wallet distribuée par l’hébergeur.
