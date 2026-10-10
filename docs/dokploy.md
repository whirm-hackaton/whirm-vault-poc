# Vaultwarden sur VPS avec Dokploy

Le VPS héberge une instance commune. Chaque utilisateur crée son propre compte de coffre, utilisé sur ses appareils. Les coffres locaux existants ne sont pas transférés automatiquement sur le VPS.

## 1. DNS et accès réseau

Chez le fournisseur DNS de whirm.dev, créer/vérifier un enregistrement A : nom vault, valeur IP publique du VPS. Le domaine vault.whirm.dev doit atteindre ce VPS. Les ports publics 80 et 443 doivent être accessibles pour le proxy et le certificat HTTPS. Le DNS et le déploiement ne sont pas encore vérifiés par ce guide.

## 2. General : source GitHub

Dépôt : whirm-hackaton/whirm-vault-poc, branche main.
Dans le champ Compose Path / chemin du fichier Compose, sélectionner :
`compose.dokploy.yaml` (ou `./compose.dokploy.yaml` si le champ demande ce format).

Le fichier compose.yaml reste réservé au POC local avec Caddy. La variante Dokploy utilise le proxy de Dokploy pour HTTPS, le service vaultwarden sur son port interne 80 et un volume persistant vault_data monté sur /data.

## 3. Environment

Coller puis enregistrer :

```dotenv
DOMAIN=https://vault.whirm.dev
SIGNUPS_ALLOWED=true
```

DOMAIN est l'adresse publique complète. SIGNUPS_ALLOWED ouvre temporairement la création de comptes pour la démo ; sa valeur par défaut dans le Compose est false.
Les autres options sont définies dans le Compose : invitations, organisations, accès d'urgence et affichage d'indices de mot de passe désactivés.
Aucun mot de passe maître, clé de wallet ou ADMIN_TOKEN n'est requis ici. Aucun SMTP n'est configuré ; les parcours nécessitant des emails ne sont pas validés.

## 4. Domains

Ajouter et enregistrer le domaine avec :

| Champ | Valeur |
|---|---|
| Host | vault.whirm.dev |
| Service | vaultwarden |
| Container Port | 80 |
| Path | / |
| Internal Path | vide |
| Strip Path | désactivé |
| HTTPS | activé |
| Certificate | letsencrypt |

Dokploy ajoute automatiquement les labels et le réseau nécessaires au service sélectionné. Consulter Preview Compose pour vérifier le résultat. Une modification du domaine d'une application Compose exige un redéploiement.

## 5. Déployer et tester

Cliquer Deploy, suivre Deployments et Logs, puis ouvrir https://vault.whirm.dev depuis le PC et le téléphone. Le navigateur doit accepter le certificat sans profil local à installer.
Créer les comptes personnels nécessaires au POC depuis le coffre web. Ensuite remplacer SIGNUPS_ALLOWED=true par SIGNUPS_ALLOWED=false dans Environment, enregistrer et redéployer.

Conserver le volume /data lors des redéploiements : il contient les comptes et les coffres chiffrés. Prévoir une sauvegarde cohérente de ce volume avec la base SQLite ; la synchronisation entre appareils ne remplace pas une sauvegarde du serveur.

## 6. Clients Bitwarden

Installer l'extension officielle Bitwarden sur le navigateur de la démo et Bitwarden Password Manager sur le téléphone.
Dans chaque client, sélectionner Serveur auto-hébergé et saisir https://vault.whirm.dev. Se connecter au même compte personnel sur ses appareils et activer Bitwarden comme fournisseur de passkeys selon le guide iPhone/Android du README.

Le téléphone et le PC peuvent utiliser des réseaux différents, avec un accès Internet au VPS ; l'isolation entre clients d'un Wi-Fi public ne bloque plus une connexion directe au PC, puisque le coffre est sur le VPS. Un réseau peut néanmoins filtrer l'accès Internet au service.

Vérifier la synchronisation avec un élément de test, puis l'utilisation d'une passkey sur un deuxième appareil. Ce déploiement ne déploie pas le frontend wallet : son domaine/RP ID reste une configuration distincte.

## Sources

- [Compose et domaines Dokploy](https://docs.dokploy.com/docs/core/docker-compose/domains)
- [Champs du domaine et redéploiement](https://docs.dokploy.com/docs/core/domains)
- [Clients Bitwarden auto-hébergés](https://bitwarden.com/help/change-client-environment/)
