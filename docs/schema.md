# Comptes, passkeys et reprise d’accès

Chaque membre lance sa propre instance Vaultwarden sur son PC et crée son compte de test personnel. Il n’est pas nécessaire de créer quatre comptes sur chaque instance. Les instances ne synchronisent pas leurs données entre elles. Dans une future banque, un serveur pourrait héberger plusieurs comptes clients séparés. Un client se connecte au même compte depuis plusieurs appareils. La première inscription se fait depuis le coffre web Vaultwarden ; le client choisit son propre mot de passe maître. La connexion bancaire ne crée pas automatiquement le compte de coffre dans ce POC.

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

    subgraph BANK["Instance locale propre à chaque membre sur son PC"]
        VW["Vaultwarden<br/>Une instance par PC de démonstration<br/>Compte de test personnel<br/>Stockage et synchronisation"]
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

Les échanges WebAuthn, la synchronisation des passkeys et la reprise du smart account représentent le parcours cible, encore à tester. Le serveur local et HTTPS Windows ont été vérifiés ; le téléchargement du certificat sur iPhone a été confirmé. L’application bancaire ne remplace pas automatiquement le fournisseur Bitwarden. Le serveur ne doit pas recevoir les secrets de déchiffrement du client. La perte totale des passkeys et des moyens d’ouvrir le coffre n’est pas résolue.

Voir [le guide de lancement](../README.md) et [le wiki du POC](https://wiki.dotshark.dev/doc/passkeys-poc-vaultwarden-bancaire-schema-et-etat-des-essais-ZKwEUZioKR).

Pour accéder à son instance, le téléphone et le PC doivent pouvoir communiquer sur le réseau choisi. Un free-wifi public/invité peut isoler les appareils ; l’accès local et la confiance HTTPS doivent être testés séparément. Chaque téléphone installe le certificat de son propre PC. Sur PC, installer et configurer l’extension Bitwarden dans le navigateur de la démo, même si l’installation est proposée automatiquement. Le [guide](../README.md) couvre iPhone et Android.
