#!/bin/bash

echo "🔍 Debug de l'authentification Listmonk"

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

LISTMONK_URL="http://localhost:9000"

step "Test de l'endpoint de santé..."
curl -v "$LISTMONK_URL/api/health" 2>&1

echo ""
echo ""

step "Test de l'endpoint d'authentification avec détails..."
echo "URL: $LISTMONK_URL/api/auth/login"
echo "Données: {\"username\":\"admin\",\"password\":\"admin\"}"

response=$(curl -v -X POST "$LISTMONK_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' 2>&1)

echo "Réponse complète:"
echo "$response"

echo ""
echo ""

step "Test avec différents formats d'authentification..."

echo "1. Test avec email au lieu de username:"
curl -X POST "$LISTMONK_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin","password":"admin"}' 2>/dev/null | jq . 2>/dev/null || echo "Pas de réponse JSON valide"

echo ""
echo "2. Test avec user au lieu de username:"
curl -X POST "$LISTMONK_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"user":"admin","password":"admin"}' 2>/dev/null | jq . 2>/dev/null || echo "Pas de réponse JSON valide"

echo ""
echo "3. Vérification des utilisateurs dans la base:"
PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT id, email, name, type FROM users;" 2>/dev/null

echo ""
echo "4. Test avec les vraies données de la base:"
admin_email=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "SELECT email FROM users WHERE type='superadmin' LIMIT 1;" 2>/dev/null | tr -d ' ')

if [ ! -z "$admin_email" ]; then
    echo "Email admin trouvé: $admin_email"
    echo "Test avec cet email:"
    curl -X POST "$LISTMONK_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"$admin_email\",\"password\":\"admin\"}" 2>/dev/null | jq . 2>/dev/null || echo "Pas de réponse JSON valide"
else
    echo "Aucun utilisateur admin trouvé dans la base"
fi

echo ""
echo ""

step "Vérification des routes disponibles..."
echo "Test de quelques endpoints pour voir lesquels répondent:"

echo "GET /api/config:"
curl -s "$LISTMONK_URL/api/config" | head -c 200

echo ""
echo "GET /api/dashboard:"
curl -s "$LISTMONK_URL/api/dashboard" | head -c 200

echo ""
echo "GET /api/users:"
curl -s "$LISTMONK_URL/api/users" | head -c 200

echo ""
success "Debug terminé"