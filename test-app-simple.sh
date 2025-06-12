#!/bin/bash

# Test simple de l'application avec frontend uniquement
# Pour vérifier que l'interface géographique fonctionne

set -e

echo "🧪 TEST SIMPLE DE L'INTERFACE GÉOGRAPHIQUE"
echo "=========================================="

cd "$(dirname "$0")"

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "npm run dev" || true
sleep 2

# Vérifier que les services Docker sont en cours
echo "🔍 Vérification des services Docker..."
cd dev
docker-compose ps

# Si PostgreSQL n'est pas en cours, le démarrer
if ! docker-compose ps | grep -q "dev-db-1.*Up"; then
    echo "🐳 Démarrage de PostgreSQL..."
    docker-compose up -d db
    sleep 10
fi

cd ..

# Construire le backend Go avec le PATH mis à jour
echo "🔨 Construction du backend..."
export PATH=$PATH:/usr/local/go/bin
go build -o listmonk cmd/*.go

# Démarrer le backend en arrière-plan
echo "🔧 Démarrage du backend..."
./listmonk --config dev/config.toml &
BACKEND_PID=$!

# Attendre que le backend démarre
sleep 5

# Vérifier que le backend répond
echo "🔍 Test du backend..."
if curl -s http://localhost:9000/api/health > /dev/null; then
    echo "✅ Backend accessible"
else
    echo "⚠️  Backend non accessible, continuons quand même..."
fi

# Démarrer le frontend
echo "🎨 Démarrage du frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!

# Attendre que le frontend démarre
sleep 5

echo ""
echo "✅ TEST DE L'INTERFACE GÉOGRAPHIQUE DÉMARRÉ!"
echo "============================================"
echo ""
echo "🌐 ACCÈS À L'APPLICATION :"
echo "   Frontend : http://localhost:12000/admin (ou port suivant)"
echo "   Backend  : http://localhost:9000"
echo ""
echo "🎯 TESTS À EFFECTUER :"
echo "   1. Aller dans 'Abonnés'"
echo "   2. Cliquer sur 'Recherche avancée'"
echo "   3. Tester le sélecteur géographique"
echo "   4. Créer un nouvel abonné"
echo "   5. Tester l'onglet 'Sélection géographique'"
echo ""
echo "📋 POUR ARRÊTER : Ctrl+C"
echo ""

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt des processus..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT

# Attendre
wait $BACKEND_PID $FRONTEND_PID