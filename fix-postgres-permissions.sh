#!/bin/bash

echo "🔧 Correction des permissions PostgreSQL 15 pour Listmonk"

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

step "Correction des permissions PostgreSQL 15"

# Donner les permissions complètes à l'utilisateur listmonk
step "Attribution des permissions sur le schéma public..."

sudo -u postgres psql << 'EOF'
-- Se connecter à la base listmonk
\c listmonk

-- Donner toutes les permissions sur le schéma public
GRANT ALL ON SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO listmonk;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO listmonk;

-- Permissions par défaut pour les futurs objets
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO listmonk;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO listmonk;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO listmonk;

-- Rendre listmonk propriétaire du schéma public
ALTER SCHEMA public OWNER TO listmonk;

-- Donner des privilèges SUPERUSER temporairement pour l'installation
ALTER USER listmonk SUPERUSER;

-- Afficher les permissions
\dp

-- Quitter
\q
EOF

if [ $? -eq 0 ]; then
    success "Permissions corrigées"
else
    error "Erreur lors de la correction des permissions"
    exit 1
fi

# Test de la connexion avec les nouvelles permissions
step "Test de la connexion avec les nouvelles permissions..."

if PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "CREATE TABLE test_permissions (id INTEGER); DROP TABLE test_permissions;" > /dev/null 2>&1; then
    success "Test de création de table réussi"
else
    error "Échec du test de permissions"
    echo "Essayons une approche alternative..."
    
    # Approche alternative : recréer complètement l'utilisateur avec SUPERUSER
    step "Recréation de l'utilisateur avec privilèges SUPERUSER..."
    
    sudo -u postgres psql << 'EOF'
-- Supprimer et recréer l'utilisateur avec SUPERUSER
DROP USER IF EXISTS listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk' SUPERUSER CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;

-- Se connecter à la base listmonk
\c listmonk

-- S'assurer que listmonk est propriétaire du schéma
ALTER SCHEMA public OWNER TO listmonk;
EOF
    
    # Test final
    if PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
        success "Utilisateur recréé avec succès"
    else
        error "Échec de la recréation de l'utilisateur"
        exit 1
    fi
fi

echo ""
success "🎉 Permissions PostgreSQL corrigées !"
echo ""
echo "🚀 Vous pouvez maintenant exécuter :"
echo "   ./install-no-docker-fixed.sh"
echo ""
echo "💡 Note : L'utilisateur 'listmonk' a temporairement les privilèges SUPERUSER"
echo "   pour permettre l'installation. Vous pourrez les révoquer après l'installation."