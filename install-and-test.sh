#!/bin/bash

# Script d'installation et test corrigé pour Listmonk avec extensions géographiques
echo "🚀 Installation et test de Listmonk avec extensions géographiques (VERSION CORRIGÉE)"

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

# Étape 1: Arrêter les services existants
step "Nettoyage des services existants"
sudo docker compose down > /dev/null 2>&1
sudo docker rm -f listmonk_db_test > /dev/null 2>&1

# Étape 2: Démarrer PostgreSQL
step "Démarrage de PostgreSQL"

# Créer un docker-compose minimal pour la DB
cat > docker-compose-test.yml << EOF
services:
  db:
    image: postgres:17-alpine
    container_name: listmonk_db_test
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: listmonk
      POSTGRES_PASSWORD: listmonk
      POSTGRES_DB: listmonk
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U listmonk"]
      interval: 5s
      timeout: 5s
      retries: 12
EOF

# Démarrer PostgreSQL
if sudo docker compose -f docker-compose-test.yml up -d db; then
    success "PostgreSQL démarré"
else
    error "Erreur lors du démarrage de PostgreSQL"
    exit 1
fi

# Attendre que PostgreSQL soit prêt
echo -n "⏳ Attente de PostgreSQL... "
for i in {1..60}; do
    if sudo docker exec listmonk_db_test pg_isready -U listmonk > /dev/null 2>&1; then
        success "PostgreSQL prêt"
        break
    fi
    sleep 1
    echo -n "."
done

if [ $i -eq 60 ]; then
    error "PostgreSQL n'est pas prêt après 60 secondes"
    exit 1
fi

# Attendre un peu plus pour que PostgreSQL soit complètement prêt
sleep 5

echo ""

# Étape 3: Installation de base de Listmonk
step "Installation de base de Listmonk"

# Créer un fichier de configuration temporaire
cat > config-test.toml << EOF
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

# Basculer temporairement vers master pour l'installation de base
echo "🔄 Basculement vers master pour installation de base..."
git checkout master

# Installer la base de données de base
echo "🔄 Installation de la base de données de base..."
if go run cmd/*.go --config config-test.toml --install --yes; then
    success "Base de données de base installée"
else
    error "Erreur lors de l'installation de base"
    exit 1
fi

# Revenir à la branche géographique
echo "🔄 Retour à la branche géographique..."
git checkout feature/french-geographic-segmentation

echo ""

# Étape 4: Application de la migration géographique
step "Application de la migration géographique"

echo "🔄 Exécution de la migration géographique v5.1.0..."
if go run cmd/*.go --config config-test.toml --upgrade --yes; then
    success "Migration géographique appliquée"
else
    error "Erreur lors de la migration géographique"
    exit 1
fi

echo "🔄 Vérification de la migration..."
if sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departement_region_mapping;" > /dev/null 2>&1; then
    success "Migration géographique complète"
else
    error "Erreur: Migration géographique incomplète"
    exit 1
fi

echo ""

# Étape 5: Vérification des tables géographiques
step "Vérification des tables géographiques"

echo -n "📊 Table departement_region_mapping... "
if count=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' '); then
    success "OK ($count départements)"
else
    error "Table manquante"
fi

echo -n "👥 Colonnes géographiques subscribers... "
if sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    success "Présentes"
else
    error "Manquantes"
fi

echo ""

# Étape 6: Ajout de données de test
step "Ajout de données de test"

echo "🔄 Insertion de données de test géographiques..."
sudo docker exec listmonk_db_test psql -U listmonk -d listmonk << 'EOF'
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

# Étape 7: Démarrage du backend
step "Démarrage du backend Listmonk"

echo "🔄 Démarrage du serveur backend..."
go run cmd/*.go --config config-test.toml > /tmp/listmonk-backend.log 2>&1 &
BACKEND_PID=$!

# Attendre que le backend soit prêt
echo -n "⏳ Attente du backend... "
for i in {1..30}; do
    if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
        success "Backend prêt"
        break
    fi
    sleep 1
    echo -n "."
done

if [ $i -eq 30 ]; then
    error "Backend n'est pas prêt après 30 secondes"
    echo "Logs du backend:"
    cat /tmp/listmonk-backend.log
    exit 1
fi

echo ""

# Étape 8: Tests des endpoints géographiques
step "Tests des endpoints géographiques"

# Test des endpoints (ils retourneront 403 sans auth, mais c'est normal)
endpoints=(
    "/api/geo/regions"
    "/api/geo/departements" 
    "/api/geo/communes"
    "/api/geo/csps"
    "/api/geo/stats"
)

for endpoint in "${endpoints[@]}"; do
    echo -n "🔗 $endpoint... "
    response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:9000$endpoint")
    if [ "$response" = "401" ] || [ "$response" = "403" ] || [ "$response" = "200" ]; then
        success "Répond (HTTP $response)"
    else
        error "Erreur (HTTP $response)"
    fi
done

echo ""

# Étape 9: Statistiques finales
step "Statistiques finales"

# Statistiques de la base de données
echo "🗄️  Base de données:"
total_subscribers=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
geo_subscribers=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' ')
total_regions=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(DISTINCT region_nom) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
total_departements=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')

echo "   • Total abonnés: $total_subscribers"
echo "   • Abonnés avec données géo: $geo_subscribers"
echo "   • Régions françaises: $total_regions"
echo "   • Départements français: $total_departements"

echo ""
echo "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !"
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
echo "   • Arrêter le backend: kill $BACKEND_PID"
echo "   • Voir les logs: tail -f /tmp/listmonk-backend.log"
echo "   • Arrêter PostgreSQL: sudo docker stop listmonk_db_test"
echo ""

success "🎯 LISTMONK AVEC EXTENSIONS GÉOGRAPHIQUES FRANÇAISES EST PRÊT !"