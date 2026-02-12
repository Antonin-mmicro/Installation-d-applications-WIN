# 📦 Scripts d’Installation Automatisée – PowerShell

## 📖 Description

Ce dépôt contient plusieurs scripts PowerShell permettant :

- 📥 Le téléchargement automatique d’applications depuis Internet  
- ⚙️ L’installation silencieuse (silent install)  
- ✅ La vérification de présence avant installation  
- 📂 L’extraction automatique d’archives (.zip)  
- 🧹 Le nettoyage des fichiers temporaires  
- 🔁 Une exécution idempotente (ne réinstalle pas si déjà présent)

Ces scripts ont pour objectif d’automatiser le déploiement d’outils et de configurations sur des postes Windows.

---

## 🛠 Fonctionnement général

La logique commune des scripts est la suivante :

1. Vérification si l’application ou l’outil est déjà installé  
2. Si absent :
   - Téléchargement du fichier (setup ou archive)
   - Installation silencieuse ou extraction
   - Vérification post-installation
3. Suppression des fichiers temporaires
4. Affichage d’un statut clair dans la console

---

## 💻 Prérequis

- Windows 10 / 11  
- PowerShell 5.1 ou supérieur  
- Droits administrateur (recommandé selon le logiciel)  
- Accès Internet  

---

## 🚀 Utilisation

### Exécution simple

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\NomDuScript.ps1
```

### Exécution en administrateur

Clic droit sur PowerShell → **Exécuter en tant qu’administrateur**, puis lancer le script.

---

## 🔐 Sécurité

Les scripts :

- Vérifient la présence des fichiers avant installation
- Téléchargent uniquement depuis des URLs définies dans le script
- Suppriment les fichiers temporaires après exécution
- Utilisent des paramètres d’installation silencieuse (/S, /allusers, etc.)

⚠️ Toujours tester les scripts dans un environnement de préproduction avant un déploiement massif.

---

## 🧠 Commandes PowerShell couramment utilisées

- `Test-Path` → Vérification de présence  
- `Invoke-WebRequest (iwr)` → Téléchargement  
- `Expand-Archive` → Extraction ZIP  
- `Start-Sleep` → Attente après installation  
- `Remove-Item` → Nettoyage  
- `exit 0 / exit 1` → Codes de retour  

---

## 🔄 Idempotence

Les scripts peuvent être relancés sans risque :

- ✔ Si le programme est déjà installé → arrêt propre  
- ✔ Sinon → installation automatique  

---

## 🧹 Nettoyage automatique

Les scripts suppriment :

- Les exécutables téléchargés temporairement  
- Les archives ZIP  
- Les fichiers placés dans `$env:TEMP`  

---

## 🏢 Utilisation possible en environnement professionnel

Ces scripts peuvent être utilisés dans :

- Déploiement manuel  
- Scripts de démarrage (GPO)  
- MDT  
- Intune (Win32)  
- Outils RMM  

---

## 📌 Améliorations possibles

- Ajouter une gestion d’erreurs avec `try/catch`  
- Ajouter un système de logs (.log)  
- Vérifier les codes de retour des installateurs  
- Uniformiser les variables et chemins  
- Ajouter une vérification de services prérequis si nécessaire  

---

## 👤 Auteur

Scripts développés et maintenus par :  
**[Ton Nom / Service IT]**

---

## ⚠️ Avertissement

Ces scripts sont fournis « en l’état ».  
L’auteur ne peut être tenu responsable d’un mauvais usage ou d’une modification inadaptée.
