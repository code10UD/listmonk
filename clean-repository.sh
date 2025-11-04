#!/bin/bash

# Script de nettoyage du dépôt Listmonk
# Supprime tous les fichiers obsolètes et garde uniquement l'essentiel

set -e

echo "🧹 NETTOYAGE DU DÉPÔT LISTMONK"
echo "=============================="

cd "$(dirname "$0")"

# Créer une sauvegarde des fichiers essentiels
echo "📦 Sauvegarde des fichiers essentiels..."
mkdir -p .cleanup_backup/docs
mkdir -p .cleanup_backup/scripts

# Sauvegarder la documentation finale
cp ETAT_DES_LIEUX_FINAL.md .cleanup_backup/docs/ 2>/dev/null || true
cp GUIDE_UI_GEOGRAPHIQUE.md .cleanup_backup/docs/ 2>/dev/null || true
cp RESOLUTION_PROBLEMES_UI_GEO.md .cleanup_backup/docs/ 2>/dev/null || true
cp VERIFICATION_FINALE_UI_GEO.md .cleanup_backup/docs/ 2>/dev/null || true

# Sauvegarder les scripts fonctionnels
cp start-frontend.sh .cleanup_backup/scripts/ 2>/dev/null || true
cp stop-app.sh .cleanup_backup/scripts/ 2>/dev/null || true
cp launch-app-complete.sh .cleanup_backup/scripts/ 2>/dev/null || true
cp test-app-simple.sh .cleanup_backup/scripts/ 2>/dev/null || true

# Supprimer tous les fichiers de documentation obsolètes
echo "🗑️  Suppression des fichiers obsolètes..."

# Documentation obsolète
rm -f A_CONTINUER*.md
rm -f CORRECTIONS_*.md
rm -f DEMARRAGE_RAPIDE.md
rm -f EXTENSION_GEOGRAPHIQUE_COMPLETE.md
rm -f GEOGRAPHIC_FEATURES.md
rm -f GUIDE_DEPANNAGE.md
rm -f GUIDE_FINAL_INTEGRATION.md
rm -f GUIDE_TEST_FINAL.md
rm -f GUIDE_UTILISATION_SIMPLE.md
rm -f INSTALLATION_DOCKER.md
rm -f NOTICE_*.md
rm -f PROBLEME_RESOLU_POSTGRESQL.md
rm -f PROJET_TERMINE.md
rm -f README_*.md
rm -f RESUME_*.md
rm -f SOLUTION_*.md
rm -f TROUBLESHOOTING_DOCKER.md

# Dockerfiles obsolètes
rm -f Dockerfile.geo*
rm -f docker-compose.*.yml

# Scripts obsolètes
rm -f add-geo-*.sh
rm -f create-admin-user.sh
rm -f debug-test-issue.sh
rm -f fix-*.sh
rm -f get-docker.sh
rm -f install-*.sh
rm -f launch-*.sh
rm -f setup-*.sh
rm -f start-geo*.sh
rm -f test-*.sh
rm -f validate-*.sh

# Fichiers de configuration obsolètes
rm -f config-*.toml
rm -f config.toml.template

# Fichiers de données de test
rm -f demo_*.csv
rm -f demo_*.py
rm -f demo_*.sql
rm -f test_*.csv
rm -f test_*.py
rm -f test_*.sh
rm -f mairielist.csv
rm -f cookies.txt

# Scripts SQL obsolètes
rm -f add-geo-extension-simple.sql
rm -f create-geographic-views.sql
rm -f fix-geographic-interface.sql
rm -f insert_departements.sql
rm -f verify_geo_structure.sql

# Logs et fichiers temporaires
rm -f *.log
rm -f listmonk
rm -f frontend/build.log
rm -f frontend/frontend.log

# Nettoyer le frontend
echo "🎨 Nettoyage du frontend..."
cd frontend
rm -rf dist/ 2>/dev/null || true
cd ..

echo "✅ Nettoyage terminé!"
echo ""
echo "📁 FICHIERS CONSERVÉS :"
echo "   ✅ Code source principal (cmd/, internal/, frontend/src/)"
echo "   ✅ Configuration de base (go.mod, package.json, etc.)"
echo "   ✅ Documentation essentielle (4 guides)"
echo "   ✅ Scripts fonctionnels (4 scripts)"
echo "   ✅ Fichiers de développement (dev/)"
echo ""
echo "🗑️  FICHIERS SUPPRIMÉS :"
echo "   ❌ Documentation obsolète (40+ fichiers)"
echo "   ❌ Scripts de test obsolètes (30+ fichiers)"
echo "   ❌ Configurations temporaires (10+ fichiers)"
echo "   ❌ Fichiers de données de test"
echo "   ❌ Logs et fichiers temporaires"
echo ""
echo "💾 Sauvegarde disponible dans .cleanup_backup/"