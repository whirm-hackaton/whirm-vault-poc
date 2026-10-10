# Coffre bancaire sur VPS — Vaultwarden

Le POC utilise exclusivement **une instance Vaultwarden commune sur VPS, gérée par Dokploy**, à l’adresse **https://vault.whirm.dev**. Chaque utilisateur possède son compte et son coffre personnels, utilisés sur tous ses appareils. Le serveur stocke et synchronise les coffres chiffrés ; les clients Bitwarden ouvrent le coffre et utilisent les passkeys côté appareil.

## Déployer le serveur

Suivre le [guide Dokploy](docs/dokploy.md). Dans Dokploy, sélectionner la branche `main` et le fichier `compose.dokploy.yaml`.

Dans **Environment**, enregistrer :

```dotenv
DOMAIN=https://vault.whirm.dev
SIGNUPS_ALLOWED=true
```

Configurer le DNS du domaine vers l’IP publique du VPS et, dans **Domains**, choisir `vault.whirm.dev`, service `vaultwarden`, port interne `80`, HTTPS activé, certificat `letsencrypt`. Enregistrer puis déployer. Dokploy gère le proxy et le certificat HTTPS ; le volume `vault_data` conserve les données dans `/data`.

Après création des comptes nécessaires, passer `SIGNUPS_ALLOWED=false`, enregistrer et redéployer. Aucun nombre fixe de comptes n’est requis : un compte par personne jouant un client, jamais un compte partagé par l’équipe.

## Préparer son compte et le navigateur

1. Ouvrir https://vault.whirm.dev et vérifier que le certificat HTTPS est accepté.
2. Créer son compte depuis le coffre web, avec son email et son **mot de passe maître personnel**, distinct du mot de passe bancaire.
3. **Installer l’extension officielle Bitwarden dans le navigateur de la démo**, même si son installation est automatiquement proposée. Le coffre web ou l’application desktop seuls ne remplacent pas cette extension dans notre parcours navigateur.
4. Dans l’extension, sélectionner **Serveur auto-hébergé / Self-hosted**, renseigner `https://vault.whirm.dev`, puis se connecter au compte personnel.
5. Vérifier les réglages d’enregistrement/utilisation des passkeys et choisir explicitement Bitwarden lors de leur création.

Le client initialise le chiffrement sur l’appareil de l’utilisateur. Notre backend bancaire ne choisit ni ne reçoit le mot de passe maître et ne crée pas automatiquement le compte de coffre. Aucun SMTP ni panneau administrateur n’est configuré ; les fonctions nécessitant des emails restent hors validation.

## Setup iPhone

Passkeys Bitwarden : **iOS 17+**, selon compatibilité du navigateur et de la version de l’application.

1. Installer **Bitwarden Password Manager**, distinct de Bitwarden Authenticator.
2. Choisir **Serveur auto-hébergé**, saisir `https://vault.whirm.dev` et se connecter au même compte que sur le PC.
3. Dans **Réglages → Général → Remplissage automatique et mots de passe**, activer le remplissage et sélectionner Bitwarden. Selon la version d’iOS : **Mots de passe → Options des mots de passe**.
4. Lors de la création/utilisation d’une passkey, choisir Bitwarden.

Avec le certificat HTTPS public valide de Dokploy, aucune installation de profil/certificat n’est nécessaire.

## Setup Android

Passkeys Bitwarden : **Android 14+**, selon compatibilité de l’appareil, du navigateur et de l’application.

1. Installer **Bitwarden Password Manager**.
2. Choisir **Serveur auto-hébergé**, saisir `https://vault.whirm.dev` et se connecter au même compte que sur le PC.
3. Dans **Bitwarden → Paramètres → Remplissage automatique → Gestion des clés d’accès / Passkey management**, suivre l’ouverture des paramètres Android et sélectionner Bitwarden comme fournisseur. Les menus varient selon le fabricant.
4. Lors de la création/utilisation d’une passkey, choisir Bitwarden et vérifier son utilisation effective.

