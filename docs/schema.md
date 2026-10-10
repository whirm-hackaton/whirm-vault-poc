# Comptes, passkeys et reprise d’accès

Une instance Vaultwarden commune héberge un compte et un coffre chiffré par client. Un client se connecte au même compte depuis plusieurs appareils. La première inscription se fait depuis le coffre web Vaultwarden ; le client choisit son propre mot de passe maître. La connexion bancaire ne crée pas automatiquement le compte de coffre dans ce POC.

+```mermaid
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

    subgraph TEL["iPhone du client"]
        BW["Application Bitwarden<br/>Ouvre le coffre avec le secret du client<br/>Crée et utilise la passkey"]
        KEY["Clé privée de la passkey<br/>Protégée dans le coffre"]
        BW --- KEY
    end

    OS -->|"Confirmation du client"| BW
    BW -->|"Clé publique ou signature<br/>Jamais la clé privée"| APP

    subgraph BANK["Infrastructure de la banque simulée sur ton PC"]
        VW["Vaultwarden<br/>Une instance commune<br/>Un compte et coffre chiffré par client<br/>Stockage et synchronisation"]
        API["Backend bancaire<br/>Identité et adresse du wallet"]
    end

    BW <-->|"Synchronisation chiffrée"| VW
    APP <-->|"Identité et métadonnées publiques"| API

    WALLET["Smart account sur la blockchain<br/>Reconnaît la clé publique du client<br/>Vérifie les autorisations signées"]
    APP -->|"Création avec la clé publique<br/>Puis opérations signées"| WALLET

    subgraph RECOVERY["Après perte de l’iPhone"]
        NEW["PC ou nouvel appareil<br/>Bitwarden connecté au même coffre"]
        ACCESS["Même passkey retrouvée<br/>si le client peut déverrouiller le coffre"]
        NEW --> ACCESS
    end

    VW <-->|"Récupération du coffre chiffré"| NEW
    ACCESS -->|"Signature avec la même passkey"| WALLET
```

Les échanges WebAuthn, la synchronisation des passkeys et la reprise du smart account représentent le parcours cible, encore à tester. Le serveur local et HTTPS Windows ont été vérifiés ; le téléchargement du certificat sur iPhone a été confirmé. L’application bancaire ne remplace pas automatiquement le fournisseur Bitwarden. Le serveur ne doit pas recevoir les secrets de déchiffrement du client. La perte totale des passkeys et des moyens d’ouvrir le coffre n’est pas résolue.

Voir [le guide de lancement](../README.md) et [le wiki du POC](https://wiki.dotshark.dev/doc/passkeys-poc-vaultwarden-bancaire-schema-et-etat-des-essais-ZKwEUZioKR).
