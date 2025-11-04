# 🔧 Guide de Résolution des Problèmes - Installation Sans Docker

## ❌ Problème : "stat frontend/dist: no such file or directory"

### 🔍 Cause
Le frontend Listmonk n'est pas compilé. Listmonk a besoin que le frontend Vue.js soit compilé avant de pouvoir démarrer.

### ✅ Solutions

#### Solution 1 : Utiliser le script corrigé
```bash
# Utilisez le script corrigé qui gère automatiquement la compilation
./install-no-docker-fixed.sh
```

#### Solution 2 : Compiler le frontend manuellement
```bash
# 1. Compiler le frontend
./build-frontend.sh

# 2. Puis relancer l'installation
./install-no-docker.sh
```

#### Solution 3 : Compilation manuelle détaillée
```bash
# 1. Installer Node.js si nécessaire
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Aller dans le répertoire frontend
cd frontend

# 3. Installer les dépendances
npm install
# ou
yarn install

# 4. Compiler le frontend
npm run build
# ou
yarn build

# 5. Retourner au répertoire principal
cd ..

# 6. Vérifier que frontend/dist existe
ls -la frontend/dist/

# 7. Relancer l'installation
./install-no-docker.sh
```

---

## ❌ Problème : Erreurs de mot de passe PostgreSQL

### 🔍 Cause
L'authentification PostgreSQL n'est pas configurée correctement.

### ✅ Solutions

#### Solution 1 : Utiliser le script de correction
```bash
./fix-postgres-auth.sh
```

#### Solution 2 : Configuration manuelle
```bash
# 1. Éditer pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# 2. Ajouter ces lignes AVANT les lignes existantes :
local   listmonk        listmonk                                md5
host    listmonk        listmonk        127.0.0.1/32            md5

# 3. Redémarrer PostgreSQL
sudo systemctl reload postgresql

# 4. Tester la connexion
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;"
```

---

## ❌ Problème : "Go n'est pas installé"

### ✅ Solution
```bash
# 1. Télécharger Go
wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz

# 2. Installer Go
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz

# 3. Ajouter Go au PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 4. Vérifier l'installation
go version
```

---

## ❌ Problème : "PostgreSQL n'est pas installé"

### ✅ Solution
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# Démarrer PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

---

## ❌ Problème : Port 9000 déjà utilisé

### ✅ Solutions

#### Solution 1 : Changer le port dans config.toml
```toml
[app]
address = "0.0.0.0:9001"  # Utiliser un autre port
```

#### Solution 2 : Arrêter le processus existant
```bash
# Trouver le processus
sudo lsof -i :9000

# Arrêter le processus
sudo kill -9 <PID>
```

---

## ❌ Problème : Erreur de migration de base de données

### ✅ Solutions

#### Solution 1 : Réinitialiser la base
```bash
# 1. Se connecter à PostgreSQL
sudo -u postgres psql

# 2. Supprimer et recréer la base
DROP DATABASE IF EXISTS listmonk;
DROP USER IF EXISTS listmonk;
CREATE DATABASE listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk';
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;
\q

# 3. Relancer l'installation
./install-no-docker-fixed.sh
```

---

## ❌ Problème : Interface géographique ne charge pas

### 🔍 Vérifications

#### 1. Vérifier que les tables existent
```bash
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'departement_region_mapping';"
```

#### 2. Vérifier les colonnes géographiques
```bash
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'subscribers' 
AND column_name IN ('code_insee', 'departement_numero');"
```

#### 3. Vérifier les données de référence
```bash
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT COUNT(*) as departements FROM departement_region_mapping;"
```

### ✅ Solution si les données manquent
```bash
# Basculer vers la branche géographique
git checkout feature/french-geographic-segmentation

# Appliquer les migrations
go run cmd/*.go --config config.toml --upgrade --yes
```

---

## 🆘 Diagnostic Complet

### Script de diagnostic automatique
```bash
#!/bin/bash
echo "=== DIAGNOSTIC LISTMONK ==="

echo "1. Vérification Go:"
go version 2>/dev/null || echo "❌ Go non installé"

echo "2. Vérification PostgreSQL:"
pg_isready 2>/dev/null && echo "✅ PostgreSQL actif" || echo "❌ PostgreSQL inactif"

echo "3. Vérification frontend:"
[ -d "frontend/dist" ] && [ "$(ls -A frontend/dist)" ] && echo "✅ Frontend compilé" || echo "❌ Frontend non compilé"

echo "4. Vérification base de données:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;" 2>/dev/null && echo "✅ Base accessible" || echo "❌ Base inaccessible"

echo "5. Vérification tables géographiques:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null && echo "✅ Tables géo présentes" || echo "❌ Tables géo manquantes"

echo "6. Vérification port 9000:"
lsof -i :9000 2>/dev/null && echo "⚠️ Port 9000 occupé" || echo "✅ Port 9000 libre"
```

---

## 📞 Support

Si les problèmes persistent :

1. **Vérifiez les logs** : `tail -f listmonk.log`
2. **Consultez la documentation** : [README_SANS_DOCKER.md](README_SANS_DOCKER.md)
3. **Utilisez le diagnostic** : Copiez le script de diagnostic ci-dessus
4. **Réinitialisez complètement** : Supprimez tout et recommencez

### Réinitialisation complète
```bash
# 1. Arrêter Listmonk
pkill -f "go run cmd"

# 2. Supprimer la base
sudo -u postgres psql -c "DROP DATABASE IF EXISTS listmonk; DROP USER IF EXISTS listmonk;"

# 3. Nettoyer le frontend
rm -rf frontend/dist frontend/node_modules

# 4. Relancer l'installation complète
./install-no-docker-fixed.sh
```