# 🚀 Installation Listmonk sans Docker - Extensions Géographiques Françaises (Version Corrigée)

Ce guide vous permet d'installer Listmonk avec les extensions géographiques françaises directement sur votre serveur, sans utiliser Docker.

## 📋 Prérequis

- **Système d'exploitation** : Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **Go** : Version 1.19 ou supérieure
- **PostgreSQL** : Version 12 ou supérieure
- **Node.js** : Version 16+ (pour compiler le frontend)
- **Accès root** ou sudo sur le serveur

## 🔧 Installation Automatique (Recommandée)

### Script d'installation complet corrigé

```bash
# 1. Cloner le repository
git clone https://github.com/code10UD/listmonk.git
cd listmonk

# 2. Rendre les scripts exécutables
chmod +x install-no-docker-fixed.sh
chmod +x build-frontend.sh
chmod +x diagnostic.sh

# 3. Diagnostic préalable (optionnel)
./diagnostic.sh

# 4. Lancer l'installation corrigée
./install-no-docker-fixed.sh
```

Le script corrigé va automatiquement :
- ✅ Vérifier les prérequis (Go, PostgreSQL, Node.js)
- ✅ **Compiler le frontend automatiquement**
- ✅ Configurer PostgreSQL avec l'utilisateur `listmonk`
- ✅ Créer la base de données `listmonk`
- ✅ Installer Listmonk avec les extensions géographiques
- ✅ Ajouter les données de référence françaises (départements, régions)
- ✅ Configurer l'authentification

## 🛠️ Résolution du Problème Frontend

### ❌ Erreur : "stat frontend/dist: no such file or directory"

Cette erreur indique que le frontend n'est pas compilé. **Solutions** :

#### Solution 1 : Script automatique
```bash
./build-frontend.sh
```

#### Solution 2 : Compilation manuelle
```bash
# 1. Installer Node.js si nécessaire
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Compiler le frontend
cd frontend
npm install
npm run build
cd ..

# 3. Vérifier la compilation
ls -la frontend/dist/
```

#### Solution 3 : Utiliser le script corrigé
```bash
# Le script corrigé gère automatiquement la compilation
./install-no-docker-fixed.sh
```

## 🔍 Diagnostic et Dépannage

### Script de diagnostic complet
```bash
# Analyser tous les composants
./diagnostic.sh
```

### Problèmes courants et solutions

#### 1. Frontend non compilé
```bash
# Compiler le frontend
./build-frontend.sh
```

#### 2. Erreurs PostgreSQL
```bash
# Corriger l'authentification
./fix-postgres-auth.sh
```

#### 3. Go non installé
```bash
# Installer Go
wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

#### 4. Node.js non installé
```bash
# Installer Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## 🛠️ Installation Manuelle (Avancée)

Si vous préférez une installation étape par étape :

### 1. Installation des prérequis

```bash
# Go
wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# PostgreSQL
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Démarrer PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Configuration de PostgreSQL

```bash
# Se connecter en tant qu'utilisateur postgres
sudo -u postgres psql

# Créer la base de données et l'utilisateur
CREATE DATABASE listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk';
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;
\q
```

### 3. Configuration de l'authentification PostgreSQL

```bash
# Éditer le fichier pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Ajouter ces lignes AVANT les lignes existantes :
local   listmonk        listmonk                                md5
host    listmonk        listmonk        127.0.0.1/32            md5

# Redémarrer PostgreSQL
sudo systemctl reload postgresql
```

### 4. Compilation du frontend

```bash
# Aller dans le répertoire frontend
cd frontend

# Installer les dépendances
npm install

# Compiler le frontend
npm run build

# Vérifier la compilation
ls -la dist/

# Retourner au répertoire principal
cd ..
```

### 5. Installation de Listmonk

```bash
# Cloner le repository
git clone https://github.com/code10UD/listmonk.git
cd listmonk

# Basculer vers la branche avec extensions géographiques
git checkout feature/french-geographic-segmentation

# Créer le fichier de configuration
cat > config.toml << EOF
[db]
host = "localhost"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"

