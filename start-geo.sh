#!/bin/bash

# Script de démarrage simple pour l'interface géographique
# Charge automatiquement les variables d'environnement

set -e

echo "🚀 DÉMARRAGE LISTMONK GÉOGRAPHIQUE"
echo "=================================="

# Vérifier que le fichier .env.geo existe
if [ ! -f ".env.geo" ]; then
    echo "❌ Fichier .env.geo manquant"
    exit 1
fi

# Charger les variables d'environnement
echo "📋 Chargement des variables d'environnement..."
set -a  # Exporter automatiquement toutes les variables
source .env.geo
set +a  # Désactiver l'export automatique

# Afficher les variables chargées (sans les mots de passe)
echo "✅ Variables chargées:"
echo "   - POSTGRES_PASSWORD: [DÉFINI]"
echo "   - ADMIN_USERNAME: $ADMIN_USERNAME"
echo "   - ADMIN_PASSWORD: [DÉFINI]"
echo "   - IMPORT_DEMO_DATA: $IMPORT_DEMO_DATA"

# Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker compose -f docker-compose.geo.yml down --remove-orphans 2>/dev/null || true

# Démarrer les services
echo "🐳 Démarrage des services Docker..."
docker compose -f docker-compose.geo.yml up -d

# Attendre le démarrage
echo "⏳ Attente du démarrage (30 secondes)..."
sleep 30

# Vérifier le statut
echo "📊 Statut des services:"
docker compose -f docker-compose.geo.yml ps

echo ""
echo "✅ DÉMARRAGE TERMINÉ!"
echo "===================="
echo "🌐 Interface: http://localhost:9000"
echo "🗄️ Base de données: localhost:5432"
echo "🔧 Adminer: http://localhost:8080"
echo ""
echo "📋 Identifiants par défaut:"
echo "   - Username: $ADMIN_USERNAME"
echo "   - Password: [voir .env.geo]"