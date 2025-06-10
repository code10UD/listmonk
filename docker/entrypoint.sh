#!/bin/sh

# Script d'entrée pour Listmonk avec extension géographique

set -e

echo "🚀 Démarrage de Listmonk avec extension géographique..."

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
while ! pg_isready -h $LISTMONK_DB_HOST -p $LISTMONK_DB_PORT -U $LISTMONK_DB_USER; do
  echo "PostgreSQL n'est pas encore prêt. Attente..."
  sleep 2
done

echo "✅ PostgreSQL est prêt!"

# Vérifier si la base de données est initialisée
echo "🗄️ Initialisation de la base de données..."
if ! ./listmonk --config config.toml --install --idempotent --yes; then
  echo "❌ Erreur lors de l'initialisation de la base de données"
  exit 1
fi

echo "✅ Base de données initialisée"

# Exécuter les migrations géographiques si nécessaire
echo "🗺️ Application des migrations géographiques..."
if ! ./listmonk --config config.toml --upgrade --yes; then
  echo "❌ Erreur lors des migrations géographiques"
  exit 1
fi

echo "✅ Migrations géographiques appliquées"

# Importer les données de démonstration si demandé
if [ "$LISTMONK_IMPORT_DEMO_DATA" = "true" ] && [ -f "/listmonk/demo/demo_geo_data.csv" ]; then
  echo "📊 Import des données de démonstration..."
  if [ -f "/listmonk/scripts/import_demo_data.sh" ]; then
    /listmonk/scripts/import_demo_data.sh
  else
    echo "⚠️ Script d'import de démonstration non trouvé"
  fi
fi

echo "🎉 Listmonk avec extension géographique prêt!"

# Démarrer l'application
exec "$@"