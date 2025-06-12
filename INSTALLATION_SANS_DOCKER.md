# 🚀 INSTALLATION LISTMONK SANS DOCKER

## 📋 PRÉREQUIS

### 1. Installer PostgreSQL
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL/Rocky Linux
sudo dnf install postgresql postgresql-server postgresql-contrib
sudo postgresql-setup --initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Arch Linux
sudo pacman -S postgresql
sudo -u postgres initdb -D /var/lib/postgres/data
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### 2. Installer Go (si pas déjà fait)
```bash
# Télécharger Go 1.21+
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Ajouter au PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Vérifier
go version
```

## 🗄️ CONFIGURATION POSTGRESQL

### 1. Créer la base de données et l'utilisateur
```bash
# Se connecter en tant que postgres
sudo -u postgres psql

# Dans psql, exécuter :
CREATE DATABASE listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk';
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;
\q
```

### 2. Configurer l'accès (optionnel)
```bash
# Éditer pg_hba.conf pour autoriser les connexions locales
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Ajouter ou modifier cette ligne :
local   all             listmonk                                md5

# Redémarrer PostgreSQL
sudo systemctl restart postgresql
```

### 3. Tester la connexion
```bash
psql -U listmonk -d listmonk -h localhost
# Entrer le mot de passe : listmonk
```

## 🚀 INSTALLATION LISTMONK

### 1. Cloner le projet
```bash
git clone https://github.com/code10UD/listmonk.git
cd listmonk
git checkout feature/french-geographic-segmentation
```

### 2. Créer la configuration
```bash
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

[privacy]
individual_tracking = false
unsubscribe_header = true
allow_blocklist = true
allow_export = true
allow_wipe = true
exportable = ["profile", "subscriptions", "campaign_views", "link_clicks"]

[security]
enable_captcha = false

[upload]
provider = "filesystem"
filesystem.upload_path = "uploads"
filesystem.upload_uri = "/uploads"

[bounce]
enabled = false

[smtp]
host = "localhost"
port = 1025
auth_protocol = "none"
username = ""
password = ""
hello_hostname = ""
max_conns = 10
idle_timeout = "15s"
wait_timeout = "5s"
max_msg_retries = 2
EOF
```

### 3. Installation de base (sur master)
```bash
# Basculer sur master pour l'installation de base
git checkout master

# Installer la base de données
go run cmd/*.go --config config.toml --install --yes
```

### 4. Application des extensions géographiques
```bash
# Revenir à la branche géographique
git checkout feature/french-geographic-segmentation

# Appliquer la migration géographique
go run cmd/*.go --config config.toml --upgrade --yes
```

### 5. Ajouter des données de test (optionnel)
```bash
psql -U listmonk -d listmonk -h localhost << 'EOF'
-- Ajouter quelques abonnés de test avec données géographiques
INSERT INTO subscribers (email, name, status, code_insee, nom_commune, departement_numero, population_commune, csp) VALUES
('test.paris@example.com', 'Test Paris', 'enabled', '75101', 'Paris', '75', 2161000, 'Cadre'),
('test.lyon@example.com', 'Test Lyon', 'enabled', '69123', 'Lyon', '69', 515695, 'Employé'),
('test.marseille@example.com', 'Test Marseille', 'enabled', '13055', 'Marseille', '13', 861635, 'Ouvrier'),
('test.toulouse@example.com', 'Test Toulouse', 'enabled', '31555', 'Toulouse', '31', 471941, 'Profession libérale'),
('test.nice@example.com', 'Test Nice', 'enabled', '06088', 'Nice', '06', 342637, 'Retraité')
ON CONFLICT (email) DO NOTHING;
EOF
```

## 🎯 DÉMARRAGE

### 1. Démarrer Listmonk
```bash
# En mode développement (avec logs)
go run cmd/*.go --config config.toml

# OU en arrière-plan
nohup go run cmd/*.go --config config.toml > listmonk.log 2>&1 &

# OU compiler et exécuter
go build -o listmonk cmd/*.go
./listmonk --config config.toml
```

### 2. Accéder à l'interface
- **URL**: http://localhost:9000
- **Email**: admin
- **Mot de passe**: admin

