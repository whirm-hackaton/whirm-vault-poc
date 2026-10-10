# Coffre bancaire — Vaultwarden

**Déploiement VPS commun :** suivre le [guide Dokploy](docs/dokploy.md) avec `compose.dokploy.yaml` et `https://vault.whirm.dev`. Chaque utilisateur y possède son compte personnel. Ce déploiement est à effectuer et vérifier ; les instructions ci-dessous décrivent le mode local alternatif.

Chaque membre de l’équipe lance **sa propre instance sur son PC** et crée **un compte de test personnel sur cette instance**. Le téléphone et le navigateur du même membre se connectent à ce même compte. Il n’est pas nécessaire de créer quatre comptes sur chaque PC.

Les instances sont indépendantes : cloner ce dépôt reproduit le code et la configuration, pas les coffres, les comptes, les certificats ni les passkeys des autres. Dans un produit bancaire, une instance pourrait héberger plusieurs comptes clients séparés ; ce n’est pas l’organisation choisie pour les postes du POC.

Le serveur reste local, avec Docker Compose, Vaultwarden, SQLite et Caddy pour HTTPS. Aucun tunnel n’est configuré. Voir le [schéma](docs/schema.md).

## Prérequis sur chaque PC

* Docker Desktop démarré avec son moteur Linux et Docker Compose disponible.
* PowerShell 7 pour le script de lancement.
* **Extension Bitwarden installée dans le navigateur utilisé pour la démo**, même si le coffre propose automatiquement son installation. Le coffre web ou l’application desktop seuls ne remplacent pas cette extension dans notre parcours navigateur.
* Application **Bitwarden Password Manager** sur le téléphone. Ne pas la confondre avec l’application Bitwarden Authenticator.
* Pour les passkeys mobiles : **iOS 17+ ou Android 14+**, sous réserve de la compatibilité de l’appareil, du navigateur et de la version de Bitwarden. [Passkeys Bitwarden](https://bitwarden.com/help/storing-passkeys/)

## 1 — Choisir le réseau et l’adresse du PC

Le PC et le téléphone doivent pouvoir communiquer directement sur le réseau local. Cela peut fonctionner sur un Wi-Fi domestique ou sur un partage de connexion ; il faut le tester.

**Sur un « free-wifi », un Wi-Fi public ou invité, ce n’est pas garanti.** Certains réseaux activent l’isolation des clients ou filtrent les ports. Avoir Internet et le même nom de Wi-Fi ne prouve pas que le téléphone puisse joindre le PC. Si un portail captif est présent, connecter/authentifier les deux appareils avant le test.

Depuis PowerShell :

```powershell
ipconfig
```

Relever l’IPv4 de l’interface réellement connectée au réseau du téléphone. Ne pas prendre l’adresse d’une interface Docker, WSL, VMware ou VirtualBox. Le script accepte une IPv4 privée : 10.x.x.x, 172.16.x.x à 172.31.x.x, ou 192.168.x.x.

Dans ce guide, **172.20.10.2 est uniquement l’exemple observé sur le PC de Kalamar**. Chaque membre doit remplacer cette valeur par celle de son propre PC dans les commandes et adresses. Si le réseau n’attribue pas d’adresse privée utilisable, privilégier un réseau de démonstration contrôlé plutôt que modifier les protections du script.

Sur le téléphone, `localhost` désigne le téléphone, pas le PC.

## 2 — Lancer son instance

Depuis la racine du dépôt, dans PowerShell 7 :

```powershell
./Start-Poc.ps1 -Ip 172.20.10.2 -TrustWindows
```

Le script crée les volumes persistants, démarre Vaultwarden/Caddy, valide la configuration HTTPS, exporte le certificat racine **public** et, avec `-TrustWindows`, l’installe dans le magasin utilisateur Windows. Les images nécessitent Internet au premier téléchargement.

| Usage | Exemple à adapter à son PC |
|---|---|
| Coffre HTTPS | `https://172.20.10.2:8443` |
| Certificat public pour le téléphone | `http://172.20.10.2:8081/bank-poc-root.cer` |

Le port HTTP 8081 ne sert que le certificat public ; il ne sert pas le coffre. Les clés privées de l’autorité restent dans le volume Caddy et ne doivent pas être distribuées.

### Tester le réseau avant le certificat

Sur le téléphone, ouvrir l’adresse HTTP du certificat. Si le téléchargement est proposé, le téléphone peut joindre le PC sur ce port. Cela ne confirme pas encore le port HTTPS 8443 ni la synchronisation du coffre.

Si la page ne s’ouvre pas :

1. Vérifier IP, serveur démarré et connexion des deux appareils au réseau prévu.
2. Vérifier le portail captif et le pare-feu du PC.
3. Si le réseau public isole les appareils, utiliser un partage de connexion ou un réseau privé contrôlé, puis refaire le test. Le certificat et une règle Windows ne contournent pas une isolation imposée par le Wi-Fi.
4. Si un accès local reste impossible, un tunnel HTTPS serait une autre architecture ; il n’est pas configuré dans ce dépôt.

Source sur le mécanisme d’isolation : [documentation Cisco](https://documentation.meraki.com/Wireless/Operate_and_Maintain/How_Tos/Firewall_and_Traffic_Shaping/Wireless_Client_Isolation). Cela décrit une possibilité, pas la configuration du réseau utilisé au hackathon.

### Pare-feu Windows, seulement si nécessaire

Dans un PowerShell **administrateur**, adapter les deux adresses ci-dessous : l’IP du PC et celle du téléphone, visibles dans leurs paramètres réseau. Cette règle limite l’accès à ce téléphone, sur les deux ports du POC.

```powershell
$pocPcIp = '172.20.10.2'
$pocPhoneIp = '172.20.10.1'
New-NetFirewallRule -Name 'HackathonBankPoc' -DisplayName 'Hackathon Bank POC' -Direction Inbound -Action Allow -Protocol TCP -LocalAddress $pocPcIp -LocalPort 8443,8081 -RemoteAddress $pocPhoneIp -Profile Any
```

Les valeurs sont des exemples ; l’adresse du téléphone n’est pas nécessairement celle de la passerelle sur un Wi-Fi partagé. Si la règle existe déjà, examiner sa configuration avant de la modifier. Ne pas désactiver le pare-feu. Ajouter une règle ne supprime pas une isolation entre appareils sur le réseau.

## 3 — Configurer l’extension Bitwarden sur le PC

1. **Installer l’extension officielle Bitwarden** pour le navigateur de la démo, y compris si son installation a été suggérée automatiquement.
2. Sur son écran de connexion, sélectionner **Serveur auto-hébergé / Self-hosted**.
3. Saisir l’adresse HTTPS de son PC, par exemple `https://172.20.10.2:8443`.
4. Enregistrer ; se connecter avec le compte créé dans la section suivante et ouvrir le coffre.
5. Dans les réglages de l’extension, vérifier que la proposition d’enregistrer et utiliser les passkeys est activée.
6. Lors de la création d’une passkey, sélectionner Bitwarden ; ne pas supposer qu’elle a été enregistrée dans Vaultwarden si Windows Hello, Apple ou Google a été choisi.

Sources : [connexion des clients](https://bitwarden.com/help/change-client-environment/), [passkeys](https://bitwarden.com/help/storing-passkeys/).

## 4 — Créer son compte de test

**Un compte par client, pas un compte par appareil.** Pour les répliques de développement, chaque membre crée son compte sur sa propre instance et utilise ce même compte sur son PC et son téléphone. Des comptes supplémentaires sont facultatifs, notamment pour tester la séparation entre clients.

1. Ouvrir le coffre HTTPS sur le PC et choisir la création de compte.
2. Saisir une adresse email que l’on contrôle et choisir son mot de passe maître personnel, distinct du mot de passe bancaire.
3. Se connecter à ce compte dans l’extension et l’application mobile, avec la même adresse de serveur.
4. Créer ensuite la passkey depuis l’application wallet ou une page WebAuthn adaptée.

Le client web sur l’appareil initialise le chiffrement ; le serveur enregistre le compte et les données chiffrées. Notre backend bancaire ne crée pas le mot de passe maître et ne provisionne pas automatiquement ce compte de coffre. Aucun SMTP n’est configuré : les fonctions nécessitant un email ne sont pas validées ici.

Après création de son compte, fermer les inscriptions sur son instance :

```powershell
./Start-Poc.ps1 -Ip 172.20.10.2 -CloseSignups -TrustWindows
```

Pas de création d’organisation, d’invitations, d’accès d’urgence ni de panneau administrateur configuré. Deux instances différentes ne partagent pas automatiquement les comptes ou passkeys, même si l’email et le mot de passe saisis sont identiques.

## 5 — Setup iPhone

1. Garder le téléphone et le PC sur le réseau choisi.
2. Dans Safari, télécharger `http://172.20.10.2:8081/bank-poc-root.cer`, avec l’IP de son PC.
3. Installer le profil dans **Réglages → Général → VPN et gestion de l’appareil**, ou **Profil téléchargé**.
4. Dans **Général → Informations → Réglages des certificats**, activer la confiance complète pour l’autorité Caddy de cette instance.
5. Ouvrir `https://172.20.10.2:8443` et vérifier l’absence d’avertissement de certificat.
6. Installer Bitwarden Password Manager ; sélectionner **Serveur auto-hébergé**, saisir cette adresse HTTPS et se connecter au compte personnel.
7. Dans **Réglages → Général → Remplissage automatique et mots de passe**, activer le remplissage des mots de passe/clés d’accès et sélectionner Bitwarden. Sur les anciennes versions : **Mots de passe → Options des mots de passe**.
8. Lors de la création d’une passkey, choisir Bitwarden comme fournisseur.

Installer le certificat de **sa propre instance**, pas celui d’un autre membre. Sources : [confiance iOS](https://support.apple.com/en-us/102390), [configuration Bitwarden iOS](https://bitwarden.com/help/auto-fill-ios/).

## 6 — Setup Android

**Android 14+ est requis pour conserver/utiliser des passkeys avec Bitwarden.** La configuration doit être vérifiée sur le modèle et les versions utilisés ; elle n’a pas été exécutée par l’agent.

1. Connecter Android au réseau permettant de joindre son PC.
2. Télécharger dans le navigateur `http://172.20.10.2:8081/bank-poc-root.cer`, en remplaçant l’IP.
3. Dans les paramètres Android, rechercher **Installer un certificat**. Le chemin usuel est **Sécurité et confidentialité → Autres paramètres de sécurité → Chiffrement et identifiants** ; il varie selon le fabricant. Pour faire confiance au serveur HTTPS, installer le fichier comme **certificat d’autorité / CA**, lorsqu’il est proposé. Ce n’est pas un certificat client ni une configuration d’authentification Wi-Fi. Android peut demander le code de l’appareil et afficher un avertissement concernant l’autorité ajoutée.
4. Ouvrir le coffre HTTPS dans le navigateur et vérifier le certificat.
5. Installer **Bitwarden Password Manager**, puis choisir **Serveur auto-hébergé** et saisir l’adresse HTTPS de son PC. Si la version de l’application propose un champ de certificat pour le serveur, suivre son écran/documentation ; vérifier ensuite la connexion effective. L’acceptation du certificat par le navigateur ne prouve pas son acceptation par l’application.
6. Se connecter au même compte personnel que dans l’extension du PC.
7. Dans **Bitwarden → Paramètres → Remplissage automatique → Gestion des clés d’accès / Passkey management**, continuer vers les réglages Android et sélectionner Bitwarden comme fournisseur de passkeys.
8. Créer/utiliser une passkey sur la page de test et vérifier que Bitwarden est effectivement choisi.

Si Bitwarden refuse le certificat alors que le navigateur fonctionne, consigner OS, version de l’application et erreur ; la prise en charge des autorités utilisateur dépend du client et doit être vérifiée. Ne pas désactiver la validation HTTPS. Un certificat reconnu publiquement et un domaine stable seraient une autre configuration à préparer si nécessaire.

Les passkeys Bitwarden sur Android ne prennent pas en charge les credentials non découvrables utilisés comme second facteur ; prévoir et tester le credential découvrable du parcours wallet.

Sources : [certificats Bitwarden](https://bitwarden.com/help/certificates/), [gestion des certificats Android](https://support.google.com/pixelphone/answer/2844832?hl=en), [fournisseur Android](https://bitwarden.com/help/auto-fill-android/), [passkeys Android](https://bitwarden.com/help/storing-passkeys/). Les menus Google documentés sont indicatifs et peuvent varier.

## 7 — Vérifier la synchronisation et préparer la démo

1. Ajouter un élément de test depuis le PC et vérifier qu’il apparaît dans le même compte sur le téléphone après synchronisation.
2. Créer une passkey avec le fournisseur Bitwarden et vérifier sa disponibilité sur le deuxième appareil.
3. Rendre l’appareil initial indisponible, puis obtenir une signature vérifiée depuis le deuxième. Une simple présence dans la liste ou un message de synchronisation ne suffit pas.
4. Pour le scénario de récupération, répéter depuis une installation ou un profil vierge, connecté au **même serveur et même compte**.
5. Pour le wallet réel, vérifier la même adresse de smart account et une opération autorisée. Cette intégration reste à réaliser.
6. Facultatif : créer un deuxième compte sur une instance pour tester la séparation entre clients.

**L’adresse IP du coffre ne définit pas le RP ID du wallet.** Le frontend WebAuthn exige un nom d’hôte admissible et stable, accessible depuis les deux appareils. Une passkey créée sur localhost ne devient pas automatiquement utilisable sur le téléphone. Ce frontend n’est pas déployé par ce dépôt.

## Changer de réseau, arrêter et conserver

Si l’IP du PC change, relancer avec la nouvelle IP et mettre à jour l’adresse de serveur dans l’extension et le téléphone. Les volumes conservent les coffres et l’autorité locale. Chaque instance génère sa propre autorité ; une nouvelle instance ne partage pas automatiquement la confiance de l’ancienne.

```powershell
docker compose stop
```

L’arrêt conserve les volumes. Ne pas supprimer les volumes pour changer l’IP : ils contiennent les coffres et les clés de l’autorité. Après la démo, retirer uniquement le certificat de cette instance et la règle pare-feu si elle a été créée.

## État de vérification et configuration

Sur le PC de Kalamar, les deux services ont été lancés ; Vaultwarden était sain et le coffre répondait HTTP 200 en HTTPS avec certificat validé sous Windows. Le téléchargement du certificat dans Safari iPhone a été confirmé. Confiance/connexion mobile, Android, free-wifi, passkeys et reprise du wallet restent à tester ; les instructions ne constituent pas des résultats.

Images : Vaultwarden **1.37.4** et Caddy **2.11.7-alpine**, téléchargées pour le lancement initial. Vaultwarden n’a pas de port publié directement ; HTTPS est terminé par Caddy. Ports : 8443 pour le coffre, 8081 pour son certificat public, sur l’IP choisie ; 8443 aussi en boucle locale.

* [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
* [Version Vaultwarden](https://github.com/dani-garcia/vaultwarden/releases/tag/1.37.4)
* [Proxy recommandé](https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples)
* [Autorité locale Caddy](https://caddyserver.com/docs/caddyfile/directives/tls)
* [Schéma du POC](docs/schema.md)

Ce POC illustre un hébergement de coffres chiffrés. Il ne prouve pas à lui seul une confidentialité absolue ni une récupération après perte totale des passkeys et des moyens d’ouvrir le coffre.
