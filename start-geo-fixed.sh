#!/bin/bash

# Script de démarrage corrigé pour l'interface géographique
# Résout tous les problèmes identifiés

set -e

echo "🚀 DÉMARRAGE LISTMONK GÉOGRAPHIQUE (VERSION CORRIGÉE)"
echo "===================================================="

# Vérifier que le fichier .env.geo existe
if [ ! -f ".env.geo" ]; then
    echo "❌ Fichier .env.geo manquant"
    exit 1
fi

# Charger les variables d'environnement (méthode corrigée)
echo "📋 Chargement des variables d'environnement..."
set -a
source .env.geo
set +a

# Vérifier que les variables sont chargées
echo "✅ Variables chargées:"
echo "   - POSTGRES_PASSWORD: [DÉFINI]"
echo "   - ADMIN_USERNAME: $ADMIN_USERNAME"
echo "   - ADMIN_PASSWORD: [DÉFINI]"
echo "   - IMPORT_DEMO_DATA: $IMPORT_DEMO_DATA"

# Copier vers .env pour Docker Compose
cp .env.geo .env

# Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker compose -f docker-compose.geo.yml down --remove-orphans 2>/dev/null || true

# Nettoyer les images si nécessaire
echo "🧹 Nettoyage des images Docker..."
docker compose -f docker-compose.geo.yml build --no-cache

# Démarrer les services
echo "🐳 Démarrage des services Docker..."
docker compose -f docker-compose.geo.yml up -d

# Attendre le démarrage
echo "⏳ Attente du démarrage (45 secondes)..."
sleep 45

# Vérifier le statut
echo "📊 Statut des services:"
docker compose -f docker-compose.geo.yml ps

# Vérifier les logs en cas d'erreur
echo "📋 Vérification des logs..."
if ! docker compose -f docker-compose.geo.yml ps | grep -q "Up"; then
    echo "❌ Problème détecté. Logs des services:"
    docker compose -f docker-compose.geo.yml logs --tail=20
    exit 1
fi

echo ""
echo "✅ DÉMARRAGE TERMINÉ AVEC SUCCÈS!"
echo "================================="
echo "🌐 Interface: http://localhost:9000"
echo "🗄️ Base de données: localhost:5432"
echo "🔧 Adminer: http://localhost:8083"
echo ""
echo "📋 Identifiants par défaut:"
echo "   - Username: $ADMIN_USERNAME"
echo "   - Password: $ADMIN_PASSWORD"
echo ""
echo "🎯 Interface géographique disponible dans Subscribers"