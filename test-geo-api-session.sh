#!/bin/bash

echo "🧪 Test des API géographiques Listmonk (avec sessions)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "${BLUE}🔄 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Configuration
LISTMONK_URL="http://localhost:9000"
ADMIN_USER="vince"
ADMIN_PASS="%Qwsxdcfv123456"
COOKIE_JAR="/tmp/listmonk_cookies.txt"

# Nettoyer les cookies précédents
rm -f "$COOKIE_JAR"

# Fonction pour s'authentifier via session
authenticate() {
    step "Authentification via session..."
    
    # 1. Récupérer la page de login pour obtenir le CSRF token
    login_page=$(curl -s -c "$COOKIE_JAR" "$LISTMONK_URL/admin/login")
    
    if [ $? -ne 0 ]; then
        error "Impossible d'accéder à la page de login"
        return 1
    fi
    
    # 2. Se connecter avec les identifiants
    login_response=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        -X POST "$LISTMONK_URL/admin/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$ADMIN_USER&password=$ADMIN_PASS&next=/admin" \
        -w "%{http_code}")
    
    http_code="${login_response: -3}"
    
    if [ "$http_code" = "302" ] || [ "$http_code" = "200" ]; then
        success "Authentification réussie"
        return 0
    else
        error "Échec de l'authentification (HTTP $http_code)"
        echo "Réponse: ${login_response%???}"
        return 1
    fi
}

# Fonction pour tester une API avec session
test_api_session() {
    local endpoint="$1"
    local description="$2"
    
    step "Test $description"
    
    response=$(curl -s -b "$COOKIE_JAR" -w "%{http_code}" "$LISTMONK_URL$endpoint")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        success "$description - HTTP $http_code"
        echo "Réponse: $(echo "$body" | jq . 2>/dev/null || echo "$body" | head -c 200)"
        echo ""
        return 0
    else
        error "$description - HTTP $http_code"
        echo "Erreur: $(echo "$body" | head -c 200)"
        echo ""
        return 1
    fi
}

# Vérifier que Listmonk est démarré
step "Vérification que Listmonk est accessible..."
if curl -s "$LISTMONK_URL/api/health" > /dev/null; then
    success "Listmonk accessible"
else
    error "Listmonk non accessible sur $LISTMONK_URL"
    echo "Assurez-vous que Listmonk est démarré avec: ./listmonk --config config.toml"
    exit 1
fi

echo ""

# Authentification
if ! authenticate; then
    error "Impossible de s'authentifier"
    echo ""
    echo "Vérifiez vos identifiants dans le script ou créez un utilisateur admin:"
    echo "PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c \"SELECT email, name FROM users;\""
    exit 1
fi

echo ""

# Tests des API géographiques avec session
test_api_session "/api/geo/regions" "API Régions"
test_api_session "/api/geo/departements" "API Départements"
test_api_session "/api/geo/communes?search=Paris" "API Communes (recherche Paris)"
test_api_session "/api/geo/csps" "API CSPs"
test_api_session "/api/geo/stats" "API Statistiques géographiques"

echo ""
step "Vérification directe de la base de données..."

# Test direct de la base de données
echo "Régions dans la base :"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT DISTINCT region_nom FROM departement_region_mapping ORDER BY region_nom LIMIT 5;" 2>/dev/null

echo ""
echo "Départements dans la base :"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT departement_numero, departement_nom, region_nom FROM departement_region_mapping ORDER BY departement_numero LIMIT 5;" 2>/dev/null

echo ""
echo "Utilisateurs dans la base :"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT id, email, name, type FROM users;" 2>/dev/null

# Nettoyer
rm -f "$COOKIE_JAR"

echo ""
success "Tests terminés"