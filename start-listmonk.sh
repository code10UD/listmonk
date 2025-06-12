#!/bin/bash

# Script de démarrage simple pour Listmonk
echo "🚀 Démarrage de Listmonk avec extensions géographiques"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Utiliser le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Vérifier si le fichier de config existe
if [ ! -f "config.toml" ]; then
    echo -e "${RED}❌ Fichier config.toml manquant${NC}"
    echo "Exécutez d'abord: ./install-no-docker.sh"
    exit 1
fi

# Vérifier PostgreSQL
if ! systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "${RED}❌ PostgreSQL n'est pas démarré${NC}"
    echo "Démarrez PostgreSQL: sudo systemctl start postgresql"
    exit 1
fi

# Vérifier la connexion DB
if ! PGPASSWORD=listmonk psql -U listmonk -d listmonk -h localhost -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}❌ Impossible de se connecter à la base de données${NC}"
    echo "Vérifiez la configuration PostgreSQL"
    exit 1
fi

echo -e "${GREEN}✅ PostgreSQL connecté${NC}"

# Vérifier si le port 9000 est libre
if lsof -Pi :9000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}❌ Port 9000 déjà utilisé${NC}"
    echo "Arrêtez le processus existant ou changez le port dans config.toml"
    exit 1
fi

echo -e "${GREEN}✅ Port 9000 disponible${NC}"

# Démarrer Listmonk
echo -e "${BLUE}🔄 Démarrage de Listmonk...${NC}"
echo ""
echo "🌐 Interface admin: http://localhost:9000"
echo "👤 Email: admin | Mot de passe: admin"
echo ""
echo "Pour arrêter: Ctrl+C"
echo "Pour démarrer en arrière-plan: nohup ./start-listmonk.sh > listmonk.log 2>&1 &"
echo ""

# Démarrer avec logs en temps réel
go run cmd/*.go --config config.toml