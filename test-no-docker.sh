#!/bin/bash

# Script de test pour installation sans Docker
echo "🧪 Test de l'installation Listmonk sans Docker"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo ""

# Test 1: PostgreSQL
echo -n "🗄️  PostgreSQL... "
if systemctl is-active --quiet postgresql 2>/dev/null; then
    success "Actif"
else
    error "Inactif"
fi

# Test 2: Base de données
echo -n "🔗 Connexion base de données... "
if psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    success "OK"
else
    error "Échec"
fi

# Test 3: Tables géographiques
echo -n "🗺️  Table departement_region_mapping... "
if count=$(psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' '); then
    success "OK ($count départements)"
else
    error "Manquante"
fi

# Test 4: Colonnes géographiques
echo -n "👥 Colonnes géographiques subscribers... "
if psql -U listmonk -d listmonk -h localhost -c "SELECT code_insee, departement_numero FROM subscribers LIMIT 1;" > /dev/null 2>&1; then
    success "Présentes"
else
    error "Manquantes"
fi

# Test 5: Backend (si démarré)
echo -n "🚀 Backend Listmonk... "
if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    success "Actif"
else
    info "Non démarré (normal)"
fi

# Test 6: Endpoints géographiques (si backend démarré)
if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    echo ""
    echo "🌐 Test des endpoints géographiques:"
    
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
fi

echo ""

# Statistiques
echo "📊 STATISTIQUES:"
total_subscribers=$(psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
geo_subscribers=$(psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' ')
total_regions=$(psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(DISTINCT region_nom) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
total_departements=$(psql -U listmonk -d listmonk -h localhost -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')

echo "   • Total abonnés: $total_subscribers"
echo "   • Abonnés avec données géo: $geo_subscribers"
echo "   • Régions françaises: $total_regions"
echo "   • Départements français: $total_departements"

echo ""

# Instructions
if ! curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    echo "🚀 POUR DÉMARRER LISTMONK:"
    echo "   ./start-listmonk.sh"
    echo ""
fi

echo "🌐 ACCÈS:"
echo "   • Interface: http://localhost:9000"
echo "   • Email: admin | Mot de passe: admin"
echo ""

echo "🔧 COMMANDES UTILES:"
echo "   • Démarrer: ./start-listmonk.sh"
echo "   • Arrêter: pkill -f 'go run cmd'"
echo "   • Logs: tail -f listmonk.log"
echo "   • Test DB: psql -U listmonk -d listmonk -h localhost"

echo ""
success "🎯 Test terminé !"