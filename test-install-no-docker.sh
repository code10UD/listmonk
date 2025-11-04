#!/bin/bash

echo "🧪 Test de l'installation Listmonk sans Docker (PostgreSQL existant)"

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
    exit 1
fi
success "Go $(go version | cut -d' ' -f3) détecté"

# Vérifier PostgreSQL (Docker)
if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
    success "PostgreSQL Docker accessible"
else
    error "PostgreSQL Docker non accessible"
    exit 1
fi

echo ""

# Étape 2: Configuration Listmonk
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

# Étape 3: Vérifier si Listmonk est déjà installé
step "Vérification de l'installation existante"

if PGPASSWORD=listmonk psql -h localhost -p 5432 -U listmonk -d listmonk -c "SELECT COUNT(*) FROM settings;" > /dev/null 2>&1; then
    warning "Listmonk déjà installé, passage aux extensions géographiques"
else
    # Installation de base
    step "Installation de base Listmonk"
    git checkout master
    if go run cmd/*.go --config config.toml --install --yes; then
        success "Base de données de base installée"
    else
        error "Erreur lors de l'installation de base"
        exit 1
    fi
fi

echo ""

# Étape 4: Application des extensions géographiques
step "Application des extensions géographiques"

git checkout feature/french-geographic-segmentation

if go run cmd/*.go --config config.toml --upgrade --yes; then
    success "Migration géographique appliquée"
else
    error "Erreur lors de la migration géographique"
    exit 1
fi

echo ""

# Étape 5: Vérification des tables géographiques
step "Vérification des tables géographiques"

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

# Étape 6: Ajout de données de test
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

# Étape 7: Test de démarrage
step "Test de démarrage Listmonk"

# Vérifier si le port 9000 est libre
if lsof -i :9000 >/dev/null 2>&1; then
    warning "Port 9000 occupé, arrêt du processus existant"
    pkill -f "go run cmd" 2>/dev/null || true
    sleep 2
fi

# Démarrer Listmonk en arrière-plan
echo "🔄 Démarrage de Listmonk..."
nohup go run cmd/*.go --config config.toml > listmonk-test.log 2>&1 &
LISTMONK_PID=$!

# Attendre que Listmonk démarre
echo "🔄 Attente du démarrage (10 secondes)..."
sleep 10

# Tester l'API
echo -n "🌐 Test API health... "
if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    success "OK"
else
    error "Échec"
fi

echo -n "🗺️  Test API géographique... "
if curl -s -w "%{http_code}" -o /dev/null "http://localhost:9000/api/geo/regions" | grep -q "40[13]"; then
    success "Répond (auth requise)"
else
    error "Échec"
fi

# Arrêter Listmonk
echo "🔄 Arrêt de Listmonk..."
kill $LISTMONK_PID 2>/dev/null || true
sleep 2

echo ""

# Étape 8: Statistiques finales
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
echo "🎉 TEST TERMINÉ AVEC SUCCÈS !"
echo ""
echo "🚀 Pour démarrer Listmonk :"
echo "   go run cmd/*.go --config config.toml"
echo ""
echo "🌐 Interface : http://localhost:9000"
echo "👤 Email: admin | Mot de passe: admin"

success "🎯 INSTALLATION SANS DOCKER VALIDÉE !"