Aucun certificat d’autorité à importer avec un certificat HTTPS public valide. Sur Android, Bitwarden ne prend pas en charge les credentials non découvrables utilisés comme second facteur ; prévoir et vérifier le credential découvrable du parcours wallet.

## Réseau de la démo

Le PC et le téléphone ont besoin d’un accès Internet au VPS ; ils peuvent être sur des réseaux différents. Un free-wifi qui isole les appareils entre eux ne bloque pas en lui-même ce parcours. Un portail captif ou un filtrage Internet peut toutefois empêcher l’accès à https://vault.whirm.dev : vérifier cette adresse depuis chaque appareil.

## Vérifier la synchronisation et la reprise

1. Créer un élément de test sur le PC et vérifier qu’il apparaît sur le téléphone dans le même compte après synchronisation.
2. Créer une passkey via notre frontend ou une page de test WebAuthn, avec Bitwarden sélectionné.
3. Vérifier une signature depuis un deuxième appareil, en rendant le premier indisponible.
4. Recommencer depuis une installation/profil vierge, connecté au **même serveur et même compte**.
5. Pour le wallet, choisir **Retrouver mon wallet**, utiliser la passkey existante et vérifier la même adresse de smart account, puis une opération autorisée. Ne pas créer automatiquement une nouvelle passkey.
6. Tester la séparation entre deux comptes distincts.

Une passkey listée dans le coffre ou un indicateur de synchronisation ne prouve pas à lui seul le contrôle du wallet depuis un autre appareil.

## Architecture et limites

Voir le [schéma](docs/schema.md) et le [plan frontend](https://wiki.dotshark.dev/doc/passkeys-plan-dimplementation-frontend-et-parcours-explique-vOIPvaiKrI).

**vault.whirm.dev est le domaine du coffre, pas automatiquement le RP ID du wallet.** Ce dépôt ne déploie pas le frontend wallet. Son origine HTTPS et son RP ID doivent être fixés séparément avant la création des passkeys.

L’API bancaire conserve seulement les métadonnées publiques nécessaires. Le smart account cible est initialisé avec la passkey du client comme seul propriétaire, sans clé bancaire ni clé d’équipe ; cette intégration reste à vérifier. L’hébergement de coffres chiffrés ne prouve pas à lui seul une confidentialité absolue. Les audits Bitwarden ne valident pas automatiquement Vaultwarden, qui est un serveur communautaire distinct.

La reprise exige une passkey sauvegardée et les moyens d’ouvrir le coffre. La perte totale de ces moyens n’est pas résolue ; la synchronisation ne révoque pas une copie sur un appareil volé.

## Persistance et état des validations

Conserver le volume `vault_data` entre déploiements. Prévoir une sauvegarde cohérente de `/data`, notamment SQLite : la synchronisation des appareils ne remplace pas une sauvegarde du VPS.

**Réalisé :** fichier Compose VPS, guide Dokploy et schéma publiés ; configuration Compose validée. Le dépôt est intégré à Dokploy selon Kalamar.

**À vérifier :** DNS vers le bon VPS, déploiement, certificat public, ouverture sur PC/iPhone/Android, comptes, connexion des clients, synchronisation, passkeys et reprise du wallet. Aucun succès de ces essais n’est déclaré par la documentation.

## Sources

- [Vaultwarden 1.37.4](https://github.com/dani-garcia/vaultwarden/releases/tag/1.37.4)
- [Domaines Compose Dokploy](https://docs.dokploy.com/docs/core/docker-compose/domains)
- [Clients Bitwarden auto-hébergés](https://bitwarden.com/help/change-client-environment/)
- [Passkeys Bitwarden](https://bitwarden.com/help/storing-passkeys/)
- [Réglages iOS](https://bitwarden.com/help/auto-fill-ios/)
- [Réglages Android](https://bitwarden.com/help/auto-fill-android/)
