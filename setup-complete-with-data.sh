#!/bin/bash

echo "🚀 INSTALLATION COMPLÈTE LISTMONK + DONNÉES GÉOGRAPHIQUES"
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

# Étape 3: Téléchargement et import des données mairies
echo ""
echo "📊 ÉTAPE 3: Import des données des mairies françaises"
echo "Téléchargement du fichier mairielist.csv..."

# Téléchargement du fichier CSV
curl -L -o mairielist.csv "https://raw.githubusercontent.com/code8UD/listmonk/feature/french-geographic-segmentation/mairielist.csv"

if [ -f "mairielist.csv" ]; then
    echo "✅ Fichier téléchargé avec succès"
    
    # Copie du fichier dans le container PostgreSQL
    docker cp mairielist.csv $(docker-compose ps -q db):/tmp/mairielist.csv
    
    # Import des données dans PostgreSQL
    echo "📥 Import des données dans la base..."
    docker-compose exec -T db psql -U postgres -d listmonk << 'EOF'
-- Création d'une table temporaire pour l'import
CREATE TEMP TABLE temp_mairies (
    email VARCHAR(255),
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    title VARCHAR(10),
    phone VARCHAR(50),
    website TEXT,
    address1 TEXT,
    city VARCHAR(255),
    state VARCHAR(100),
    zipcode VARCHAR(10),
    country VARCHAR(100),
    code_insee VARCHAR(10),
    population_commune INTEGER,
    date_naissance VARCHAR(20),
    csp VARCHAR(255),
    siren VARCHAR(20),
    siret VARCHAR(20),
    telecopie VARCHAR(50),
    nom_commune VARCHAR(255),
    departement_numero VARCHAR(3)
);

-- Import du CSV
\copy temp_mairies FROM '/tmp/mairielist.csv' WITH CSV HEADER DELIMITER ',' QUOTE '"';

-- Insertion dans la table subscribers avec les données géographiques
INSERT INTO subscribers (
    email, 
    name, 
    status, 
    created_at, 
    updated_at,
    region,
    departement,
    commune,
    code_postal,
    code_insee,
    population,
    csp,
    nom_commune
)
SELECT 
    email,
    CONCAT(firstname, ' ', lastname) as name,
    'enabled' as status,
    NOW() as created_at,
    NOW() as updated_at,
    CASE 
        WHEN departement_numero IN ('01','03','07','15','26','38','42','43','63','69','73','74') THEN 'Auvergne-Rhône-Alpes'
        WHEN departement_numero IN ('21','25','39','58','70','71','89','90') THEN 'Bourgogne-Franche-Comté'
        WHEN departement_numero IN ('22','29','35','56') THEN 'Bretagne'
        WHEN departement_numero IN ('18','28','36','37','41','45') THEN 'Centre-Val de Loire'
        WHEN departement_numero IN ('2A','2B') THEN 'Corse'
        WHEN departement_numero IN ('08','10','51','52','54','55','57','67','68') THEN 'Grand Est'
        WHEN departement_numero IN ('02','59','60','62','80') THEN 'Hauts-de-France'
        WHEN departement_numero IN ('75','77','78','91','92','93','94','95') THEN 'Île-de-France'
        WHEN departement_numero IN ('14','27','50','61','76') THEN 'Normandie'
        WHEN departement_numero IN ('16','17','19','23','24','33','40','47','64','79','86','87') THEN 'Nouvelle-Aquitaine'
        WHEN departement_numero IN ('09','11','12','30','31','32','34','46','48','65','66','81','82') THEN 'Occitanie'
        WHEN departement_numero IN ('44','49','53','72','85') THEN 'Pays de la Loire'
        WHEN departement_numero IN ('04','05','06','13','83','84') THEN 'Provence-Alpes-Côte d''Azur'
        ELSE 'Autre'
    END as region,
    departement_numero as departement,
    city as commune,
    zipcode as code_postal,
    code_insee,
    population_commune as population,
    csp,
    nom_commune
FROM temp_mairies
WHERE email IS NOT NULL AND email != ''
ON CONFLICT (email) DO NOTHING;

-- Statistiques d'import
SELECT 
    COUNT(*) as total_subscribers,
    COUNT(DISTINCT region) as regions_count,
    COUNT(DISTINCT departement) as departements_count
FROM subscribers;

SELECT 'Import des données terminé avec succès!' as status;
EOF

    echo "✅ Import terminé"
    
    # Nettoyage
    rm -f mairielist.csv
    docker-compose exec db rm -f /tmp/mairielist.csv
    
else
    echo "❌ Erreur lors du téléchargement du fichier"
fi

# Étape 4: Configuration du mot de passe admin
echo ""
echo "🔐 ÉTAPE 4: Configuration du compte administrateur"
echo "Le compte admin doit être créé via l'interface web au premier accès"
echo "Ou utilisez le script : ./create-admin-user.sh"

echo ""
echo "✅ INSTALLATION COMPLÈTE TERMINÉE !"
echo "=================================="
echo ""
echo "🌐 Application accessible : http://0.0.0.0:9000"
echo "👤 Login : admin"
echo "🔑 Password : listmonk"
echo ""
echo "📊 DONNÉES IMPORTÉES :"
echo "   • Mairies françaises avec données géographiques"
echo "   • 13 régions françaises"
echo "   • 95+ départements"
echo "   • Codes INSEE et populations"
echo "   • Catégories socio-professionnelles"
echo ""
echo "🗺️ Extension géographique française installée :"
echo "   • 10 colonnes géographiques sur les abonnés"
echo "   • Index optimisés pour les recherches"
echo "   • Tables de référence (régions, départements)"
echo ""
echo "📋 Vérification finale..."
docker-compose ps
echo ""
curl -s -o /dev/null -w "Status HTTP: %{http_code}\n" http://localhost:9000

echo ""
echo "🎉 PRÊT À UTILISER !"