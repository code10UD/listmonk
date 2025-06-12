#!/bin/bash

# Script de test pour l'implémentation géographique backend
echo "🧪 Test de l'implémentation géographique backend"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:9000"
FRONTEND_URL="http://localhost:12000"

echo "📋 Configuration:"
echo "   Backend URL: $BACKEND_URL"
echo "   Frontend URL: $FRONTEND_URL"
echo ""

# Fonction pour tester un endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -n "🔍 Test: $description... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$BACKEND_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json -X "$method" -H "Content-Type: application/json" -d "$data" "$BACKEND_URL$endpoint")
    fi
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        # Afficher un aperçu de la réponse
        if [ -f /tmp/response.json ]; then
            data_count=$(jq -r '.data | length' /tmp/response.json 2>/dev/null || echo "N/A")
            echo "   📊 Données retournées: $data_count éléments"
        fi
    else
        echo -e "${RED}❌ ÉCHEC (HTTP $http_code)${NC}"
        if [ -f /tmp/response.json ]; then
            echo "   📄 Réponse: $(cat /tmp/response.json)"
        fi
    fi
    echo ""
}

# Vérifier que le backend est accessible
echo "🔌 Vérification de la connectivité backend..."
if ! curl -s "$BACKEND_URL/api/health" > /dev/null; then
    echo -e "${RED}❌ Backend non accessible sur $BACKEND_URL${NC}"
    echo "💡 Assurez-vous que le backend Listmonk est démarré"
    exit 1
fi
echo -e "${GREEN}✅ Backend accessible${NC}"
echo ""

# Tests des endpoints géographiques
echo "🗺️ Tests des endpoints géographiques:"
echo "=================================="

# Test 1: Récupération des régions
test_endpoint "GET" "/api/geo/regions" "" "Récupération des régions françaises"

# Test 2: Récupération des départements
test_endpoint "GET" "/api/geo/departements" "" "Récupération des départements"

# Test 3: Recherche de communes
test_endpoint "GET" "/api/geo/communes?search=paris" "" "Recherche de communes (paris)"

# Test 4: Recherche de communes par département
test_endpoint "GET" "/api/geo/communes?departement=75" "" "Communes du département 75"

# Test 5: Récupération des CSP
test_endpoint "GET" "/api/geo/csps" "" "Récupération des CSP"

# Test 6: Statistiques géographiques
test_endpoint "GET" "/api/geo/stats" "" "Statistiques géographiques"

# Test 7: Requête géographique complexe
geo_query='{"regions":["Île-de-France"],"use_population":false}'
test_endpoint "POST" "/api/lists/query/geo" "$geo_query" "Requête géographique (Île-de-France)"

# Test 8: Requête avec filtres multiples
complex_query='{"regions":["Île-de-France"],"departements":["75","92"],"use_population":true,"population_min":10000}'
test_endpoint "POST" "/api/lists/query/geo" "$complex_query" "Requête complexe (région + depts + population)"

echo ""
echo "🔍 Vérification de la base de données:"
echo "====================================="

# Vérifier que les tables géographiques existent
echo -n "📊 Table departement_region_mapping... "
if docker exec listmonk_db psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departement_region_mapping;" > /dev/null 2>&1; then
    count=$(docker exec listmonk_db psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
    echo -e "${GREEN}✅ OK ($count départements)${NC}"
else
    echo -e "${RED}❌ Table manquante${NC}"
fi

# Vérifier les colonnes géographiques dans subscribers
echo -n "👥 Colonnes géographiques subscribers... "
if docker exec listmonk_db psql -U listmonk -d listmonk -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Colonnes manquantes${NC}"
fi

echo ""
echo "🎯 Test de l'interface frontend:"
echo "==============================="

# Vérifier que le frontend est accessible
echo -n "🌐 Frontend accessible... "
if curl -s "$FRONTEND_URL" > /dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Frontend non accessible${NC}"
fi

# Vérifier que les fichiers géographiques existent
echo -n "📁 Composant GeoSelector... "
if [ -f "/workspace/listmonk/frontend/src/components/GeoSelector.vue" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Fichier manquant${NC}"
fi

echo -n "🔧 Méthodes API frontend... "
if grep -q "getGeoRegions" "/workspace/listmonk/frontend/src/api/index.js"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Méthodes manquantes${NC}"
fi

echo ""
echo "📊 RÉSUMÉ DES TESTS:"
echo "==================="

# Compter les succès et échecs
success_count=0
total_tests=8

# Retester rapidement pour le résumé
for endpoint in "/api/geo/regions" "/api/geo/departements" "/api/geo/communes" "/api/geo/csps" "/api/geo/stats"; do
    if curl -s -f "$BACKEND_URL$endpoint" > /dev/null 2>&1; then
        ((success_count++))
    fi
done

# Test POST
if curl -s -f -X POST -H "Content-Type: application/json" -d '{"regions":["Île-de-France"]}' "$BACKEND_URL/api/lists/query/geo" > /dev/null 2>&1; then
    ((success_count++))
fi

echo "✅ Tests réussis: $success_count/$total_tests"

if [ $success_count -eq $total_tests ]; then
    echo -e "${GREEN}🎉 TOUS LES TESTS SONT PASSÉS !${NC}"
    echo "🚀 L'implémentation géographique est fonctionnelle"
else
    echo -e "${YELLOW}⚠️  Certains tests ont échoué${NC}"
    echo "🔧 Vérifiez les logs du backend pour plus de détails"
fi

echo ""
echo "💡 Commandes utiles pour le debugging:"
echo "   - Logs backend: docker logs listmonk_app"
echo "   - Logs DB: docker logs listmonk_db"
echo "   - Test manuel: curl $BACKEND_URL/api/geo/regions"
echo "   - Interface: $FRONTEND_URL/admin"

# Nettoyage
rm -f /tmp/response.json