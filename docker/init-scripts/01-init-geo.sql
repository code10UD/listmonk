-- Script d'initialisation pour l'extension géographique
-- Ce script est exécuté automatiquement par PostgreSQL au premier démarrage

\echo 'Initialisation de la base de données géographique...'

-- Créer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Optimisations pour les requêtes géographiques
-- Note: shared_preload_libraries nécessite un redémarrage de PostgreSQL
-- ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- Créer des index pour améliorer les performances des recherches textuelles
-- Ces index seront utilisés pour la recherche de communes
CREATE INDEX IF NOT EXISTS idx_trgm_commune_search ON information_schema.tables USING gin(table_name gin_trgm_ops) WHERE table_schema = 'public';

\echo 'Base de données géographique initialisée avec succès!'