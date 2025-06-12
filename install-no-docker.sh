#!/bin/bash

echo "🚀 Installation Listmonk sans Docker - Extensions Géographiques Françaises"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
export PATH=$PATH:/usr/local/go/bin
# Utiliser le répertoire courant (où le script est exécuté)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Fonction pour afficher les étapes
step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Fonction pour afficher les succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher les erreurs
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour afficher les avertissements
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""

# Étape 1: Vérifications préalables
step "Vérifications préalables"

# Vérifier Go
if ! command -v go &> /dev/null; then
    error "Go n'est pas installé. Installez Go 1.19+ d'abord."
    echo "Téléchargez depuis: https://golang.org/dl/"
    exit 1
fi
success "Go $(go version | cut -d' ' -f3) détecté"

# Vérifier PostgreSQL
if ! command -v psql &> /dev/null; then
    error "PostgreSQL n'est pas installé."
    echo ""
    echo "Pour installer PostgreSQL :"
    echo "  Ubuntu/Debian: sudo apt install postgresql postgresql-contrib"
    echo "  CentOS/RHEL:   sudo dnf install postgresql postgresql-server"
    echo "  Arch Linux:    sudo pacman -S postgresql"
    exit 1
fi
success "PostgreSQL détecté"

# Vérifier si PostgreSQL est démarré
if ! systemctl is-active --quiet postgresql 2>/dev/null; then
    warning "PostgreSQL n'est pas démarré"
    echo "Tentative de démarrage..."
    if sudo systemctl start postgresql 2>/dev/null; then
        success "PostgreSQL démarré"
    else
        error "Impossible de démarrer PostgreSQL. Démarrez-le manuellement :"
        echo "  sudo systemctl start postgresql"
        exit 1
    fi
else
    success "PostgreSQL actif"
fi

echo ""

# Étape 2: Configuration de la base de données
step "Configuration de la base de données"