[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "admin"
EOF

# Installer la base de données (branche master d'abord)
git checkout master
go run cmd/*.go --config config.toml --install --yes

# Appliquer les migrations géographiques
git checkout feature/french-geographic-segmentation
go run cmd/*.go --config config.toml --upgrade --yes
```

## 🚀 Démarrage

```bash
# Démarrer Listmonk
go run cmd/*.go --config config.toml

# Ou en arrière-plan
nohup go run cmd/*.go --config config.toml > listmonk.log 2>&1 &
```

## 🌐 Accès à l'interface

- **URL** : http://votre-serveur:9000
- **Email** : admin
- **Mot de passe** : admin

⚠️ **Important** : Changez le mot de passe admin après la première connexion !

## 📍 Fonctionnalités Géographiques

### Nouvelles fonctionnalités disponibles :

1. **Segmentation par région française** (12 régions)
2. **Segmentation par département** (94 départements + DOM-TOM)
3. **Données INSEE intégrées**
4. **Interface de saisie géographique** dans la fiche abonné
5. **API REST pour les données géographiques**

### Interface géographique :

Dans la fiche d'un abonné, vous trouverez un onglet **"geo.title"** avec :
- **Région** : Menu déroulant des régions françaises
- **Département** : Menu déroulant des départements (filtré par région)
- **Commune** : Champ de recherche de commune
- **Code INSEE** : Code commune INSEE
- **Code postal** : Code postal
- **CSP** : Catégorie socio-professionnelle
- **Âge** : Âge de l'abonné

### Endpoints API géographiques :

- `GET /api/geo/regions` - Liste des régions françaises
- `GET /api/geo/departements` - Liste des départements
- `GET /api/geo/departements/{region}` - Départements d'une région

### Nouveaux champs abonnés :

- **Code INSEE** : Code commune INSEE
- **Nom commune** : Nom de la commune
- **Département** : Numéro de département
- **Population** : Population de la commune
- **CSP** : Catégorie socio-professionnelle
- **Âge** : Âge de l'abonné
- **Code postal** : Code postal

## 🆘 Dépannage Complet

### Scripts de dépannage disponibles :

```bash
# Diagnostic complet
./diagnostic.sh

# Compilation du frontend
./build-frontend.sh

# Correction PostgreSQL
./fix-postgres-auth.sh

# Installation corrigée
./install-no-docker-fixed.sh
```

### Guide de résolution détaillé :

```bash
# Consulter le guide complet
cat GUIDE_RESOLUTION_PROBLEMES.md
```

### Problèmes courants :

#### 1. Frontend non compilé
```bash
# Solution automatique
./build-frontend.sh

# Ou manuel
cd frontend && npm install && npm run build && cd ..
```

#### 2. Erreur de connexion PostgreSQL
```bash
# Vérifier que PostgreSQL est actif
sudo systemctl status postgresql

# Corriger l'authentification
./fix-postgres-auth.sh

# Tester la connexion
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;"
```

#### 3. Port 9000 déjà utilisé
```bash
# Trouver le processus
sudo lsof -i :9000

# Changer le port dans config.toml
[app]
address = "0.0.0.0:9001"
```

#### 4. Tables géographiques manquantes
```bash
# Basculer vers la branche géographique
git checkout feature/french-geographic-segmentation

# Appliquer les migrations
go run cmd/*.go --config config.toml --upgrade --yes
```

### Réinitialisation complète :

```bash
# Arrêter Listmonk
pkill -f "go run cmd"

# Supprimer la base
sudo -u postgres psql -c "DROP DATABASE IF EXISTS listmonk; DROP USER IF EXISTS listmonk;"

# Nettoyer le frontend
rm -rf frontend/dist frontend/node_modules

# Relancer l'installation complète
./install-no-docker-fixed.sh
```

## 📞 Support

- **Guide de résolution** : [GUIDE_RESOLUTION_PROBLEMES.md](GUIDE_RESOLUTION_PROBLEMES.md)
- **Documentation géographique** : [README_GEOGRAPHIC.md](README_GEOGRAPHIC.md)
- **Issues** : https://github.com/code10UD/listmonk/issues

## 🎯 Prochaines étapes

Après l'installation :

1. **Configurez SMTP** pour l'envoi d'emails
2. **Importez vos listes** d'abonnés
3. **Créez vos templates** d'emails
4. **Testez la segmentation géographique**
5. **Configurez les sauvegardes automatiques**

---

✨ **Félicitations !** Listmonk avec les extensions géographiques françaises est maintenant installé et prêt à l'emploi !

## 🔧 Scripts Disponibles

- `install-no-docker-fixed.sh` - Installation complète corrigée
- `build-frontend.sh` - Compilation du frontend
- `diagnostic.sh` - Diagnostic complet du système
- `fix-postgres-auth.sh` - Correction authentification PostgreSQL
- `test-install-no-docker.sh` - Test de l'installation