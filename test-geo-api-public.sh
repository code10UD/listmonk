#!/bin/bash

echo "🧪 Test des API géographiques Listmonk (groupe public)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "${BLUE}🔄 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
LISTMONK_URL="http://localhost:9000"

# Fonction pour tester une API publique
test_api_public() {
    local endpoint="$1"
    local description="$2"
    
    step "Test $description"
    
    response=$(curl -s -w "%{http_code}" "$LISTMONK_URL$endpoint")
    
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

# Tests des API géographiques sans authentification
test_api_public "/api/geo/regions" "API Régions (public)"
test_api_public "/api/geo/departements" "API Départements (public)"
test_api_public "/api/geo/communes?search=Paris" "API Communes (public)"
test_api_public "/api/geo/csps" "API CSPs (public)"
test_api_public "/api/geo/stats" "API Statistiques géographiques (public)"

echo ""
step "Test des API publiques existantes pour comparaison..."
test_api_public "/api/public/lists" "API Listes publiques (référence)"

echo ""
success "Tests terminés"