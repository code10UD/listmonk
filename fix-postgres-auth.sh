#!/bin/bash

echo "🔧 Correction de l'authentification PostgreSQL pour Listmonk"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Étape 1: Créer la base et l'utilisateur
echo "🔄 Création de la base de données et de l'utilisateur..."
sudo -u postgres psql << 'EOF'
-- Supprimer si existe déjà
DROP DATABASE IF EXISTS listmonk;
DROP USER IF EXISTS listmonk;

-- Créer la base et l'utilisateur
CREATE DATABASE listmonk;
CREATE USER listmonk WITH PASSWORD 'listmonk';
GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
ALTER USER listmonk CREATEDB;
\q
EOF

if [ $? -eq 0 ]; then
    success "Base de données et utilisateur créés"
else
    error "Erreur lors de la création"
    exit 1
fi

# Étape 2: Configurer l'authentification
echo "🔄 Configuration de l'authentification PostgreSQL..."

# Trouver le fichier pg_hba.conf
PG_HBA_FILE=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)

if [ -z "$PG_HBA_FILE" ]; then
    error "Fichier pg_hba.conf non trouvé"
    echo "Configurez manuellement l'authentification PostgreSQL"
    exit 1
fi

info "Fichier trouvé: $PG_HBA_FILE"

# Sauvegarder le fichier original
sudo cp "$PG_HBA_FILE" "$PG_HBA_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Ajouter la ligne d'authentification pour listmonk
if ! sudo grep -q "local.*listmonk.*md5" "$PG_HBA_FILE"; then
    echo "local   all             listmonk                                md5" | sudo tee -a "$PG_HBA_FILE" > /dev/null
    success "Configuration ajoutée"
else
    success "Configuration déjà présente"
fi

# Redémarrer PostgreSQL
echo "🔄 Redémarrage de PostgreSQL..."
sudo systemctl restart postgresql

if [ $? -eq 0 ]; then
    success "PostgreSQL redémarré"
else
    error "Erreur lors du redémarrage"
    exit 1
fi

# Attendre que PostgreSQL soit prêt
sleep 3

# Tester la connexion
echo "🔄 Test de la connexion..."
if PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    success "Connexion réussie !"
    echo ""
    echo "🎉 Configuration terminée !"
    echo "🚀 Vous pouvez maintenant exécuter: ./install-no-docker.sh"
else
    error "Connexion échouée"
    echo ""
    echo "Configuration manuelle nécessaire :"
    echo "1. Éditez $PG_HBA_FILE"
    echo "2. Ajoutez: local   all   listmonk   md5"
    echo "3. Redémarrez: sudo systemctl restart postgresql"
    echo "4. Testez: PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost"
fi