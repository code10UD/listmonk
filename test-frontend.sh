#!/bin/bash

# Test rapide du frontend avec interface géographique

set -e

echo "🧪 TEST FRONTEND LISTMONK GÉOGRAPHIQUE"
echo "======================================"

cd "$(dirname "$0")"

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "npm run dev" || true
sleep 2

# Démarrer le frontend
echo "🎨 Démarrage du frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!

# Attendre le démarrage
sleep 8

# Tester l'accès
echo "🔍 Test d'accès..."
for port in 12000 12001 12002 12003; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/admin | grep -q "200"; then
        echo "✅ Frontend accessible sur port $port"
        echo ""
        echo "🌐 ACCÈS : http://localhost:$port/admin"
        echo ""
        echo "🎯 TESTS À EFFECTUER :"
        echo "   1. Aller dans 'Abonnés'"
        echo "   2. Cliquer sur 'Recherche avancée'"
        echo "   3. Tester le sélecteur géographique"
        echo "   4. Créer un nouvel abonné"
        echo "   5. Tester l'onglet 'Sélection géographique'"
        echo ""
        echo "📋 POUR ARRÊTER : Ctrl+C"
        
        # Attendre Ctrl+C
        trap "echo ''; echo '🛑 Arrêt du test...'; kill $FRONTEND_PID 2>/dev/null || true; exit 0" SIGINT
        wait $FRONTEND_PID
        exit 0
    fi
done

echo "❌ Frontend non accessible"
kill $FRONTEND_PID 2>/dev/null || true
exit 1