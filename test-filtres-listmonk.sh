#!/bin/bash

# Script de test pour valider les filtres géographiques dans Listmonk
set -e

echo "🧪 TEST DES FILTRES GÉOGRAPHIQUES LISTMONK"
echo "=========================================="

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}🔍 Test:${NC} $1"
}

print_result() {
    echo -e "${GREEN}✅ Résultat:${NC} $1"
}

print_separator() {
    echo -e "${YELLOW}---${NC}"
}

# Fonction pour exécuter une requête SQL
run_query() {
    local query="$1"
    local description="$2"
    
    print_test "$description"
    echo "SQL: $query"
    
    result=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "$query" 2>/dev/null | grep -E "^\s*[0-9]+" | wc -l)
    
    if [ $result -gt 0 ]; then
        print_result "$result ligne(s) trouvée(s)"
        docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "$query" 2>/dev/null | head -10
    else
        print_result "Aucun résultat"
    fi
    
    print_separator
}

echo ""
echo "🗺️ TESTS DES FILTRES GÉOGRAPHIQUES SIMPLES"
echo ""

# Test 1: Filtrage par région
run_query "SELECT email, name, region FROM subscribers WHERE region = 'Île-de-France';" "Abonnés en Île-de-France"

# Test 2: Filtrage par département
run_query "SELECT email, name, departement_nom FROM subscribers WHERE departement_numero = '69';" "Abonnés dans le Rhône (69)"

# Test 3: Filtrage par commune
run_query "SELECT email, name, commune FROM subscribers WHERE commune = 'Paris';" "Abonnés à Paris"

# Test 4: Filtrage par CSP
run_query "SELECT email, name, csp FROM subscribers WHERE csp = 'Cadre';" "Abonnés cadres"

echo ""
echo "🎯 TESTS DES FILTRES COMBINÉS"
echo ""

# Test 5: Région + CSP
run_query "SELECT email, name, region, csp FROM subscribers WHERE region = 'Île-de-France' AND csp = 'Cadre';" "Cadres en Île-de-France"

# Test 6: Département + Âge
run_query "SELECT email, name, age, departement_nom FROM subscribers WHERE departement_numero = '75' AND age < 40;" "Parisiens de moins de 40 ans"

# Test 7: Régions multiples
run_query "SELECT email, name, region FROM subscribers WHERE region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie');" "Abonnés dans le Sud (PACA + Occitanie)"

echo ""
echo "📊 TESTS DES VUES PRÉDÉFINIES"
echo ""

# Test 8: Vue Île-de-France
run_query "SELECT * FROM abonnes_ile_de_france;" "Vue abonnés Île-de-France"

# Test 9: Vue cadres
run_query "SELECT * FROM abonnes_cadres;" "Vue abonnés cadres"

# Test 10: Vue grandes métropoles
run_query "SELECT email, name, region, pop_dept FROM abonnes_grandes_metropoles;" "Vue grandes métropoles"

echo ""
echo "📈 TESTS DES STATISTIQUES"
echo ""

# Test 11: Statistiques géographiques
run_query "SELECT * FROM stats_geographiques;" "Statistiques géographiques complètes"

# Test 12: Comptage par région
run_query "SELECT region, COUNT(*) as nb FROM subscribers WHERE region IS NOT NULL GROUP BY region ORDER BY nb DESC;" "Comptage par région"

# Test 13: Comptage par CSP
run_query "SELECT csp, COUNT(*) as nb FROM subscribers WHERE csp IS NOT NULL GROUP BY csp ORDER BY nb DESC;" "Comptage par CSP"

echo ""
echo "🔧 TESTS DE PERFORMANCE"
echo ""

# Test 14: Performance avec index
print_test "Test de performance des index géographiques"
echo "EXPLAIN ANALYZE: SELECT * FROM subscribers WHERE region = 'Île-de-France';"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "EXPLAIN ANALYZE SELECT * FROM subscribers WHERE region = 'Île-de-France';" 2>/dev/null
print_separator

echo ""
echo "🎉 RÉSUMÉ DES TESTS"
echo "=================="

# Comptage final
total_abonnes=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
abonnes_geo=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE region IS NOT NULL;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
nb_regions=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(DISTINCT region) FROM subscribers WHERE region IS NOT NULL;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
nb_departements=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(DISTINCT departement_numero) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')

echo "✅ Total abonnés: $total_abonnes"
echo "✅ Abonnés avec données géographiques: $abonnes_geo"
echo "✅ Nombre de régions représentées: $nb_regions"
echo "✅ Nombre de départements représentés: $nb_departements"

echo ""
echo "🚀 FILTRES PRÊTS POUR LISTMONK"
echo "=============================="
echo ""
echo "Vous pouvez maintenant utiliser ces filtres simples dans l'interface Listmonk :"
echo ""
echo "• region = 'Île-de-France'"
echo "• departement_numero = '75'"
echo "• commune = 'Paris'"
echo "• csp = 'Cadre'"
echo "• age < 40"
echo "• region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie')"
echo ""
echo "Ou utiliser directement les vues prédéfinies :"
echo "• SELECT * FROM abonnes_ile_de_france"
echo "• SELECT * FROM abonnes_cadres"
echo "• SELECT * FROM abonnes_grandes_metropoles"
echo ""
echo "🎯 Interface Listmonk: http://localhost:9000"
echo "🗄️ Interface Adminer: http://localhost:8080"
echo ""
echo "Bon marketing géographique ! 🗺️📧"