## ✅ VÉRIFICATION

### 1. Tester la base de données
```bash
psql -U listmonk -d listmonk -h localhost -c "SELECT COUNT(*) FROM departement_region_mapping;"
# Résultat attendu : 94 départements
```

### 2. Tester les endpoints géographiques
```bash
# Backend actif
curl http://localhost:9000/api/health

# Endpoints géographiques (403 = normal sans auth)
curl -w "%{http_code}" http://localhost:9000/api/geo/regions
curl -w "%{http_code}" http://localhost:9000/api/geo/departements
```

### 3. Vérifier les logs
```bash
tail -f listmonk.log
```

## 🔧 SCRIPT D'INSTALLATION AUTOMATIQUE SANS DOCKER

Créez ce script `install-no-docker.sh` :

```bash
#!/bin/bash

echo "🚀 Installation Listmonk sans Docker"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "${BLUE}🔄 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Vérifier PostgreSQL
step "Vérification de PostgreSQL"
if ! systemctl is-active --quiet postgresql; then
    error "PostgreSQL n'est pas démarré. Démarrez-le avec: sudo systemctl start postgresql"
    exit 1
fi
success "PostgreSQL actif"

# Vérifier la connexion DB
step "Vérification de la base de données"
if ! psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    error "Impossible de se connecter à la base listmonk. Vérifiez la configuration."
    exit 1
fi
success "Base de données accessible"

# Configuration
step "Création de la configuration"
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
success "Configuration créée"

# Installation de base
step "Installation de base"
git checkout master
if go run cmd/*.go --config config.toml --install --yes; then
    success "Base installée"
else
    error "Erreur installation base"
    exit 1
fi

# Extensions géographiques
step "Application des extensions géographiques"
git checkout feature/french-geographic-segmentation
if go run cmd/*.go --config config.toml --upgrade --yes; then
    success "Extensions géographiques appliquées"
else
    error "Erreur extensions géographiques"
    exit 1
fi

# Données de test
step "Ajout de données de test"
psql -U listmonk -d listmonk -h localhost << 'EOF'
INSERT INTO subscribers (email, name, status, code_insee, nom_commune, departement_numero, population_commune, csp) VALUES
('test.paris@example.com', 'Test Paris', 'enabled', '75101', 'Paris', '75', 2161000, 'Cadre'),
('test.lyon@example.com', 'Test Lyon', 'enabled', '69123', 'Lyon', '69', 515695, 'Employé')
ON CONFLICT (email) DO NOTHING;
EOF
success "Données de test ajoutées"

echo ""
echo "🎉 INSTALLATION TERMINÉE !"
echo ""
echo "🚀 Pour démarrer Listmonk :"
echo "   go run cmd/*.go --config config.toml"
echo ""
echo "🌐 Interface : http://localhost:9000"
echo "👤 Email: admin | Mot de passe: admin"
```

## 🛠️ MAINTENANCE

### Commandes utiles
```bash
# Démarrer/arrêter PostgreSQL
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql

# Voir les logs PostgreSQL
sudo journalctl -u postgresql

# Sauvegarder la base
pg_dump -U listmonk -h localhost listmonk > backup.sql

# Restaurer la base
psql -U listmonk -h localhost listmonk < backup.sql

# Arrêter Listmonk
pkill -f "go run cmd"
# OU si compilé
pkill listmonk
```

### Dépannage
```bash
# Vérifier les ports
sudo netstat -tlnp | grep :5432  # PostgreSQL
sudo netstat -tlnp | grep :9000  # Listmonk

# Tester la connexion DB
psql -U listmonk -d listmonk -h localhost

# Logs détaillés Listmonk
go run cmd/*.go --config config.toml --verbose
```

## 🎯 AVANTAGES SANS DOCKER

✅ **Performance** : Accès direct à PostgreSQL  
✅ **Simplicité** : Moins de couches d'abstraction  
✅ **Contrôle** : Configuration fine de PostgreSQL  
✅ **Ressources** : Moins de consommation mémoire  
✅ **Intégration** : Meilleure intégration système  

---

*Guide d'installation sans Docker - Version 1.0*  
*Listmonk Géographique Français*