#!/bin/bash

echo "🎨 Compilation du Frontend Listmonk"

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""

# Vérifications préalables
step "Vérifications préalables"

if [ ! -d "frontend" ]; then
    error "Répertoire frontend/ non trouvé"
    exit 1
fi

if [ ! -f "frontend/package.json" ]; then
    error "package.json non trouvé dans frontend/"
    exit 1
fi

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    error "Node.js n'est pas installé"
    echo "Installez Node.js depuis https://nodejs.org/"
    echo "Ou utilisez : curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

NODE_VERSION=$(node --version)
success "Node.js $NODE_VERSION détecté"

echo ""

# Compilation du frontend
step "Compilation du frontend"

cd frontend

# Nettoyer les anciens builds
if [ -d "dist" ]; then
    warning "Suppression de l'ancien build..."
    rm -rf dist
fi

if [ -d "node_modules" ]; then
    warning "Suppression des anciens node_modules..."
    rm -rf node_modules
fi

# Installation des dépendances
step "Installation des dépendances..."
if command -v yarn &> /dev/null; then
    yarn install
    if [ $? -ne 0 ]; then
        error "Erreur lors de l'installation avec yarn"
        exit 1
    fi
    success "Dépendances installées avec yarn"
    
    # Build
    step "Compilation avec yarn..."
    yarn build
    if [ $? -ne 0 ]; then
        error "Erreur lors de la compilation avec yarn"
        exit 1
    fi
elif command -v npm &> /dev/null; then
    npm install
    if [ $? -ne 0 ]; then
        error "Erreur lors de l'installation avec npm"
        exit 1
    fi
    success "Dépendances installées avec npm"
    
    # Build
    step "Compilation avec npm..."
    npm run build
    if [ $? -ne 0 ]; then
        error "Erreur lors de la compilation avec npm"
        exit 1
    fi
else
    error "Ni yarn ni npm trouvé"
    echo "Installez npm : sudo apt-get install npm"
    exit 1
fi

cd ..

# Vérification du build
if [ -d "frontend/dist" ] && [ "$(ls -A frontend/dist)" ]; then
    success "Frontend compilé avec succès"
    
    # Afficher les fichiers générés
    echo ""
    step "Fichiers générés :"
    ls -la frontend/dist/ | head -10
    
    if [ $(ls frontend/dist/ | wc -l) -gt 10 ]; then
        echo "... et $(( $(ls frontend/dist/ | wc -l) - 10 )) autres fichiers"
    fi
else
    error "Échec de la compilation du frontend"
    exit 1
fi

echo ""
success "🎉 FRONTEND COMPILÉ AVEC SUCCÈS !"
echo ""
echo "Vous pouvez maintenant :"
echo "• Lancer l'installation : ./install-no-docker-fixed.sh"
echo "• Ou démarrer Listmonk : go run cmd/*.go --config config.toml"