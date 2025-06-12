#!/bin/bash

# Script de lancement complet de l'application Listmonk avec interface géographique
# Lance backend + frontend + base de données PostgreSQL

set -e

echo "🚀 LANCEMENT COMPLET DE LISTMONK GÉOGRAPHIQUE"
echo "=============================================="

cd "$(dirname "$0")"

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "npm run dev" || true
pkill -f "listmonk" || true
docker-compose -f dev/docker-compose.yml down || true
sleep 3

# Démarrer PostgreSQL avec Docker
echo "🐳 Démarrage de PostgreSQL..."
cd dev
docker-compose up -d db
sleep 10

# Vérifier PostgreSQL
echo "🔍 Vérification de PostgreSQL..."
docker-compose exec -T db psql -U listmonk-dev -d listmonk-dev -c "SELECT version();" || {
    echo "❌ PostgreSQL non accessible"
    exit 1
}

cd ..

# Construire le backend
echo "🔨 Construction du backend..."
export PATH=$PATH:/usr/local/go/bin
go build -o listmonk cmd/*.go

# Installer la base de données
echo "📊 Installation de la base de données..."
./listmonk --install --config dev/config.toml || echo "⚠️ Installation déjà effectuée"

# Démarrer le backend
echo "🔧 Démarrage du backend..."
./listmonk --config dev/config.toml &
BACKEND_PID=$!
sleep 5

# Démarrer le frontend
echo "🎨 Démarrage du frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!
sleep 5

echo ""
echo "✅ APPLICATION LISTMONK GÉOGRAPHIQUE DÉMARRÉE!"
echo "=============================================="
echo ""
echo "🌐 ACCÈS :"
echo "   Frontend : http://localhost:12000/admin (ou port suivant)"
echo "   Backend  : http://localhost:9000"
echo ""
echo "🎯 FONCTIONNALITÉS GÉOGRAPHIQUES :"
echo "   ✅ Sélecteur géographique dans la recherche"
echo "   ✅ Onglet géographique dans le formulaire d'abonné"
echo "   ✅ API géographique complète"
echo ""
echo "📋 POUR ARRÊTER : Ctrl+C ou ./stop-app.sh"
echo ""

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt de l'application..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    cd dev && docker-compose down
    exit 0
}

trap cleanup SIGINT
wait $BACKEND_PID $FRONTEND_PID