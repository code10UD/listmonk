#!/bin/bash

# Script de lancement complet de l'application Listmonk avec interface géographique
# Lance backend + frontend + base de données

set -e

echo "🚀 LANCEMENT COMPLET DE LISTMONK GÉOGRAPHIQUE"
echo "=============================================="

# Aller dans le répertoire principal
cd "$(dirname "$0")"

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "npm run dev" || true
pkill -f "listmonk" || true
docker-compose -f dev/docker-compose.yml down || true
sleep 3

# Construire et lancer les services avec Docker Compose
echo "🐳 Démarrage des services Docker..."
cd dev
docker-compose up -d db mailhog adminer

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 10

# Vérifier que PostgreSQL est accessible
echo "🔍 Vérification de PostgreSQL..."
docker-compose exec -T db psql -U listmonk-dev -d listmonk-dev -c "SELECT version();" || {
    echo "❌ PostgreSQL n'est pas accessible"
    exit 1
}

# Retourner au répertoire principal
cd ..

# Construire le backend avec les extensions géographiques
echo "🔨 Construction du backend avec extensions géographiques..."
go build -o listmonk cmd/*.go

# Installer la base de données avec les extensions géographiques
echo "📊 Installation de la base de données..."
./listmonk --install --config dev/config.toml || {
    echo "⚠️  Installation déjà effectuée ou erreur, continuons..."
}

# Ajouter les extensions géographiques à la base
echo "🗺️  Ajout des extensions géographiques..."
docker-compose -f dev/docker-compose.yml exec -T db psql -U listmonk-dev -d listmonk-dev << 'EOF'
-- Créer l'extension PostGIS si elle n'existe pas
CREATE EXTENSION IF NOT EXISTS postgis;

-- Créer les tables géographiques si elles n'existent pas
CREATE TABLE IF NOT EXISTS geo_regions (
    id SERIAL PRIMARY KEY,
    region_nom VARCHAR(255) NOT NULL,
    region_code VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geo_departements (
    id SERIAL PRIMARY KEY,
    departement_numero VARCHAR(10) NOT NULL,
    departement_nom VARCHAR(255) NOT NULL,
    region_nom VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geo_communes (
    id SERIAL PRIMARY KEY,
    code_insee VARCHAR(10) NOT NULL,
    nom_commune VARCHAR(255) NOT NULL,
    code_postal VARCHAR(10),
    departement_numero VARCHAR(10) NOT NULL,
    region_nom VARCHAR(255) NOT NULL,
    population INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geo_csps (
    id SERIAL PRIMARY KEY,
    csp VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insérer quelques données de test si les tables sont vides
INSERT INTO geo_regions (region_nom, region_code) 
SELECT * FROM (VALUES 
    ('Île-de-France', 'IDF'),
    ('Auvergne-Rhône-Alpes', 'ARA'),
    ('Nouvelle-Aquitaine', 'NAQ'),
    ('Occitanie', 'OCC'),
    ('Hauts-de-France', 'HDF'),
    ('Grand Est', 'GES'),
    ('Provence-Alpes-Côte d''Azur', 'PAC'),
    ('Pays de la Loire', 'PDL'),
    ('Bretagne', 'BRE'),
    ('Normandie', 'NOR'),
    ('Bourgogne-Franche-Comté', 'BFC'),
    ('Centre-Val de Loire', 'CVL'),
    ('Corse', 'COR')
) AS v(region_nom, region_code)
WHERE NOT EXISTS (SELECT 1 FROM geo_regions LIMIT 1);

INSERT INTO geo_departements (departement_numero, departement_nom, region_nom)
SELECT * FROM (VALUES 
    ('75', 'Paris', 'Île-de-France'),
    ('77', 'Seine-et-Marne', 'Île-de-France'),
    ('78', 'Yvelines', 'Île-de-France'),
    ('91', 'Essonne', 'Île-de-France'),
    ('92', 'Hauts-de-Seine', 'Île-de-France'),
    ('93', 'Seine-Saint-Denis', 'Île-de-France'),
    ('94', 'Val-de-Marne', 'Île-de-France'),
    ('95', 'Val-d''Oise', 'Île-de-France'),
    ('69', 'Rhône', 'Auvergne-Rhône-Alpes'),
    ('13', 'Bouches-du-Rhône', 'Provence-Alpes-Côte d''Azur'),
    ('59', 'Nord', 'Hauts-de-France'),
    ('33', 'Gironde', 'Nouvelle-Aquitaine')
) AS v(departement_numero, departement_nom, region_nom)
WHERE NOT EXISTS (SELECT 1 FROM geo_departements LIMIT 1);

INSERT INTO geo_communes (code_insee, nom_commune, code_postal, departement_numero, region_nom, population)
SELECT * FROM (VALUES 
    ('75056', 'Paris', '75001', '75', 'Île-de-France', 2161000),
    ('69123', 'Lyon', '69001', '69', 'Auvergne-Rhône-Alpes', 515695),
    ('13055', 'Marseille', '13001', '13', 'Provence-Alpes-Côte d''Azur', 861635),
    ('59350', 'Lille', '59000', '59', 'Hauts-de-France', 232741),
    ('33063', 'Bordeaux', '33000', '33', 'Nouvelle-Aquitaine', 254436)
) AS v(code_insee, nom_commune, code_postal, departement_numero, region_nom, population)
WHERE NOT EXISTS (SELECT 1 FROM geo_communes LIMIT 1);

INSERT INTO geo_csps (csp, description)
SELECT * FROM (VALUES 
    ('Agriculteurs exploitants', 'Agriculteurs exploitants'),
    ('Artisans, commerçants et chefs d''entreprise', 'Artisans, commerçants et chefs d''entreprise'),
    ('Cadres et professions intellectuelles supérieures', 'Cadres et professions intellectuelles supérieures'),
    ('Professions intermédiaires', 'Professions intermédiaires'),
    ('Employés', 'Employés'),
    ('Ouvriers', 'Ouvriers'),
    ('Retraités', 'Retraités'),
    ('Autres personnes sans activité professionnelle', 'Autres personnes sans activité professionnelle')
) AS v(csp, description)
WHERE NOT EXISTS (SELECT 1 FROM geo_csps LIMIT 1);

\q
EOF

echo "✅ Extensions géographiques installées!"

# Démarrer le backend
echo "🔧 Démarrage du backend..."
./listmonk --config dev/config.toml &
BACKEND_PID=$!

# Attendre que le backend démarre
sleep 5

# Vérifier que le backend répond
echo "🔍 Vérification du backend..."
curl -s http://localhost:9000/api/health || {
    echo "❌ Backend non accessible"
    kill $BACKEND_PID || true
    exit 1
}

# Démarrer le frontend
echo "🎨 Démarrage du frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!

# Attendre que le frontend démarre
sleep 5

echo ""
echo "✅ APPLICATION LISTMONK GÉOGRAPHIQUE DÉMARRÉE!"
echo "=============================================="
echo ""
echo "🌐 ACCÈS À L'APPLICATION :"
echo "   Frontend : http://localhost:12000/admin (ou port suivant)"
echo "   Backend  : http://localhost:9000"
echo "   MailHog  : http://localhost:8025"
echo "   Adminer  : http://localhost:8070"
echo ""
echo "🎯 FONCTIONNALITÉS GÉOGRAPHIQUES DISPONIBLES :"
echo "   ✅ API géographique : /api/geo/*"
echo "   ✅ Sélecteur géographique dans la recherche"
echo "   ✅ Onglet géographique dans le formulaire d'abonné"
echo "   ✅ Base de données avec extensions PostGIS"
echo "   ✅ Données de test françaises"
echo ""
echo "🔧 SERVICES DOCKER :"
echo "   ✅ PostgreSQL avec PostGIS"
echo "   ✅ MailHog pour les emails"
echo "   ✅ Adminer pour la base de données"
echo ""
echo "📋 POUR ARRÊTER :"
echo "   Ctrl+C ou ./stop-app.sh"
echo ""

# Garder le script actif
wait $BACKEND_PID $FRONTEND_PID