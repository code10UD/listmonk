#!/bin/bash

echo "🧪 Test des API géographiques Listmonk"

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
ADMIN_USER="admin"
ADMIN_PASS="admin"

# Fonction pour tester une API
test_api() {
    local endpoint="$1"
    local description="$2"
    
    step "Test $description"
    
    # Obtenir un token d'authentification
    TOKEN=$(curl -s -X POST "$LISTMONK_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" | \
        grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$TOKEN" ]; then
        error "Impossible d'obtenir le token d'authentification"
        return 1
    fi
    
    # Tester l'endpoint
    response=$(curl -s -w "%{http_code}" -X GET "$LISTMONK_URL$endpoint" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        success "$description - HTTP $http_code"
        echo "Réponse: $(echo "$body" | jq . 2>/dev/null || echo "$body")"
        echo ""
        return 0
    else
        error "$description - HTTP $http_code"
        echo "Erreur: $body"
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

# Tests des API géographiques
test_api "/api/geo/regions" "API Régions"
test_api "/api/geo/departements" "API Départements"
test_api "/api/geo/communes?search=Paris" "API Communes (recherche Paris)"
test_api "/api/geo/csps" "API CSPs"
test_api "/api/geo/stats" "API Statistiques géographiques"

echo ""
step "Vérification directe de la base de données..."

# Test direct de la base de données
echo "Régions dans la base :"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT DISTINCT region_nom FROM departement_region_mapping ORDER BY region_nom LIMIT 5;" 2>/dev/null

echo ""
echo "Départements dans la base :"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT departement_numero, departement_nom, region_nom FROM departement_region_mapping ORDER BY departement_numero LIMIT 5;" 2>/dev/null

echo ""
success "Tests terminés"