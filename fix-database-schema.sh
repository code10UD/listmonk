#!/bin/bash

# Script pour corriger le schéma de base de données et ajouter les colonnes géographiques

set -e

echo "🔧 CORRECTION DU SCHÉMA DE BASE DE DONNÉES"
echo "=========================================="

cd "$(dirname "$0")"

# Vérifier que PostgreSQL est en cours
if ! docker ps | grep -q "dev-db-1"; then
    echo "❌ PostgreSQL n'est pas en cours. Démarrez-le d'abord avec:"
    echo "   cd dev && docker-compose up -d db"
    exit 1
fi

echo "🗺️  Ajout des colonnes géographiques à la table subscribers..."

# Ajouter les colonnes géographiques à la table subscribers
docker-compose -f dev/docker-compose.yml exec -T db psql -U listmonk-dev -d listmonk-dev << 'EOF'
-- Ajouter toutes les colonnes nécessaires à la table subscribers si elles n'existent pas
DO $$ 
BEGIN
    -- Colonnes géographiques de base
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='code_insee') THEN
        ALTER TABLE subscribers ADD COLUMN code_insee VARCHAR(10);
        CREATE INDEX IF NOT EXISTS idx_subs_code_insee ON subscribers(code_insee);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='population_commune') THEN
        ALTER TABLE subscribers ADD COLUMN population_commune INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='date_naissance') THEN
        ALTER TABLE subscribers ADD COLUMN date_naissance DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='csp') THEN
        ALTER TABLE subscribers ADD COLUMN csp VARCHAR(255);
        CREATE INDEX IF NOT EXISTS idx_subs_csp ON subscribers(csp);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='siren') THEN
        ALTER TABLE subscribers ADD COLUMN siren VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='siret') THEN
        ALTER TABLE subscribers ADD COLUMN siret VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='telecopie') THEN
        ALTER TABLE subscribers ADD COLUMN telecopie VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='nom_commune') THEN
        ALTER TABLE subscribers ADD COLUMN nom_commune VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='departement_numero') THEN
        ALTER TABLE subscribers ADD COLUMN departement_numero VARCHAR(10);
        CREATE INDEX IF NOT EXISTS idx_subs_departement ON subscribers(departement_numero);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='phone') THEN
        ALTER TABLE subscribers ADD COLUMN phone VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='website') THEN
        ALTER TABLE subscribers ADD COLUMN website VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='address1') THEN
        ALTER TABLE subscribers ADD COLUMN address1 TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='city') THEN
        ALTER TABLE subscribers ADD COLUMN city VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='state') THEN
        ALTER TABLE subscribers ADD COLUMN state VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='zipcode') THEN
        ALTER TABLE subscribers ADD COLUMN zipcode VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='country') THEN
        ALTER TABLE subscribers ADD COLUMN country VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='title') THEN
        ALTER TABLE subscribers ADD COLUMN title VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscribers' AND column_name='region_nom') THEN
        ALTER TABLE subscribers ADD COLUMN region_nom VARCHAR(255);
        CREATE INDEX IF NOT EXISTS idx_subs_region ON subscribers(region_nom);
    END IF;
END $$;

-- Vérifier que les colonnes ont été ajoutées
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscribers' 
  AND column_name IN ('code_insee', 'population_commune', 'date_naissance', 'csp', 'siren', 'siret', 
                      'telecopie', 'nom_commune', 'departement_numero', 'phone', 'website', 
                      'address1', 'city', 'state', 'zipcode', 'country', 'title', 'region_nom')
ORDER BY column_name;

\q
EOF

echo "✅ Toutes les colonnes nécessaires ajoutées à la table subscribers!"

echo ""
echo "🎯 COLONNES AJOUTÉES :"
echo "   ✅ Géographiques : code_insee, nom_commune, departement_numero, region_nom"
echo "   ✅ Démographiques : population_commune, date_naissance, csp"
echo "   ✅ Entreprise : siren, siret, telecopie"
echo "   ✅ Contact : phone, website, address1, city, state, zipcode, country, title"
echo ""
echo "📊 Index créés pour optimiser les requêtes géographiques"
echo ""
echo "✅ Base de données prête pour toutes les fonctionnalités!"