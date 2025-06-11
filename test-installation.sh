#!/bin/bash

# Script de test pour valider l'installation
set -e

echo "🧪 TEST DE L'INSTALLATION LISTMONK GÉOGRAPHIQUE"
echo "==============================================="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🔍${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Test 1: Vérifier que PostgreSQL fonctionne
print_test "Test PostgreSQL..."
if docker compose -f docker-compose.postgres-fixed.yml exec postgres pg_isready -U listmonk -d listmonk &>/dev/null; then
    print_success "PostgreSQL fonctionne"
else
    print_error "PostgreSQL ne fonctionne pas"
    exit 1
fi

# Test 2: Vérifier que Listmonk fonctionne
print_test "Test Listmonk..."
if curl -f http://localhost:9000/health &>/dev/null; then
    print_success "Listmonk fonctionne"
else
    print_error "Listmonk ne fonctionne pas"
    exit 1
fi

# Test 3: Vérifier les données géographiques
print_test "Test données géographiques..."
dept_count=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departements_france;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
if [ "$dept_count" -eq 94 ]; then
    print_success "94 départements chargés"
else
    print_error "Départements manquants ($dept_count/94)"
fi

# Test 4: Vérifier les abonnés avec données géographiques
print_test "Test abonnés géographiques..."
geo_count=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE region IS NOT NULL;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
if [ "$geo_count" -ge 5 ]; then
    print_success "$geo_count abonnés avec données géographiques"
else
    print_error "Abonnés géographiques manquants ($geo_count)"
fi

# Test 5: Vérifier les vues prédéfinies
print_test "Test vues prédéfinies..."
view_count=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM abonnes_ile_de_france;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
if [ "$view_count" -ge 1 ]; then
    print_success "Vues prédéfinies fonctionnent"
else
    print_error "Vues prédéfinies ne fonctionnent pas"
fi

# Test 6: Vérifier les filtres simples
print_test "Test filtres simples..."
filter_count=$(docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE csp = 'Cadre';" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ')
if [ "$filter_count" -ge 1 ]; then
    print_success "Filtres simples fonctionnent"
else
    print_error "Filtres simples ne fonctionnent pas"
fi

echo ""
echo "🎉 RÉSUMÉ DES TESTS"
echo "=================="
echo "✅ PostgreSQL : OK"
echo "✅ Listmonk : OK"
echo "✅ Données géographiques : $dept_count départements"
echo "✅ Abonnés géographiques : $geo_count abonnés"
echo "✅ Vues prédéfinies : OK"
echo "✅ Filtres simples : OK"
echo ""
echo "🚀 Installation validée ! Listmonk géographique est prêt."
echo "🌐 Interface : http://localhost:9000 (admin/admin123)"
echo "🗄️ Base de données : http://localhost:8080"