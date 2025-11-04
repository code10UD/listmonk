#!/bin/bash

echo "🔍 Test des requêtes SQL géographiques"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "${BLUE}🔄 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

step "Test direct des requêtes SQL géographiques..."

echo "1. Test get-geo-regions:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT DISTINCT region_nom, region_code 
FROM departement_region_mapping 
ORDER BY region_nom 
LIMIT 3;"

echo ""
echo "2. Test get-geo-departements:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT departement_numero, departement_nom, region_nom, region_code
FROM departement_region_mapping 
ORDER BY departement_nom 
LIMIT 3;"

echo ""
echo "3. Test get-geo-communes:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT DISTINCT s.nom_commune, s.code_insee, s.population_commune, s.departement_numero,
       COUNT(*) as count
FROM subscribers s
WHERE s.nom_commune IS NOT NULL 
  AND s.nom_commune != ''
  AND ('' = '' OR s.nom_commune ILIKE '%' || '' || '%')
  AND ('' = '' OR s.departement_numero = '')
GROUP BY s.nom_commune, s.code_insee, s.population_commune, s.departement_numero
ORDER BY count DESC, s.nom_commune
LIMIT 3;"

echo ""
echo "4. Test get-geo-csps:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT s.csp, COUNT(*) as count
FROM subscribers s
WHERE s.csp IS NOT NULL AND s.csp != ''
GROUP BY s.csp
ORDER BY count DESC
LIMIT 3;"

echo ""
step "Vérification de la structure des tables..."

echo "Table departement_region_mapping:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "\d departement_region_mapping"

echo ""
echo "Colonnes géographiques de subscribers:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscribers' 
  AND column_name IN ('code_insee', 'nom_commune', 'departement_numero', 'csp', 'population_commune')
ORDER BY column_name;"

success "Tests SQL terminés"