#!/bin/bash

# Script de démarrage du frontend Listmonk avec interface géographique
# Démarre le serveur de développement Vite sur le port 12000

set -e

echo "🚀 DÉMARRAGE DU FRONTEND LISTMONK GÉOGRAPHIQUE"
echo "=============================================="

# Aller dans le répertoire frontend
cd "$(dirname "$0")/frontend"

# Vérifier que les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Arrêter les processus existants
echo "🛑 Arrêt des processus frontend existants..."
pkill -f "npm run dev" || true
sleep 2

# Démarrer le serveur de développement
echo "🌐 Démarrage du serveur de développement..."
echo "   Port configuré : 12000 (ou suivant disponible)"
echo "   Host : 0.0.0.0 (accessible depuis l'extérieur)"
echo "   CORS : activé"
echo ""

# Démarrer en arrière-plan et afficher les logs
npm run dev &
DEV_PID=$!

# Attendre que le serveur démarre
sleep 3

echo ""
echo "✅ FRONTEND DÉMARRÉ!"
echo "==================="
echo "🌐 Interface accessible sur :"
echo "   - https://work-1-fidtkmufrlxauioj.prod-runtime.all-hands.dev (port 12000)"
echo "   - https://work-2-fidtkmufrlxauioj.prod-runtime.all-hands.dev (port 12001)"
echo "   - Ou le port suivant disponible"
echo ""
echo "🎯 Fonctionnalités géographiques disponibles :"
echo "   ✅ Sélecteur géographique dans la recherche d'abonnés"
echo "   ✅ Onglet géographique dans le formulaire d'abonné"
echo "   ✅ Filtrage par région, département, commune"
echo "   ✅ Filtrage par CSP et âge"
echo "   ✅ Synchronisation automatique avec les attributs JSON"
echo ""
echo "📋 Pour arrêter le serveur : Ctrl+C ou pkill -f 'npm run dev'"
echo ""

# Garder le script actif pour afficher les logs
wait $DEV_PID