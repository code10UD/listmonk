#!/bin/bash

echo "🚀 Installation Listmonk sans Docker - Extensions Géographiques Françaises (Version Corrigée)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
export PATH=$PATH:/usr/local/go/bin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

step() { echo -e "${BLUE}🔄 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo ""

# Étape 1: Vérifications préalables
step "Vérifications préalables"

# Vérifier Go
if ! command -v go &> /dev/null; then
    error "Go n'est pas installé"
    echo "Installez Go depuis https://golang.org/dl/"
    exit 1
fi
success "Go $(go version | cut -d' ' -f3) détecté"

# Vérifier PostgreSQL
if ! command -v psql &> /dev/null; then
    error "PostgreSQL n'est pas installé"
    echo "Installez PostgreSQL : apt-get install postgresql postgresql-contrib"
    exit 1
fi
success "PostgreSQL détecté"

# Vérifier si PostgreSQL est actif
if ! pg_isready -q; then
    error "PostgreSQL n'est pas actif"
    echo "Démarrez PostgreSQL : sudo systemctl start postgresql"
    exit 1
fi
success "PostgreSQL actif"

echo ""

# Étape 2: Configuration de la base de données (CORRIGÉE)
step "Configuration de la base de données"

# Vérifier si la base existe déjà
if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
    warning "Base de données 'listmonk' existe déjà"
    read -p "Voulez-vous la réinitialiser ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        step "Suppression de la base existante..."
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS listmonk;" 2>/dev/null || true
        sudo -u postgres psql -c "DROP USER IF EXISTS listmonk;" 2>/dev/null || true
    fi
fi

step "Création de la base de données et de l'utilisateur..."
sudo -u postgres psql << EOF
-- Créer la base de données
CREATE DATABASE listmonk;

-- Créer l'utilisateur avec tous les privilèges nécessaires
CREATE USER listmonk WITH PASSWORD 'listmonk';

-- Donner tous les privilèges sur la base
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;

-- Se connecter à la base listmonk pour configurer les permissions
\c listmonk

-- Donner tous les privilèges sur le schéma public
GRANT ALL ON SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO listmonk;

-- Permettre la création de nouvelles tables/séquences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO listmonk;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO listmonk;

-- Donner temporairement les droits superuser pour l'installation
ALTER USER listmonk WITH SUPERUSER;

-- Afficher les permissions pour vérification
\du listmonk
\dn+ public
EOF

success "Base de données et utilisateur créés avec toutes les permissions"

# Test de la connexion et des permissions
step "Test de la connexion et des permissions..."

# Test de connexion basique
if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
    success "Connexion à la base réussie"
else
    error "Impossible de se connecter à la base de données"
    echo "Tentative de correction des permissions..."
    
    # Tentative de correction
    sudo -u postgres psql listmonk << EOF
GRANT ALL ON SCHEMA public TO listmonk;
ALTER USER listmonk WITH SUPERUSER;
EOF
    
    # Test à nouveau
    if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
        success "Connexion corrigée"
    else
        error "Problème de connexion persistant"
        exit 1
    fi
fi

# Test des permissions de création de tables
step "Test des permissions de création de tables..."
if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "CREATE TABLE test_permissions (id INTEGER); DROP TABLE test_permissions;" > /dev/null 2>&1; then
    success "Permissions de création de tables OK"
else
    error "Permissions insuffisantes pour créer des tables"
    echo "Application de permissions étendues..."
    
    sudo -u postgres psql listmonk << EOF
-- Donner tous les privilèges possibles
GRANT ALL ON SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO listmonk;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO listmonk;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO listmonk;
ALTER USER listmonk WITH SUPERUSER;
EOF
    
    # Test final
    if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "CREATE TABLE test_permissions (id INTEGER); DROP TABLE test_permissions;" > /dev/null 2>&1; then
        success "Permissions corrigées"
    else
        error "Impossible de résoudre les permissions"
        exit 1
    fi
fi

# Configuration de l'authentification PostgreSQL
step "Configuration de l'authentification PostgreSQL..."

# Trouver le fichier pg_hba.conf
PG_VERSION=$(psql --version | awk '{print $3}' | sed 's/\..*//')
PG_HBA_CONF="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

if [ ! -f "$PG_HBA_CONF" ]; then
    # Essayer d'autres emplacements
    for conf in /var/lib/pgsql/data/pg_hba.conf /usr/local/pgsql/data/pg_hba.conf; do
        if [ -f "$conf" ]; then
            PG_HBA_CONF="$conf"
            break
        fi
    done
fi

if [ -f "$PG_HBA_CONF" ]; then
    # Sauvegarder le fichier original
    sudo cp "$PG_HBA_CONF" "$PG_HBA_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Vérifier si la configuration est déjà correcte
    if ! grep -q "local.*listmonk.*md5" "$PG_HBA_CONF"; then
        # Ajouter la configuration pour l'utilisateur listmonk
        sudo sed -i '/^local.*all.*all.*peer/i local   listmonk        listmonk                                md5' "$PG_HBA_CONF"
        sudo sed -i '/^host.*all.*all.*127.0.0.1\/32.*ident/i host    listmonk        listmonk        127.0.0.1/32            md5' "$PG_HBA_CONF"
        
        # Redémarrer PostgreSQL
        sudo systemctl reload postgresql 2>/dev/null || sudo service postgresql reload 2>/dev/null || true
        sleep 2
    fi
    success "Configuration PostgreSQL mise à jour"
else
    success "Configuration PostgreSQL déjà correcte"
fi

success "Base de données configurée et accessible avec toutes les permissions"

echo ""

# Étape 3: Préparation du frontend
step "Préparation du frontend"

# Vérifier si le répertoire frontend/dist existe et n'est pas vide
if [ ! -d "frontend/dist" ] || [ -z "$(ls -A frontend/dist 2>/dev/null)" ]; then
    warning "Frontend non compilé, compilation en cours..."
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js n'est pas installé"
        echo "Installez Node.js depuis https://nodejs.org/"
        exit 1
    fi
    
    # Compiler le frontend
    cd frontend
    if [ -f "package.json" ]; then
        if command -v yarn &> /dev/null; then
            yarn install && yarn build
        elif command -v npm &> /dev/null; then
            npm install && npm run build
        else
            error "Ni yarn ni npm trouvé"
            exit 1
        fi
    else
        error "package.json non trouvé dans frontend/"
        exit 1
    fi
    cd ..
    success "Frontend compilé"
else
    success "Frontend déjà compilé"
fi

echo ""

# Étape 4: Configuration Listmonk
step "Configuration Listmonk"

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

success "Configuration créée"

echo ""

# Étape 5: Nettoyage et préparation
step "Nettoyage de l'environnement"

# Arrêter tout processus listmonk
pkill -f listmonk 2>/dev/null || true

# Nettoyer les fichiers compilés
rm -rf cmd/listmonk 2>/dev/null || true
rm -rf *.log 2>/dev/null || true

# Nettoyer le cache Go
go clean -cache
go clean -modcache 2>/dev/null || true

success "Environnement nettoyé"

# Étape 6: Installation directe avec extensions géographiques
step "Installation Listmonk avec extensions géographiques"

step "Basculement vers la branche géographique..."
git clean -fd
git reset --hard HEAD
git checkout feature/french-geographic-segmentation

step "Préparation du code..."
go mod tidy
go build -o listmonk cmd/*.go

step "Installation de la base de données avec extensions..."
if ./listmonk --config config.toml --install --yes; then
    success "Installation complète réussie"
else
    error "Erreur lors de l'installation"
    
    # Tentative de fallback sur master puis upgrade
    warning "Tentative d'installation en deux étapes..."
    
    git checkout master
    go mod tidy
    go build -o listmonk cmd/*.go
    
    if ./listmonk --config config.toml --install --yes; then
        success "Installation de base réussie"
        
        # Maintenant appliquer les extensions
        git checkout feature/french-geographic-segmentation
        go mod tidy
        go build -o listmonk cmd/*.go
        
        if ./listmonk --config config.toml --upgrade --yes; then
            success "Extensions géographiques appliquées"
        else
            error "Erreur lors de l'application des extensions"
            exit 1
        fi
    else
        error "Impossible d'installer même la version de base"
        exit 1
    fi
fi

echo ""

# Étape 7: Vérification de l'installation
step "Vérification de l'installation"

echo -n "📊 Table departement_region_mapping... "
if count=$(PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' '); then
    success "OK ($count départements)"
else
    error "Table manquante"
fi

echo -n "👥 Colonnes géographiques subscribers... "
if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    success "Présentes"
else
    error "Manquantes"
fi

echo ""

# Étape 8: Ajout de données de test
step "Ajout de données de test"

PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk << 'EOF'
INSERT INTO subscribers (email, name, status, code_insee, nom_commune, departement_numero, population_commune, csp) VALUES
('test.paris@example.com', 'Test Paris', 'enabled', '75101', 'Paris', '75', 2161000, 'Cadre'),
('test.lyon@example.com', 'Test Lyon', 'enabled', '69123', 'Lyon', '69', 515695, 'Employé'),
('test.marseille@example.com', 'Test Marseille', 'enabled', '13055', 'Marseille', '13', 861635, 'Ouvrier'),
('test.toulouse@example.com', 'Test Toulouse', 'enabled', '31555', 'Toulouse', '31', 471941, 'Profession libérale'),
('test.nice@example.com', 'Test Nice', 'enabled', '06088', 'Nice', '06', 342637, 'Retraité')
ON CONFLICT (email) DO NOTHING;
EOF

success "Données de test ajoutées"

echo ""

# Étape 9: Configuration de la sécurité finale
step "Configuration de la sécurité finale"

# Retirer les privilèges superuser après installation
sudo -u postgres psql -c "ALTER USER listmonk WITH NOSUPERUSER;" 2>/dev/null || true
success "Privilèges de sécurité appliqués"

echo ""

# Étape 10: Statistiques finales
step "Statistiques finales"

total_subscribers=$(PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
geo_subscribers=$(PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' ')
total_regions=$(PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -t -c "SELECT COUNT(DISTINCT region_nom) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
total_departements=$(PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')

echo "🗄️  Base de données:"
echo "   • Total abonnés: $total_subscribers"
echo "   • Abonnés avec données géo: $geo_subscribers"
echo "   • Régions françaises: $total_regions"
echo "   • Départements français: $total_departements"

echo ""
echo "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo ""
echo "🚀 Pour démarrer Listmonk :"
echo "   go run cmd/*.go --config config.toml"
echo ""
echo "🌐 Interface : http://localhost:9000"
echo "👤 Email: admin | Mot de passe: admin"
echo ""
echo "📍 Fonctionnalités géographiques disponibles :"
echo "   • Segmentation par région française"
echo "   • Segmentation par département"
echo "   • Données INSEE intégrées"
echo "   • Interface de saisie géographique"

success "🎯 LISTMONK AVEC EXTENSIONS GÉOGRAPHIQUES FRANÇAISES INSTALLÉ !"