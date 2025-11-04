#!/bin/bash

echo "🔍 DIAGNOSTIC LISTMONK - Extensions Géographiques Françaises"
echo "============================================================"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""

# 1. Vérification Go
echo "1️⃣  VÉRIFICATION GO"
echo "-------------------"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | cut -d' ' -f3)
    success "Go installé : $GO_VERSION"
    
    # Vérifier GOPATH
    if [ -n "$GOPATH" ]; then
        info "GOPATH : $GOPATH"
    else
        warning "GOPATH non défini (normal avec Go modules)"
    fi
else
    error "Go non installé"
    echo "   💡 Solution : ./install-go.sh ou https://golang.org/dl/"
fi

echo ""

# 2. Vérification PostgreSQL
echo "2️⃣  VÉRIFICATION POSTGRESQL"
echo "---------------------------"
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | awk '{print $3}')
    success "PostgreSQL installé : $PG_VERSION"
    
    # Vérifier si PostgreSQL est actif
    if pg_isready -q 2>/dev/null; then
        success "PostgreSQL actif"
        
        # Tester la connexion à la base listmonk
        if PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
            success "Base de données 'listmonk' accessible"
        else
            error "Base de données 'listmonk' inaccessible"
            echo "   💡 Solution : ./fix-postgres-auth.sh"
        fi
    else
        error "PostgreSQL inactif"
        echo "   💡 Solution : sudo systemctl start postgresql"
    fi
else
    error "PostgreSQL non installé"
    echo "   💡 Solution : sudo apt-get install postgresql postgresql-contrib"
fi

echo ""

# 3. Vérification Node.js et Frontend
echo "3️⃣  VÉRIFICATION FRONTEND"
echo "-------------------------"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js installé : $NODE_VERSION"
    
    # Vérifier npm/yarn
    if command -v yarn &> /dev/null; then
        YARN_VERSION=$(yarn --version)
        success "Yarn installé : $YARN_VERSION"
    elif command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        success "npm installé : $NPM_VERSION"
    else
        warning "Ni npm ni yarn trouvé"
    fi
else
    error "Node.js non installé"
    echo "   💡 Solution : curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
fi

# Vérifier le frontend compilé
if [ -d "frontend/dist" ] && [ "$(ls -A frontend/dist 2>/dev/null)" ]; then
    DIST_FILES=$(ls frontend/dist | wc -l)
    success "Frontend compilé ($DIST_FILES fichiers)"
else
    error "Frontend non compilé"
    echo "   💡 Solution : ./build-frontend.sh"
fi

echo ""

# 4. Vérification des fichiers du projet
echo "4️⃣  VÉRIFICATION FICHIERS PROJET"
echo "--------------------------------"

# Vérifier les fichiers essentiels
essential_files=("go.mod" "go.sum" "cmd/main.go" "frontend/package.json")
for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        success "Fichier présent : $file"
    else
        error "Fichier manquant : $file"
    fi
done

# Vérifier la branche Git
if command -v git &> /dev/null && [ -d ".git" ]; then
    CURRENT_BRANCH=$(git branch --show-current)
    success "Branche Git : $CURRENT_BRANCH"
    
    if [ "$CURRENT_BRANCH" = "feature/french-geographic-segmentation" ]; then
        success "Branche géographique active"
    else
        warning "Branche géographique non active"
        echo "   💡 Solution : git checkout feature/french-geographic-segmentation"
    fi
else
    warning "Pas de dépôt Git ou Git non installé"
fi

echo ""

# 5. Vérification de la base de données
echo "5️⃣  VÉRIFICATION BASE DE DONNÉES"
echo "--------------------------------"

if PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
    # Vérifier les tables
    tables_check=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "
        SELECT 
            CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscribers') THEN 'subscribers:OK' ELSE 'subscribers:MISSING' END ||
            ',' ||
            CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departement_region_mapping') THEN 'geo:OK' ELSE 'geo:MISSING' END
    " 2>/dev/null | tr -d ' ')
    
    if [[ $tables_check == *"subscribers:OK"* ]]; then
        success "Table 'subscribers' présente"
    else
        error "Table 'subscribers' manquante"
    fi
    
    if [[ $tables_check == *"geo:OK"* ]]; then
        success "Table 'departement_region_mapping' présente"
        
        # Compter les départements
        dept_count=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM departement_region_mapping;" 2>/dev/null | tr -d ' ')
        if [ "$dept_count" = "94" ]; then
            success "Données géographiques complètes (94 départements)"
        else
            warning "Données géographiques incomplètes ($dept_count départements)"
        fi
    else
        error "Table géographique manquante"
        echo "   💡 Solution : go run cmd/*.go --config config.toml --upgrade --yes"
    fi
    
    # Vérifier les colonnes géographiques
    geo_columns=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "
        SELECT COUNT(*) FROM information_schema.columns 
        WHERE table_name = 'subscribers' 
        AND column_name IN ('code_insee', 'departement_numero', 'nom_commune')
    " 2>/dev/null | tr -d ' ')
    
    if [ "$geo_columns" = "3" ]; then
        success "Colonnes géographiques présentes"
    else
        error "Colonnes géographiques manquantes ($geo_columns/3)"
    fi
    
    # Statistiques
    total_subs=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
    geo_subs=$(PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero IS NOT NULL;" 2>/dev/null | tr -d ' ')
    
    info "Statistiques : $total_subs abonnés total, $geo_subs avec données géo"
else
    error "Impossible de se connecter à la base de données"
fi

echo ""

# 6. Vérification des ports
echo "6️⃣  VÉRIFICATION PORTS"
echo "----------------------"

# Vérifier le port 9000
if command -v lsof &> /dev/null; then
    if lsof -i :9000 > /dev/null 2>&1; then
        warning "Port 9000 occupé"
        lsof -i :9000 | head -2
        echo "   💡 Solution : Changer le port dans config.toml ou arrêter le processus"
    else
        success "Port 9000 libre"
    fi
else
    info "lsof non disponible, impossible de vérifier les ports"
fi

echo ""

# 7. Vérification de la configuration
echo "7️⃣  VÉRIFICATION CONFIGURATION"
echo "------------------------------"

if [ -f "config.toml" ]; then
    success "Fichier config.toml présent"
    
    # Vérifier les paramètres essentiels
    if grep -q "database.*listmonk" config.toml; then
        success "Configuration base de données OK"
    else
        warning "Configuration base de données à vérifier"
    fi
    
    if grep -q "address.*9000" config.toml; then
        info "Port configuré : 9000"
    elif grep -q "address" config.toml; then
        port=$(grep "address" config.toml | cut -d':' -f3 | tr -d '"')
        info "Port configuré : $port"
    fi
else
    error "Fichier config.toml manquant"
    echo "   💡 Solution : Relancer l'installation"
fi

echo ""

# 8. Résumé et recommandations
echo "8️⃣  RÉSUMÉ ET RECOMMANDATIONS"
echo "============================="

echo ""
echo "📋 ACTIONS RECOMMANDÉES :"

# Analyser les problèmes détectés
if ! command -v go &> /dev/null; then
    echo "🔧 Installer Go : https://golang.org/dl/"
fi

if ! command -v psql &> /dev/null; then
    echo "🔧 Installer PostgreSQL : sudo apt-get install postgresql postgresql-contrib"
fi

if ! pg_isready -q 2>/dev/null; then
    echo "🔧 Démarrer PostgreSQL : sudo systemctl start postgresql"
fi

if ! PGPASSWORD=listmonk psql -h localhost -U listmonk -d listmonk -c "SELECT 1;" > /dev/null 2>&1; then
    echo "🔧 Configurer PostgreSQL : ./fix-postgres-auth.sh"
fi

if [ ! -d "frontend/dist" ] || [ -z "$(ls -A frontend/dist 2>/dev/null)" ]; then
    echo "🔧 Compiler le frontend : ./build-frontend.sh"
fi

if ! command -v node &> /dev/null; then
    echo "🔧 Installer Node.js : curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
fi

echo ""
echo "🚀 POUR INSTALLER LISTMONK :"
echo "   ./install-no-docker-fixed.sh"
echo ""
echo "🌐 POUR DÉMARRER LISTMONK :"
echo "   go run cmd/*.go --config config.toml"
echo ""
echo "📖 GUIDE DE RÉSOLUTION :"
echo "   cat GUIDE_RESOLUTION_PROBLEMES.md"

echo ""
echo "✨ Diagnostic terminé !"