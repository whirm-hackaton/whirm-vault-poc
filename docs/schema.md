# Comptes, passkeys et reprise d’accès

Le POC utilise une instance commune sur VPS à **https://vault.whirm.dev**, gérée par Dokploy. Chaque client crée son compte personnel depuis le coffre web, choisit son mot de passe maître et utilise le même compte sur ses appareils. La connexion bancaire ne crée pas automatiquement le compte de coffre.

```mermaid
flowchart TB
    U["Client : créer mon wallet<br/>ou autoriser une transaction"]
    APP["Notre application bancaire / wallet"]
    OS["Navigateur ou système de l’appareil<br/>Demande la création ou l’utilisation d’une passkey"]

    REG["Première utilisation : un compte par client<br/>Inscription depuis le coffre web Vaultwarden"]
    INIT["Sur l’appareil du client<br/>Email et mot de passe maître personnel<br/>Initialisation du chiffrement du coffre"]
    U -->|"Inscription initiale du coffre"| REG
    REG --> INIT
    INIT -->|"Enregistrement du compte<br/>et données chiffrées"| VW
    INIT -->|"Connexion au même compte<br/>sur chaque appareil"| BW

    U --> APP
    APP --> OS

    subgraph TEL["Téléphone du client : iPhone ou Android"]
        BW["Application Bitwarden<br/>Ouvre le coffre avec le secret du client<br/>Crée et utilise la passkey"]
        KEY["Clé privée de la passkey<br/>Protégée dans le coffre"]
        BW --- KEY
    end

    OS -->|"Confirmation du client"| BW
    BW -->|"Clé publique ou signature<br/>Jamais la clé privée"| APP

    subgraph BANK["VPS : coffre bancaire simulé"]
        VW["Vaultwarden — vault.whirm.dev<br/>Une instance commune sur VPS / Dokploy<br/>Un compte et coffre chiffré par client<br/>Stockage et synchronisation"]
        API["Backend bancaire<br/>Identité et adresse du wallet"]
    end

    BW <-->|"Synchronisation chiffrée"| VW
    APP <-->|"Identité et métadonnées publiques"| API

    WALLET["Smart account sur la blockchain<br/>Reconnaît la clé publique du client<br/>Vérifie les autorisations signées"]
    APP -->|"Création avec la clé publique<br/>Puis opérations signées"| WALLET

    subgraph RECOVERY["Après perte du téléphone"]
        NEW["PC ou nouvel appareil<br/>Bitwarden connecté au même coffre"]
        ACCESS["Même passkey retrouvée<br/>si le client peut déverrouiller le coffre"]
        NEW --> ACCESS
    end

    VW <-->|"Récupération du coffre chiffré"| NEW
    ACCESS -->|"Signature avec la même passkey"| WALLET
```

Les échanges WebAuthn, la synchronisation des passkeys et la reprise du smart account représentent le parcours cible, encore à tester. La configuration Compose VPS est validée ; DNS, déploiement HTTPS et clients restent à vérifier. Le proxy Dokploy fournit HTTPS avec un certificat public valide.

Le serveur Vaultwarden est hébergé sur le VPS ; le backend bancaire est représenté pour expliquer son rôle, et son hébergement n’est pas défini par ce dépôt. L’application bancaire ne remplace pas le fournisseur Bitwarden. Notre API ne reçoit ni mot de passe maître ni clé privée. La perte totale des passkeys et des moyens d’ouvrir le coffre n’est pas résolue.

Le PC et le téléphone peuvent utiliser des réseaux différents avec accès Internet au VPS. Sur PC, installer l’extension Bitwarden même si son installation est proposée automatiquement. Sur téléphone, installer Bitwarden Password Manager et choisir le serveur https://vault.whirm.dev. Un certificat HTTPS public valide ne nécessite aucun profil à installer.

Le domaine du coffre ne définit pas automatiquement l’origine/RP ID du frontend wallet. Voir [le guide](../README.md), le [déploiement Dokploy](dokploy.md) et [le wiki du POC](https://wiki.dotshark.dev/doc/passkeys-poc-vaultwarden-bancaire-schema-et-etat-des-essais-ZKwEUZioKR).
