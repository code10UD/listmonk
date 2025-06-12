#!/bin/bash

echo "⚡ INSTALLATION COMPLÈTE LISTMONK + EXTENSION GÉOGRAPHIQUE"
echo "========================================================="

# Étape 1: Installation de base
echo "🚨 ÉTAPE 1: Installation de base Listmonk"
./fix-brutal.sh

# Attendre que l'application soit prête
echo ""
echo "⏳ Attente que l'application soit complètement prête..."
sleep 15

# Étape 2: Ajout de l'extension géographique
echo ""
echo "🗺️ ÉTAPE 2: Ajout de l'extension géographique française"
echo "Connexion à PostgreSQL et ajout des colonnes..."

# Exécution du script SQL
docker-compose exec -T db psql -U postgres -d listmonk < add-geo-extension-simple.sql

echo ""
echo "✅ INSTALLATION COMPLÈTE TERMINÉE !"
echo "=================================="
echo ""
echo "🌐 Application accessible : http://localhost:9000"
echo "👤 Login : admin"
echo "🔑 Password : listmonk"
echo ""
echo "🗺️ Extension géographique française installée :"
echo "   • 13 régions françaises"
echo "   • 95 départements"
echo "   • 10 colonnes géographiques sur les abonnés"
echo "   • Index optimisés pour les recherches"
echo ""
echo "📋 Vérification finale..."
docker-compose ps
echo ""
curl -s -o /dev/null -w "Status HTTP: %{http_code}\n" http://localhost:9000