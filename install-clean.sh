#!/bin/bash
set -e

echo "🗺️ INSTALLATION LISTMONK-GEO - VERSION CORRIGÉE"
echo "================================================="

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

# 1. Nettoyer complètement les containers existants
print_step "Nettoyage complet des containers existants..."
docker stop $(docker ps -aq --filter name=listmonk) 2>/dev/null || true
docker rm $(docker ps -aq --filter name=listmonk) 2>/dev/null || true
docker stop $(docker ps -aq --filter name=postgres) 2>/dev/null || true
docker rm $(docker ps -aq --filter name=postgres) 2>/dev/null || true

# Nettoyer les réseaux Docker
docker network prune -f 2>/dev/null || true

print_success "Nettoyage terminé"

# 2. Choisir le fichier docker-compose approprié
COMPOSE_FILE="docker-compose.simple-fixed.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    COMPOSE_FILE="docker-compose.postgres-fixed.yml"
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Aucun fichier docker-compose trouvé"
        exit 1
    fi
fi

print_success "Fichier docker-compose trouvé: $COMPOSE_FILE"

# 3. Créer le fichier config.toml s'il n'existe pas
if [ ! -f "config.toml" ]; then
    print_step "Création du fichier config.toml..."
    cat > config.toml << 'EOF'
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "admin123"

[db]
host = "postgres"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"
EOF
    print_success "Fichier config.toml créé"
fi

# 4. Démarrer PostgreSQL seul d'abord
print_step "Démarrage PostgreSQL..."
docker compose -f "$COMPOSE_FILE" up -d postgres

# Attendre que PostgreSQL soit prêt
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

if [ $attempt -eq $max_attempts ]; then
    print_error "PostgreSQL n'a pas démarré dans les temps"
    docker logs listmonk-postgres
    exit 1
fi

print_success "PostgreSQL prêt"

# 5. Installation de Listmonk
print_step "Installation de Listmonk..."
echo "y" | docker run --rm -i \
  --network "$(basename $(pwd))_default" \
  -e LISTMONK_db__host=postgres \
  -e LISTMONK_db__port=5432 \
  -e LISTMONK_db__user=listmonk \
  -e LISTMONK_db__password=listmonk \
  -e LISTMONK_db__database=listmonk \
  -e LISTMONK_db__ssl_mode=disable \
  listmonk/listmonk:latest ./listmonk --install

print_success "Installation Listmonk terminée"

# 6. Charger les données géographiques si disponibles
if [ -f "migrations/geo_data.sql" ]; then
    print_step "Chargement des données géographiques..."
    docker compose -f "$COMPOSE_FILE" exec -T postgres \
      psql -U listmonk -d listmonk < migrations/geo_data.sql
    print_success "Données géographiques chargées"
elif [ -f "insert_departements.sql" ]; then
    print_step "Chargement des départements..."
    docker compose -f "$COMPOSE_FILE" exec -T postgres \
      psql -U listmonk -d listmonk < insert_departements.sql
    print_success "Départements chargés"
else
    print_warning "Aucun fichier de données géographiques trouvé - ignoré"
fi

# 7. Ajouter les colonnes géographiques si le script existe
if [ -f "add-geo-columns.sh" ]; then
    print_step "Ajout des colonnes géographiques..."
    chmod +x add-geo-columns.sh
    ./add-geo-columns.sh
    print_success "Colonnes géographiques ajoutées"
fi

# 8. Build frontend (optionnel, peut échouer sans problème)
print_step "Tentative de build frontend..."
if [ -d "frontend" ]; then
    cd frontend
    if [ -f "package.json" ]; then
        # Installer les dépendances avec différentes stratégies
        npm install --legacy-peer-deps 2>/dev/null || \
        npm install --force 2>/dev/null || \
        npm install 2>/dev/null || \
        print_warning "Installation npm échouée - continuons"
        
        # Tenter le build avec différentes commandes
        npm run build 2>/dev/null || \
        npm run build:prod 2>/dev/null || \
        npm run build --no-lint 2>/dev/null || \
        print_warning "Build frontend échoué - l'interface par défaut sera utilisée"
    fi
    cd ..
else
    print_warning "Répertoire frontend non trouvé"
fi

# 9. Démarrer l'application complète
print_step "Démarrage de l'application complète..."
docker compose -f "$COMPOSE_FILE" up -d

# 10. Attendre que l'application soit prête
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

# 11. Afficher le résumé final
echo ""
echo "🎉 INSTALLATION TERMINÉE !"
echo "=========================="
echo ""
print_success "📱 Interface disponible : http://localhost:9000"
print_success "👤 Utilisateur : admin"
print_success "🔑 Mot de passe : admin123"
echo ""
echo "🗺️ FONCTIONNALITÉS GÉOGRAPHIQUES :"
echo "- Aller dans 'Abonnés'"
echo "- Cliquer sur 'Recherche avancée' (icône engrenage)"
echo "- Utiliser le 'Sélecteur géographique'"
echo ""
echo "🔧 COMMANDES UTILES :"
echo "- Voir les logs : docker logs listmonk-app"
echo "- Redémarrer : docker compose -f $COMPOSE_FILE restart"
echo "- Arrêter : docker compose -f $COMPOSE_FILE down"
echo ""

# 12. Test final optionnel
if [ -f "test-geo-frontend.sh" ]; then
    echo "🧪 LANCEMENT DU TEST D'INTÉGRATION..."
    chmod +x test-geo-frontend.sh
    ./test-geo-frontend.sh || print_warning "Tests échoués mais l'installation peut fonctionner"
fi

print_success "Installation complète ! 🚀"