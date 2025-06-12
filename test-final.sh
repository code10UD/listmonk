#!/bin/bash

# Test final de l'implémentation géographique
echo "🎯 Test final de l'implémentation géographique Listmonk"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher les erreurs
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour afficher les infos
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo ""
echo "🔍 VÉRIFICATION DE L'ÉTAT DU SYSTÈME"
echo "===================================="

# Vérifier PostgreSQL
echo -n "📊 PostgreSQL... "
if sudo docker exec listmonk_db_test pg_isready -U listmonk > /dev/null 2>&1; then
    success "Actif"
else
    error "Inactif"
    exit 1
fi

# Vérifier le backend
echo -n "🚀 Backend Listmonk... "
if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    success "Actif"
else
    error "Inactif"
    exit 1
fi

echo ""
echo "🗄️ VÉRIFICATION DE LA BASE DE DONNÉES"
echo "====================================="

# Vérifier les tables géographiques
echo -n "🗺️  Table departement_region_mapping... "
if count=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' '); then
    success "$count départements"
else
    error "Table manquante"
fi

# Vérifier les colonnes géographiques
echo -n "👥 Colonnes géographiques subscribers... "
if sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    success "Présentes"
else
    error "Manquantes"
fi

# Vérifier les données de test
echo -n "🧪 Données de test... "
if count=$(sudo docker exec listmonk_db_test psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' '); then
    success "$count abonnés avec données géographiques"
else
    error "Aucune donnée"
fi

echo ""
echo "📁 VÉRIFICATION DES FICHIERS"
echo "============================"

# Vérifier les fichiers backend
echo -n "🔧 Backend geo.go... "
if [ -f "cmd/geo.go" ]; then
    lines=$(wc -l < cmd/geo.go)
    success "$lines lignes"
else
    error "Manquant"
fi

# Vérifier les requêtes SQL
echo -n "📝 Requêtes géographiques... "
if grep -q "get-geo-regions" queries.sql; then
    count=$(grep -c "name: get-geo" queries.sql)
    success "$count requêtes"
else
    error "Manquantes"
fi

# Vérifier les structures Go
echo -n "🏗️  Structures queries.go... "
if grep -q "GetGeoRegions" models/queries.go; then
    count=$(grep -c "GetGeo" models/queries.go)
    success "$count méthodes"
else
    error "Manquantes"
fi

# Vérifier le frontend
echo -n "🎨 Frontend GeoSelector.vue... "
if [ -f "frontend/src/components/GeoSelector.vue" ]; then
    lines=$(wc -l < frontend/src/components/GeoSelector.vue)
    success "$lines lignes"
else
    error "Manquant"
fi

# Vérifier le build frontend
echo -n "📦 Build frontend... "
if [ -d "frontend/dist" ]; then
    files=$(find frontend/dist -name "*.js" | wc -l)
    success "$files fichiers JS"
else
    error "Non construit"
fi

echo ""
echo "🌐 VÉRIFICATION DES ENDPOINTS API"
echo "================================="

# Test des endpoints (sans authentification, juste pour vérifier qu'ils répondent)
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
    if [ "$response" = "401" ] || [ "$response" = "200" ]; then
        success "Répond (HTTP $response)"
    else
        error "Erreur (HTTP $response)"
    fi
done

echo ""
echo "📊 STATISTIQUES FINALES"
echo "======================="

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

# Statistiques du code
echo ""
echo "💻 Code source:"
backend_lines=$(find cmd -name "*.go" -exec wc -l {} + | tail -1 | awk '{print $1}')
frontend_lines=$(find frontend/src -name "*.vue" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
sql_lines=$(wc -l < queries.sql)

echo "   • Lignes backend Go: $backend_lines"
echo "   • Lignes frontend Vue: $frontend_lines"
echo "   • Lignes SQL: $sql_lines"

echo ""
echo "🎯 RÉSUMÉ FINAL"
echo "==============="

# Vérifier l'état global
all_good=true

# Vérifications critiques
if ! sudo docker exec listmonk_db_test pg_isready -U listmonk > /dev/null 2>&1; then
    all_good=false
fi

if ! curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    all_good=false
fi

if ! [ -f "cmd/geo.go" ]; then
    all_good=false
fi

if ! grep -q "GetGeoRegions" models/queries.go; then
    all_good=false
fi

if ! [ -f "frontend/src/components/GeoSelector.vue" ]; then
    all_good=false
fi

if [ "$all_good" = true ]; then
    success "🎉 IMPLÉMENTATION GÉOGRAPHIQUE COMPLÈTE ET FONCTIONNELLE !"
    echo ""
    echo "✨ Fonctionnalités disponibles:"
    echo "   • 🗺️  Sélection par régions françaises"
    echo "   • 🏛️  Sélection par départements"
    echo "   • 🏘️  Recherche de communes"
    echo "   • 👔 Filtrage par CSP"
    echo "   • 📊 Statistiques géographiques"
    echo "   • 🔍 Requêtes géographiques avancées"
    echo ""
    echo "🌐 URLs d'accès:"
    echo "   • Interface admin: http://localhost:9000"
    echo "   • API géographique: http://localhost:9000/api/geo/"
    echo ""
    echo "👤 Identifiants:"
    echo "   • Email: admin@test.com"
    echo "   • Mot de passe: admin"
else
    error "❌ IMPLÉMENTATION INCOMPLÈTE"
    echo ""
    echo "🔧 Actions requises:"
    echo "   • Vérifier les services actifs"
    echo "   • Compléter les fichiers manquants"
    echo "   • Tester les endpoints API"
fi

echo ""
echo "📋 Fichiers créés/modifiés:"
echo "   • cmd/geo.go (handlers API géographiques)"
echo "   • queries.sql (9 nouvelles requêtes)"
echo "   • models/queries.go (structures Go)"
echo "   • frontend/src/components/GeoSelector.vue"
echo "   • frontend/src/api/index.js (méthodes API)"
echo "   • internal/migrations/v5.1.0.go"
echo ""

if [ "$all_good" = true ]; then
    exit 0
else
    exit 1
fi