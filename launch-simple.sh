#!/bin/bash

# Script de lancement simplifié avec installation standard

set -e

echo "🚀 LANCEMENT LISTMONK AVEC INSTALLATION STANDARD"
echo "================================================="

cd "$(dirname "$0")"

# Configuration des variables d'environnement
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/tmp/go

# Arrêter les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "listmonk" || true
docker-compose -f dev/docker-compose.yml down || true
sleep 3

# Démarrer PostgreSQL avec Docker
echo "🐳 Démarrage de PostgreSQL..."
cd dev
docker-compose up -d db
sleep 10

cd ..

# Corriger le schéma de base de données
echo "🔧 Correction du schéma de base de données..."
./fix-database-schema.sh

# Obtenir l'IP du conteneur PostgreSQL
DB_IP=$(docker inspect dev-db-1 --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "📍 IP de la base de données: $DB_IP"

# Créer un fichier de configuration pour le backend
cat > config-simple.toml << EOF
[app]
address = "0.0.0.0:9000"

[db]
host = "$DB_IP"
port = 5432
user = "listmonk-dev"
password = "listmonk-dev"
database = "listmonk-dev"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"
params = ""
EOF

# Construire le backend
echo "🔨 Construction du backend..."
go build -o listmonk cmd/*.go

# Installer Listmonk (cela créera les tables et l'utilisateur admin)
echo "🔧 Installation de Listmonk..."
echo -e "y\nadmin\nadmin123" | ./listmonk --install --config config-simple.toml

# Ajouter les extensions géographiques
echo "🗺️  Ajout des extensions géographiques..."
docker-compose -f dev/docker-compose.yml exec -T db psql -U listmonk-dev -d listmonk-dev << 'EOF'
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
./listmonk --config config-simple.toml &
BACKEND_PID=$!

# Attendre que le backend démarre
sleep 10

# Vérifier que le backend répond
echo "🔍 Vérification du backend..."
if curl -s http://localhost:9000/api/health > /dev/null; then
    echo "✅ Backend accessible"
else
    echo "❌ Backend non accessible"
    kill $BACKEND_PID || true
    exit 1
fi

echo ""
echo "✅ APPLICATION LISTMONK DÉMARRÉE!"
echo "================================="
echo ""
echo "🌐 ACCÈS À L'APPLICATION :"
echo "   Interface : http://localhost:9000/admin"
echo "   API       : http://localhost:9000/api"
echo ""
echo "🔑 INFORMATIONS DE CONNEXION :"
echo "   Username : admin"
echo "   Password : admin123"
echo ""
echo "🎯 FONCTIONNALITÉS GÉOGRAPHIQUES DISPONIBLES :"
echo "   ✅ API géographique : /api/geo/*"
echo "   ✅ Sélecteur géographique dans la recherche"
echo "   ✅ Onglet géographique dans le formulaire d'abonné"
echo "   ✅ Base de données avec données françaises"
echo ""
echo "📋 TESTS À EFFECTUER :"
echo "   1. Aller sur http://localhost:9000/admin"
echo "   2. Se connecter avec admin / admin123"
echo "   3. Naviguer vers 'Abonnés'"
echo "   4. Tester le sélecteur géographique"
echo "   5. Créer un nouvel abonné"
echo "   6. Tester l'onglet 'Sélection géographique'"
echo ""
echo "📋 POUR ARRÊTER : Ctrl+C"
echo ""

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt de l'application..."
    kill $BACKEND_PID 2>/dev/null || true
    cd dev
    docker-compose down
    exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT

# Attendre
wait $BACKEND_PID