# Vérifier si la base existe déjà en tant que postgres
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw listmonk; then
    warning "Base de données 'listmonk' existe déjà"
    echo -n "Voulez-vous la réinitialiser ? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🔄 Suppression de la base existante..."
        sudo -u postgres dropdb listmonk 2>/dev/null || true
        sudo -u postgres dropuser listmonk 2>/dev/null || true
    else
        echo "🔄 Utilisation de la base existante..."
        # Vérifier si on peut se connecter
        if PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
            success "Base de données accessible"
            echo ""
            # Passer à l'étape suivante
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
            # Aller directement aux extensions géographiques
            step "Application des extensions géographiques"
            git checkout feature/french-geographic-segmentation
            if go run cmd/*.go --config config.toml --upgrade --yes; then
                success "Extensions géographiques appliquées"
                echo ""
                echo "🎉 INSTALLATION TERMINÉE !"
                echo "🚀 Démarrez avec: ./start-listmonk.sh"
                exit 0
            else
                error "Erreur lors de l'application des extensions"
                exit 1
            fi
        fi
    fi
fi

# Créer la base et l'utilisateur
echo "🔄 Création de la base de données et de l'utilisateur..."
sudo -u postgres psql << 'EOF'
CREATE DATABASE listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk';
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;
\q
EOF

if [ $? -ne 0 ]; then
    error "Erreur lors de la création de la base de données"
    exit 1
fi

success "Base de données et utilisateur créés"

# Configurer l'authentification PostgreSQL
echo "🔄 Configuration de l'authentification PostgreSQL..."
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"

if [ ! -d "$PG_CONFIG_DIR" ]; then
    # Essayer d'autres emplacements
    PG_CONFIG_DIR=$(find /etc/postgresql -name "pg_hba.conf" -exec dirname {} \; 2>/dev/null | head -1)
fi

if [ -f "$PG_CONFIG_DIR/pg_hba.conf" ]; then
    # Sauvegarder le fichier original
    sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup"
    
    # Ajouter la ligne d'authentification pour listmonk si elle n'existe pas
    if ! sudo grep -q "local.*listmonk.*md5" "$PG_CONFIG_DIR/pg_hba.conf"; then
        echo "local   all             listmonk                                md5" | sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null
        sudo systemctl reload postgresql
        success "Configuration PostgreSQL mise à jour"
    else
        success "Configuration PostgreSQL déjà correcte"
    fi
else
    warning "Fichier pg_hba.conf non trouvé, configuration manuelle nécessaire"
fi

# Attendre un peu pour que PostgreSQL recharge la config
sleep 2

# Tester la connexion
echo "🔄 Test de la connexion..."
if PGPASSWORD=listmonk PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    success "Base de données configurée et accessible"
else
    error "Impossible de se connecter à la base de données"
    echo ""
    echo "Configuration manuelle nécessaire :"
    echo "1. Éditez $PG_CONFIG_DIR/pg_hba.conf"
    echo "2. Ajoutez: local   all   listmonk   md5"
    echo "3. Redémarrez: sudo systemctl restart postgresql"
    echo "4. Testez: PGPASSWORD=listmonk PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost"
    exit 1
fi

echo ""

# Étape 3: Configuration Listmonk
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

# Étape 4: Installation de base
step "Installation de base Listmonk"

# Basculer sur master pour l'installation de base
echo "🔄 Basculement vers master pour installation de base..."
git checkout master

# Installer la base de données de base
echo "🔄 Installation de la base de données de base..."
if go run cmd/*.go --config config.toml --install --yes; then
    success "Base de données de base installée"
else
    error "Erreur lors de l'installation de base"
    exit 1
fi

echo ""

# Étape 5: Application des extensions géographiques
step "Application des extensions géographiques"

# Revenir à la branche géographique
echo "🔄 Retour à la branche géographique..."
git checkout feature/french-geographic-segmentation

# Appliquer la migration géographique
echo "🔄 Exécution de la migration géographique v5.1.0..."
if go run cmd/*.go --config config.toml --upgrade --yes; then
    success "Migration géographique appliquée"
else
    error "Erreur lors de la migration géographique"
    exit 1
fi

echo "🔄 Vérification de la migration..."
if PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT COUNT(*) FROM departement_region_mapping;" > /dev/null 2>&1; then
    success "Migration géographique complète"
else
    error "Erreur: Migration géographique incomplète"
    exit 1
fi

echo ""

# Étape 6: Vérification des tables géographiques
step "Vérification des tables géographiques"

echo -n "📊 Table departement_region_mapping... "
if count=$(PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' '); then
    success "OK ($count départements)"
else
    error "Table manquante"
fi

echo -n "👥 Colonnes géographiques subscribers... "
if PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    success "Présentes"
else
    error "Manquantes"
fi

echo ""

# Étape 7: Ajout de données de test
step "Ajout de données de test"

echo "🔄 Insertion de données de test géographiques..."
PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost << 'EOF'
-- Ajouter quelques abonnés de test avec données géographiques
INSERT INTO subscribers (email, name, status, code_insee, nom_commune, departement_numero, population_commune, csp) VALUES
('test.paris@example.com', 'Test Paris', 'enabled', '75101', 'Paris', '75', 2161000, 'Cadre'),
('test.lyon@example.com', 'Test Lyon', 'enabled', '69123', 'Lyon', '69', 515695, 'Employé'),
('test.marseille@example.com', 'Test Marseille', 'enabled', '13055', 'Marseille', '13', 861635, 'Ouvrier'),
('test.toulouse@example.com', 'Test Toulouse', 'enabled', '31555', 'Toulouse', '31', 471941, 'Profession libérale'),
('test.nice@example.com', 'Test Nice', 'enabled', '06088', 'Nice', '06', 342637, 'Retraité')
ON CONFLICT (email) DO NOTHING;
EOF

if [ $? -eq 0 ]; then
    success "Données de test ajoutées"
else
    error "Erreur lors de l'ajout des données de test"
fi

echo ""

# Étape 8: Statistiques finales
step "Statistiques finales"

# Statistiques de la base de données
echo "🗄️  Base de données:"
total_subscribers=$(PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
geo_subscribers=$(PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' ')
total_regions=$(PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(DISTINCT region_nom) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
total_departements=$(PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')

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
echo "🚀 OU en arrière-plan :"
echo "   nohup go run cmd/*.go --config config.toml > listmonk.log 2>&1 &"
echo ""
echo "🚀 OU compiler et exécuter :"
echo "   go build -o listmonk cmd/*.go"
echo "   ./listmonk --config config.toml"
echo ""
echo "🌐 URLs d'accès:"
echo "   • Interface admin: http://localhost:9000"
echo "   • API géographique: http://localhost:9000/api/geo/"
echo ""
echo "👤 Identifiants:"
echo "   • Email: admin"
echo "   • Mot de passe: admin"
echo ""
echo "🔧 Commandes utiles:"
echo "   • Voir les logs: tail -f listmonk.log"
echo "   • Arrêter: pkill -f 'go run cmd'"
echo "   • Tester DB: PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost"
echo ""

success "🎯 LISTMONK AVEC EXTENSIONS GÉOGRAPHIQUES FRANÇAISES EST PRÊT (SANS DOCKER) !"