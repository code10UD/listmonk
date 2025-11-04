#!/bin/bash

# Script d'arrêt de l'application Listmonk

echo "🛑 ARRÊT DE L'APPLICATION LISTMONK"
echo "=================================="

# Arrêter les processus Node.js et Go
echo "Arrêt des processus frontend et backend..."
pkill -f "npm run dev" || true
pkill -f "listmonk" || true

# Arrêter les services Docker
echo "Arrêt des services Docker..."
cd "$(dirname "$0")/dev"
docker-compose down

echo "✅ Application arrêtée!"