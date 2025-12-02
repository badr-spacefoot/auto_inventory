# 🖥️ Inventaire Informatique – Scripts Automatisés (Windows & macOS)

Ce dépôt contient les scripts d’inventaire informatique utilisés chez **Spacefoot**  
pour collecter automatiquement les informations techniques des postes utilisateurs  
et synchroniser ces données vers une base centralisée dans Google Sheets (via Google Apps Script).

L’objectif :  
- disposer d’un inventaire **toujours à jour**,  
- sans installation locale,  
- sans erreurs humaines,  
- avec un historique clair des mouvements de matériel.

---

## 🚀 Fonctionnalités principales

### 🎯 Collecte automatique (Windows & macOS)
Le script récupère automatiquement :
- Modèle de l’ordinateur  
- Numéro de série  
- Fabricant  
- Version de l’OS  
- CPU  
- RAM  
- Adresse IP interne  
- Adresse MAC (identifiant unique de la machine)  
- Nom de la machine  
- Nom de l’utilisateur OS  

### 🧑‍💼 Informations utilisateur intégrées
Lors du lancement, l’utilisateur renseigne :
- **Prénom** (automatiquement formaté en “Nom propre”)  
- **Nom** (automatiquement mis en MAJUSCULE)  
- **Team** (sélection via menu interactif ou liste Windows/Mac)
- **Établissement** (liste complète des sites Spacefoot)

### 📡 Synchronisation en temps réel vers Google Sheets
Le script envoie les données à une **Web App Google Apps Script** qui gère :  
- l’inventaire principal (`Données`)  
- l’historique (`Historique`)

La feuille **Données** contient *une seule ligne par machine* (clé = MAC).  
La feuille **Historique** garde *toutes les attributions et changements*.

### 🔄 Déploiement centralisé (Git)
Les utilisateurs n’ont jamais besoin de mettre à jour leurs scripts.  
Le lanceur Windows/macOS télécharge automatiquement la **dernière version** depuis GitHub/GitLab.

### 🖥️ UX améliorée (Windows)
Un mini-UI en console (style BIOS) :
- navigation avec **flèches ↑ ↓**
- sélection / validation avec **Entrée**
- écran de récapitulatif
- confirmation avant synchro

---
