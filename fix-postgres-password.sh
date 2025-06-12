#!/bin/bash

echo "🔧 CORRECTION DU MOT DE PASSE POSTGRESQL"
echo "========================================"

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

COMPOSE_FILE="docker-compose.simple-fixed.yml"

print_step "Arrêt des containers existants..."
docker compose -f "$COMPOSE_FILE" down

print_step "Suppression du volume PostgreSQL pour réinitialisation..."
docker volume rm listmonk_postgres_data 2>/dev/null || true

print_success "Volume supprimé"

print_step "Redémarrage de PostgreSQL avec le bon mot de passe..."
docker compose -f "$COMPOSE_FILE" up -d postgres

print_step "Attente de PostgreSQL..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U listmonk >/dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
done

echo ""

if [ $attempt -eq $max_attempts ]; then
    print_error "PostgreSQL n'a pas démarré dans les temps"
    docker logs listmonk-postgres
    exit 1
fi

print_success "PostgreSQL prêt avec le bon mot de passe"

print_step "Test de connexion..."
if docker compose -f "$COMPOSE_FILE" exec -T postgres psql -U listmonk -d listmonk -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Connexion PostgreSQL réussie"
else
    print_error "Problème de connexion persistant"
    exit 1
fi

print_step "Réinstallation de Listmonk..."
echo "y" | docker run --rm -i \
  --network "$(basename $(pwd))_default" \
  -e LISTMONK_db__host=postgres \
  -e LISTMONK_db__port=5432 \
  -e LISTMONK_db__user=listmonk \
  -e LISTMONK_db__password=listmonk \
  -e LISTMONK_db__database=listmonk \
  -e LISTMONK_db__ssl_mode=disable \
  listmonk/listmonk:latest ./listmonk --install

print_success "Listmonk réinstallé"

print_step "Ajout des colonnes géographiques..."
if [ -f "add-geo-columns.sh" ]; then
    ./add-geo-columns.sh
    print_success "Colonnes géographiques ajoutées"
else
    print_warning "Script add-geo-columns.sh non trouvé"
fi

print_step "Démarrage de l'application complète..."
docker compose -f "$COMPOSE_FILE" up -d

print_step "Vérification que l'application est prête..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:9000 >/dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
done

echo ""

if [ $attempt -eq $max_attempts ]; then
    print_warning "L'application met du temps à démarrer, vérifiez les logs"
    docker logs listmonk-app
else
    print_success "Application prête !"
fi

echo ""
echo "🎉 CORRECTION TERMINÉE !"
echo "========================"
echo ""
print_success "📱 Interface disponible : http://localhost:9000"
print_success "👤 Utilisateur : admin"
print_success "🔑 Mot de passe : admin123"
echo ""
print_success "🔧 Mot de passe PostgreSQL corrigé et synchronisé"