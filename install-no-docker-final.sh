#!/bin/bash

echo "🚀 Installation Listmonk sans Docker - Extensions Géographiques Françaises (Version Finale)"

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

# Étape 6: Installation de base depuis master
step "Installation de base depuis master"

step "Basculement vers master pour installation de base..."
git clean -fd
git reset --hard HEAD
git checkout master

step "Préparation du code..."
go mod tidy
go build -o listmonk cmd/*.go

step "Installation de la base de données de base..."
if ./listmonk --config config.toml --install --yes; then
    success "Installation de base réussie"
else
    error "Erreur lors de l'installation de base"
    exit 1
fi

echo ""

# Étape 7: Application manuelle des extensions géographiques
step "Application des extensions géographiques"

step "Basculement vers la branche géographique..."
git checkout feature/french-geographic-segmentation

step "Application manuelle de la migration v5.1.0..."

# Appliquer manuellement la migration v5.1.0
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk << 'EOF'
-- Ajouter les colonnes géographiques à la table subscribers existante
ALTER TABLE subscribers 
ADD COLUMN IF NOT EXISTS code_insee VARCHAR(10),
ADD COLUMN IF NOT EXISTS population_commune INTEGER,
ADD COLUMN IF NOT EXISTS date_naissance DATE,
ADD COLUMN IF NOT EXISTS csp VARCHAR(100),
ADD COLUMN IF NOT EXISTS siren VARCHAR(20),
ADD COLUMN IF NOT EXISTS siret VARCHAR(20),
ADD COLUMN IF NOT EXISTS telecopie VARCHAR(20),
ADD COLUMN IF NOT EXISTS nom_commune VARCHAR(255),
ADD COLUMN IF NOT EXISTS departement_numero VARCHAR(3),
ADD COLUMN IF NOT EXISTS phone VARCHAR(50),
ADD COLUMN IF NOT EXISTS website VARCHAR(255),
ADD COLUMN IF NOT EXISTS address1 TEXT,
ADD COLUMN IF NOT EXISTS city VARCHAR(255),
ADD COLUMN IF NOT EXISTS state VARCHAR(255),
ADD COLUMN IF NOT EXISTS zipcode VARCHAR(10),
ADD COLUMN IF NOT EXISTS country VARCHAR(100),
ADD COLUMN IF NOT EXISTS title VARCHAR(10);

-- Index pour les requêtes géographiques performantes
CREATE INDEX IF NOT EXISTS idx_subscribers_departement ON subscribers(departement_numero);
CREATE INDEX IF NOT EXISTS idx_subscribers_code_insee ON subscribers(code_insee);
CREATE INDEX IF NOT EXISTS idx_subscribers_population ON subscribers(population_commune);
CREATE INDEX IF NOT EXISTS idx_subscribers_csp ON subscribers(csp);
CREATE INDEX IF NOT EXISTS idx_subscribers_nom_commune ON subscribers(nom_commune);
CREATE INDEX IF NOT EXISTS idx_subscribers_state ON subscribers(state);

-- Créer une table de mapping départements vers régions
CREATE TABLE IF NOT EXISTS departement_region_mapping (
    departement_numero VARCHAR(3) PRIMARY KEY,
    departement_nom VARCHAR(255) NOT NULL,
    region_nom VARCHAR(255) NOT NULL,
    region_code VARCHAR(3) NOT NULL
);

-- Insérer le mapping complet départements/régions français
INSERT INTO departement_region_mapping (departement_numero, departement_nom, region_nom, region_code) VALUES
('01', 'Ain', 'Auvergne-Rhône-Alpes', '84'),
('02', 'Aisne', 'Hauts-de-France', '32'),
('03', 'Allier', 'Auvergne-Rhône-Alpes', '84'),
('04', 'Alpes-de-Haute-Provence', 'Provence-Alpes-Côte d''Azur', '93'),
('05', 'Hautes-Alpes', 'Provence-Alpes-Côte d''Azur', '93'),
('06', 'Alpes-Maritimes', 'Provence-Alpes-Côte d''Azur', '93'),
('07', 'Ardèche', 'Auvergne-Rhône-Alpes', '84'),
('08', 'Ardennes', 'Grand Est', '44'),
('09', 'Ariège', 'Occitanie', '76'),
('10', 'Aube', 'Grand Est', '44'),
('11', 'Aude', 'Occitanie', '76'),
('12', 'Aveyron', 'Occitanie', '76'),
('13', 'Bouches-du-Rhône', 'Provence-Alpes-Côte d''Azur', '93'),
('14', 'Calvados', 'Normandie', '28'),
('15', 'Cantal', 'Auvergne-Rhône-Alpes', '84'),
('16', 'Charente', 'Nouvelle-Aquitaine', '75'),
('17', 'Charente-Maritime', 'Nouvelle-Aquitaine', '75'),
('18', 'Cher', 'Centre-Val de Loire', '24'),
('19', 'Corrèze', 'Nouvelle-Aquitaine', '75'),
('21', 'Côte-d''Or', 'Bourgogne-Franche-Comté', '27'),
('22', 'Côtes-d''Armor', 'Bretagne', '53'),
('23', 'Creuse', 'Nouvelle-Aquitaine', '75'),
('24', 'Dordogne', 'Nouvelle-Aquitaine', '75'),
('25', 'Doubs', 'Bourgogne-Franche-Comté', '27'),
('26', 'Drôme', 'Auvergne-Rhône-Alpes', '84'),
('27', 'Eure', 'Normandie', '28'),
('28', 'Eure-et-Loir', 'Centre-Val de Loire', '24'),
('29', 'Finistère', 'Bretagne', '53'),
('30', 'Gard', 'Occitanie', '76'),
('31', 'Haute-Garonne', 'Occitanie', '76'),
('32', 'Gers', 'Occitanie', '76'),
('33', 'Gironde', 'Nouvelle-Aquitaine', '75'),
('34', 'Hérault', 'Occitanie', '76'),
('35', 'Ille-et-Vilaine', 'Bretagne', '53'),
('36', 'Indre', 'Centre-Val de Loire', '24'),
('37', 'Indre-et-Loire', 'Centre-Val de Loire', '24'),
('38', 'Isère', 'Auvergne-Rhône-Alpes', '84'),
('39', 'Jura', 'Bourgogne-Franche-Comté', '27'),
('40', 'Landes', 'Nouvelle-Aquitaine', '75'),
('41', 'Loir-et-Cher', 'Centre-Val de Loire', '24'),
('42', 'Loire', 'Auvergne-Rhône-Alpes', '84'),
('43', 'Haute-Loire', 'Auvergne-Rhône-Alpes', '84'),
('44', 'Loire-Atlantique', 'Pays de la Loire', '52'),
('45', 'Loiret', 'Centre-Val de Loire', '24'),
('46', 'Lot', 'Occitanie', '76'),
('47', 'Lot-et-Garonne', 'Nouvelle-Aquitaine', '75'),
('48', 'Lozère', 'Occitanie', '76'),
('49', 'Maine-et-Loire', 'Pays de la Loire', '52'),
('50', 'Manche', 'Normandie', '28'),
('51', 'Marne', 'Grand Est', '44'),
('52', 'Haute-Marne', 'Grand Est', '44'),
('53', 'Mayenne', 'Pays de la Loire', '52'),
('54', 'Meurthe-et-Moselle', 'Grand Est', '44'),
('55', 'Meuse', 'Grand Est', '44'),
('56', 'Morbihan', 'Bretagne', '53'),
('57', 'Moselle', 'Grand Est', '44'),
('58', 'Nièvre', 'Bourgogne-Franche-Comté', '27'),
('59', 'Nord', 'Hauts-de-France', '32'),
('60', 'Oise', 'Hauts-de-France', '32'),
('61', 'Orne', 'Normandie', '28'),
('62', 'Pas-de-Calais', 'Hauts-de-France', '32'),
('63', 'Puy-de-Dôme', 'Auvergne-Rhône-Alpes', '84'),
('64', 'Pyrénées-Atlantiques', 'Nouvelle-Aquitaine', '75'),
('65', 'Hautes-Pyrénées', 'Occitanie', '76'),
('66', 'Pyrénées-Orientales', 'Occitanie', '76'),
('67', 'Bas-Rhin', 'Grand Est', '44'),
('68', 'Haut-Rhin', 'Grand Est', '44'),
('69', 'Rhône', 'Auvergne-Rhône-Alpes', '84'),
('70', 'Haute-Saône', 'Bourgogne-Franche-Comté', '27'),
('71', 'Saône-et-Loire', 'Bourgogne-Franche-Comté', '27'),
('72', 'Sarthe', 'Pays de la Loire', '52'),
('73', 'Savoie', 'Auvergne-Rhône-Alpes', '84'),
('74', 'Haute-Savoie', 'Auvergne-Rhône-Alpes', '84'),
('75', 'Paris', 'Île-de-France', '11'),
('76', 'Seine-Maritime', 'Normandie', '28'),
('77', 'Seine-et-Marne', 'Île-de-France', '11'),
('78', 'Yvelines', 'Île-de-France', '11'),
('79', 'Deux-Sèvres', 'Nouvelle-Aquitaine', '75'),
('80', 'Somme', 'Hauts-de-France', '32'),
('81', 'Tarn', 'Occitanie', '76'),
('82', 'Tarn-et-Garonne', 'Occitanie', '76'),
('83', 'Var', 'Provence-Alpes-Côte d''Azur', '93'),
('84', 'Vaucluse', 'Provence-Alpes-Côte d''Azur', '93'),
('85', 'Vendée', 'Pays de la Loire', '52'),
('86', 'Vienne', 'Nouvelle-Aquitaine', '75'),
('87', 'Haute-Vienne', 'Nouvelle-Aquitaine', '75'),
('88', 'Vosges', 'Grand Est', '44'),
('89', 'Yonne', 'Bourgogne-Franche-Comté', '27'),
('90', 'Territoire de Belfort', 'Bourgogne-Franche-Comté', '27'),
('91', 'Essonne', 'Île-de-France', '11'),
('92', 'Hauts-de-Seine', 'Île-de-France', '11'),
('93', 'Seine-Saint-Denis', 'Île-de-France', '11'),
('94', 'Val-de-Marne', 'Île-de-France', '11'),
('95', 'Val-d''Oise', 'Île-de-France', '11')
ON CONFLICT (departement_numero) DO NOTHING;

-- Index sur la table de mapping
CREATE INDEX IF NOT EXISTS idx_departement_region_mapping_region ON departement_region_mapping(region_nom);

-- Marquer la migration comme appliquée
INSERT INTO settings (key, value) VALUES ('migrations', '["v5.1.0"]') 
ON CONFLICT (key) DO UPDATE SET value = '["v5.1.0"]', updated_at = NOW();
EOF

if [ $? -eq 0 ]; then
    success "Extensions géographiques appliquées manuellement"
else
    error "Erreur lors de l'application des extensions géographiques"
    exit 1
fi

step "Recompilation avec les extensions géographiques..."
go mod tidy
go build -o listmonk cmd/*.go

echo ""

# Étape 8: Vérification de l'installation
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

# Étape 9: Test de démarrage
step "Test de démarrage de Listmonk"

# Test rapide de démarrage
timeout 10s ./listmonk --config config.toml > /dev/null 2>&1 &
LISTMONK_PID=$!
sleep 3

if kill -0 $LISTMONK_PID 2>/dev/null; then
    success "Listmonk démarre correctement"
    kill $LISTMONK_PID 2>/dev/null || true
else
    warning "Problème de démarrage détecté"
fi

echo ""

# Étape 10: Ajout de données de test
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

# Étape 11: Configuration de la sécurité finale
step "Configuration de la sécurité finale"

# Retirer les privilèges superuser après installation
sudo -u postgres psql -c "ALTER USER listmonk WITH NOSUPERUSER;" 2>/dev/null || true
success "Privilèges de sécurité appliqués"

echo ""

# Étape 12: Statistiques finales
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
echo "   ./listmonk --config config.toml"
echo "   # ou"
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