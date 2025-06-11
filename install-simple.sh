#!/bin/bash

# Installation simple de Listmonk avec extension géographique via JSON
set -e

echo "🗺️ INSTALLATION LISTMONK AVEC EXTENSION GÉOGRAPHIQUE"
echo "===================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Nettoyer l'installation précédente
print_status "Nettoyage de l'installation précédente..."
docker compose -f docker-compose.postgres-fixed.yml down -v 2>/dev/null || true

# Étape 1: Démarrer PostgreSQL
print_status "Étape 1: Démarrage de PostgreSQL..."
docker compose -f docker-compose.postgres-fixed.yml up -d postgres

# Attendre PostgreSQL
print_status "Attente de PostgreSQL..."
for i in {1..30}; do
    if docker compose -f docker-compose.postgres-fixed.yml exec postgres pg_isready -U listmonk -d listmonk &>/dev/null; then
        print_success "PostgreSQL est prêt"
        break
    fi
    
    if [ $i -eq 30 ]; then
        print_error "Timeout - PostgreSQL ne répond pas"
        exit 1
    fi
    
    echo -n "."
    sleep 2
done

# Étape 2: Installation Listmonk standard
print_status "Étape 2: Installation Listmonk standard..."

# Créer un fichier de configuration temporaire pour l'installation
cat > /tmp/listmonk-install-config.toml << EOF
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "admin123"

[db]
host = "postgres"
port = 5432
user = "listmonk"
password = "listmonk_secure_password"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"

[smtp]
[[smtp.host]]
enabled = false
host = "localhost"
port = 587
auth_protocol = "cram"
username = ""
password = ""
hello_hostname = ""
max_conns = 10
idle_timeout = "15s"
wait_timeout = "5s"
max_msg_retries = 2
tls_enabled = true
tls_skip_verify = false

[upload]
provider = "filesystem"
filesystem.upload_path = "uploads"
filesystem.upload_uri = "/uploads"

[privacy]
individual_tracking = false
unsubscribe_header = true
allow_blocklist = true
allow_export = true
allow_wipe = true
exportable = ["profile", "subscriptions", "campaign_views", "link_clicks"]

[media]
upload.provider = "filesystem"
upload.filesystem.upload_path = "uploads"
upload.filesystem.upload_uri = "/uploads"
EOF

# Utiliser l'image officielle de Listmonk pour l'installation
docker run --rm --network listmonk-geo_listmonk-network \
    -v /tmp/listmonk-install-config.toml:/listmonk/config.toml \
    listmonk/listmonk:latest \
    ./listmonk --install --yes

print_success "Installation Listmonk standard terminée"

# Étape 3: Charger les données géographiques françaises
print_status "Étape 3: Chargement des données géographiques françaises..."

# Créer les tables de référence géographique
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk << 'EOF'
-- Créer la table des départements français
CREATE TABLE IF NOT EXISTS departements_france (
    numero VARCHAR(3) PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    prefecture VARCHAR(100),
    population INTEGER,
    superficie DECIMAL(10,2)
);

-- Créer la table des communes françaises (échantillon)
CREATE TABLE IF NOT EXISTS communes_france (
    code_insee VARCHAR(10) PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    departement_numero VARCHAR(3) NOT NULL,
    departement_nom VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    population INTEGER,
    code_postal VARCHAR(10),
    FOREIGN KEY (departement_numero) REFERENCES departements_france(numero)
);

-- Insérer les données des départements français
INSERT INTO departements_france (numero, nom, region, prefecture, population, superficie) VALUES
('01', 'Ain', 'Auvergne-Rhône-Alpes', 'Bourg-en-Bresse', 652432, 5762.00),
('02', 'Aisne', 'Hauts-de-France', 'Laon', 531345, 7361.00),
('03', 'Allier', 'Auvergne-Rhône-Alpes', 'Moulins', 337988, 7340.00),
('04', 'Alpes-de-Haute-Provence', 'Provence-Alpes-Côte d''Azur', 'Digne-les-Bains', 164308, 6925.00),
('05', 'Hautes-Alpes', 'Provence-Alpes-Côte d''Azur', 'Gap', 141284, 5549.00),
('06', 'Alpes-Maritimes', 'Provence-Alpes-Côte d''Azur', 'Nice', 1083310, 4299.00),
('07', 'Ardèche', 'Auvergne-Rhône-Alpes', 'Privas', 328278, 5529.00),
('08', 'Ardennes', 'Grand Est', 'Charleville-Mézières', 269997, 5229.00),
('09', 'Ariège', 'Occitanie', 'Foix', 153287, 4890.00),
('10', 'Aube', 'Grand Est', 'Troyes', 310020, 6004.00),
('11', 'Aude', 'Occitanie', 'Carcassonne', 374070, 6139.00),
('12', 'Aveyron', 'Occitanie', 'Rodez', 279206, 8735.00),
('13', 'Bouches-du-Rhône', 'Provence-Alpes-Côte d''Azur', 'Marseille', 2043110, 5087.00),
('14', 'Calvados', 'Normandie', 'Caen', 694002, 5548.00),
('15', 'Cantal', 'Auvergne-Rhône-Alpes', 'Aurillac', 144692, 5726.00),
('16', 'Charente', 'Nouvelle-Aquitaine', 'Angoulême', 352015, 5956.00),
('17', 'Charente-Maritime', 'Nouvelle-Aquitaine', 'La Rochelle', 651358, 6864.00),
('18', 'Cher', 'Centre-Val de Loire', 'Bourges', 302306, 7235.00),
('19', 'Corrèze', 'Nouvelle-Aquitaine', 'Tulle', 240073, 5857.00),
('21', 'Côte-d''Or', 'Bourgogne-Franche-Comté', 'Dijon', 534124, 8763.00),
('22', 'Côtes-d''Armor', 'Bretagne', 'Saint-Brieuc', 598814, 6878.00),
('23', 'Creuse', 'Nouvelle-Aquitaine', 'Guéret', 116617, 5565.00),
('24', 'Dordogne', 'Nouvelle-Aquitaine', 'Périgueux', 412807, 9060.00),
('25', 'Doubs', 'Bourgogne-Franche-Comté', 'Besançon', 543974, 5234.00),
('26', 'Drôme', 'Auvergne-Rhône-Alpes', 'Valence', 516762, 6530.00),
('27', 'Eure', 'Normandie', 'Évreux', 599507, 6040.00),
('28', 'Eure-et-Loir', 'Centre-Val de Loire', 'Chartres', 431575, 5880.00),
('29', 'Finistère', 'Bretagne', 'Quimper', 915090, 6733.00),
('30', 'Gard', 'Occitanie', 'Nîmes', 748437, 5853.00),
('31', 'Haute-Garonne', 'Occitanie', 'Toulouse', 1400039, 6309.00),
('32', 'Gers', 'Occitanie', 'Auch', 191377, 6257.00),
('33', 'Gironde', 'Nouvelle-Aquitaine', 'Bordeaux', 1601845, 9976.00),
('34', 'Hérault', 'Occitanie', 'Montpellier', 1175623, 6101.00),
('35', 'Ille-et-Vilaine', 'Bretagne', 'Rennes', 1079498, 6775.00),
('36', 'Indre', 'Centre-Val de Loire', 'Châteauroux', 219316, 6791.00),
('37', 'Indre-et-Loire', 'Centre-Val de Loire', 'Tours', 610079, 6127.00),
('38', 'Isère', 'Auvergne-Rhône-Alpes', 'Grenoble', 1271166, 7431.00),
('39', 'Jura', 'Bourgogne-Franche-Comté', 'Lons-le-Saunier', 259199, 4999.00),
('40', 'Landes', 'Nouvelle-Aquitaine', 'Mont-de-Marsan', 413690, 9243.00),
('41', 'Loir-et-Cher', 'Centre-Val de Loire', 'Blois', 329470, 6343.00),
('42', 'Loire', 'Auvergne-Rhône-Alpes', 'Saint-Étienne', 765634, 4781.00),
('43', 'Haute-Loire', 'Auvergne-Rhône-Alpes', 'Le Puy-en-Velay', 227339, 4977.00),
('44', 'Loire-Atlantique', 'Pays de la Loire', 'Nantes', 1429272, 6815.00),
('45', 'Loiret', 'Centre-Val de Loire', 'Orléans', 680434, 6775.00),
('46', 'Lot', 'Occitanie', 'Cahors', 174754, 5217.00),
('47', 'Lot-et-Garonne', 'Nouvelle-Aquitaine', 'Agen', 332833, 5361.00),
('48', 'Lozère', 'Occitanie', 'Mende', 76422, 5167.00),
('49', 'Maine-et-Loire', 'Pays de la Loire', 'Angers', 818273, 7166.00),
('50', 'Manche', 'Normandie', 'Saint-Lô', 495045, 5938.00),
('51', 'Marne', 'Grand Est', 'Châlons-en-Champagne', 566145, 8162.00),
('52', 'Haute-Marne', 'Grand Est', 'Chaumont', 172512, 6211.00),
('53', 'Mayenne', 'Pays de la Loire', 'Laval', 307445, 5175.00),
('54', 'Meurthe-et-Moselle', 'Grand Est', 'Nancy', 733481, 5246.00),
('55', 'Meuse', 'Grand Est', 'Bar-le-Duc', 184083, 6211.00),
('56', 'Morbihan', 'Bretagne', 'Vannes', 750863, 6823.00),
('57', 'Moselle', 'Grand Est', 'Metz', 1043522, 6216.00),
('58', 'Nièvre', 'Bourgogne-Franche-Comté', 'Nevers', 204452, 6817.00),
('59', 'Nord', 'Hauts-de-France', 'Lille', 2604361, 5743.00),
('60', 'Oise', 'Hauts-de-France', 'Beauvais', 829419, 5860.00),
('61', 'Orne', 'Normandie', 'Alençon', 279942, 6103.00),
('62', 'Pas-de-Calais', 'Hauts-de-France', 'Arras', 1465278, 6671.00),
('63', 'Puy-de-Dôme', 'Auvergne-Rhône-Alpes', 'Clermont-Ferrand', 658182, 7970.00),
('64', 'Pyrénées-Atlantiques', 'Nouvelle-Aquitaine', 'Pau', 682621, 7645.00),
('65', 'Hautes-Pyrénées', 'Occitanie', 'Tarbes', 229228, 4464.00),
('66', 'Pyrénées-Orientales', 'Occitanie', 'Perpignan', 479979, 4116.00),
('67', 'Bas-Rhin', 'Grand Est', 'Strasbourg', 1125559, 4755.00),
('68', 'Haut-Rhin', 'Grand Est', 'Colmar', 764030, 3525.00),
('69', 'Rhône', 'Auvergne-Rhône-Alpes', 'Lyon', 1876351, 2715.00),
('70', 'Haute-Saône', 'Bourgogne-Franche-Comté', 'Vesoul', 235313, 5360.00),
('71', 'Saône-et-Loire', 'Bourgogne-Franche-Comté', 'Mâcon', 551493, 8575.00),
('72', 'Sarthe', 'Pays de la Loire', 'Le Mans', 566506, 6206.00),
('73', 'Savoie', 'Auvergne-Rhône-Alpes', 'Chambéry', 433724, 6028.00),
('74', 'Haute-Savoie', 'Auvergne-Rhône-Alpes', 'Annecy', 825987, 4388.00),
('75', 'Paris', 'Île-de-France', 'Paris', 2161063, 105.00),
('76', 'Seine-Maritime', 'Normandie', 'Rouen', 1254378, 6278.00),
('77', 'Seine-et-Marne', 'Île-de-France', 'Melun', 1421197, 5915.00),
('78', 'Yvelines', 'Île-de-France', 'Versailles', 1448394, 2284.00),
('79', 'Deux-Sèvres', 'Nouvelle-Aquitaine', 'Niort', 374878, 5999.00),
('80', 'Somme', 'Hauts-de-France', 'Amiens', 570559, 6170.00),
('81', 'Tarn', 'Occitanie', 'Albi', 387890, 5758.00),
('82', 'Tarn-et-Garonne', 'Occitanie', 'Montauban', 260400, 3718.00),
('83', 'Var', 'Provence-Alpes-Côte d''Azur', 'Toulon', 1076711, 5973.00),
('84', 'Vaucluse', 'Provence-Alpes-Côte d''Azur', 'Avignon', 559479, 3567.00),
('85', 'Vendée', 'Pays de la Loire', 'La Roche-sur-Yon', 685442, 6720.00),
('86', 'Vienne', 'Nouvelle-Aquitaine', 'Poitiers', 438435, 6990.00),
('87', 'Haute-Vienne', 'Nouvelle-Aquitaine', 'Limoges', 374426, 5520.00),
('88', 'Vosges', 'Grand Est', 'Épinal', 364499, 5874.00),
('89', 'Yonne', 'Bourgogne-Franche-Comté', 'Auxerre', 338291, 7427.00),
('90', 'Territoire de Belfort', 'Bourgogne-Franche-Comté', 'Belfort', 140120, 609.00),
('91', 'Essonne', 'Île-de-France', 'Évry-Courcouronnes', 1301659, 1804.00),
('92', 'Hauts-de-Seine', 'Île-de-France', 'Nanterre', 1609306, 176.00),
('93', 'Seine-Saint-Denis', 'Île-de-France', 'Bobigny', 1644518, 236.00),
('94', 'Val-de-Marne', 'Île-de-France', 'Créteil', 1387926, 245.00),
('95', 'Val-d''Oise', 'Île-de-France', 'Cergy', 1249755, 1246.00)
ON CONFLICT (numero) DO NOTHING;

-- Insérer quelques communes d'exemple
INSERT INTO communes_france (code_insee, nom, departement_numero, departement_nom, region, population, code_postal) VALUES
('75056', 'Paris', '75', 'Paris', 'Île-de-France', 2161063, '75001'),
('69123', 'Lyon', '69', 'Rhône', 'Auvergne-Rhône-Alpes', 518635, '69001'),
('13055', 'Marseille', '13', 'Bouches-du-Rhône', 'Provence-Alpes-Côte d''Azur', 870731, '13001'),
('31555', 'Toulouse', '31', 'Haute-Garonne', 'Occitanie', 486828, '31000'),
('06088', 'Nice', '06', 'Alpes-Maritimes', 'Provence-Alpes-Côte d''Azur', 342637, '06000'),
('44109', 'Nantes', '44', 'Loire-Atlantique', 'Pays de la Loire', 320732, '44000'),
('67482', 'Strasbourg', '67', 'Bas-Rhin', 'Grand Est', 290576, '67000'),
('34172', 'Montpellier', '34', 'Hérault', 'Occitanie', 295542, '34000'),
('33063', 'Bordeaux', '33', 'Gironde', 'Nouvelle-Aquitaine', 257068, '33000'),
('59350', 'Lille', '59', 'Nord', 'Hauts-de-France', 236710, '59000')
ON CONFLICT (code_insee) DO NOTHING;

-- Créer des index pour les performances
CREATE INDEX IF NOT EXISTS idx_departements_region ON departements_france(region);
CREATE INDEX IF NOT EXISTS idx_communes_departement ON communes_france(departement_numero);
CREATE INDEX IF NOT EXISTS idx_communes_region ON communes_france(region);
CREATE INDEX IF NOT EXISTS idx_communes_nom ON communes_france(nom);
CREATE INDEX IF NOT EXISTS idx_communes_code_postal ON communes_france(code_postal);

EOF

print_success "Données géographiques françaises chargées"

# Étape 4: Démarrer Listmonk standard
print_status "Étape 4: Démarrage de Listmonk..."

# Créer les volumes nécessaires
docker volume create listmonk_listmonk_uploads 2>/dev/null || true
docker volume create listmonk_listmonk_static 2>/dev/null || true

# Démarrer Listmonk avec l'image officielle directement
docker run -d \
  --name listmonk-app \
  --network listmonk-geo_listmonk-network \
  -p 9000:9000 \
  -v listmonk_listmonk_uploads:/listmonk/uploads \
  -v listmonk_listmonk_static:/listmonk/static \
  -v /tmp/listmonk-install-config.toml:/listmonk/config.toml \
  --restart unless-stopped \
  listmonk/listmonk:latest

print_status "Attente du démarrage de Listmonk..."
sleep 15

# Vérifier que Listmonk fonctionne
if curl -f http://localhost:9000/health &>/dev/null; then
    print_success "Listmonk est accessible sur http://localhost:9000"
else
    print_warning "Listmonk n'est pas encore accessible (peut nécessiter quelques minutes)"
fi

# Étape 5: Créer des exemples d'abonnés avec données géographiques
print_status "Étape 5: Création d'exemples d'abonnés avec données géographiques..."

# Attendre que Listmonk soit complètement démarré
sleep 10

# Créer des abonnés d'exemple avec des attributs géographiques
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk << 'EOF'
-- Insérer des abonnés d'exemple avec des attributs géographiques JSON
INSERT INTO subscribers (uuid, email, name, attribs, status) VALUES
(gen_random_uuid(), 'jean.dupont@example.com', 'Jean Dupont', 
 '{"geo": {"departement": "75", "departement_nom": "Paris", "region": "Île-de-France", "commune": "Paris", "code_insee": "75056", "code_postal": "75001"}, "csp": "Cadre", "age": 35}', 
 'enabled'),
(gen_random_uuid(), 'marie.martin@example.com', 'Marie Martin', 
 '{"geo": {"departement": "69", "departement_nom": "Rhône", "region": "Auvergne-Rhône-Alpes", "commune": "Lyon", "code_insee": "69123", "code_postal": "69001"}, "csp": "Employé", "age": 28}', 
 'enabled'),
(gen_random_uuid(), 'pierre.bernard@example.com', 'Pierre Bernard', 
 '{"geo": {"departement": "13", "departement_nom": "Bouches-du-Rhône", "region": "Provence-Alpes-Côte d''Azur", "commune": "Marseille", "code_insee": "13055", "code_postal": "13001"}, "csp": "Ouvrier", "age": 42}', 
 'enabled'),
(gen_random_uuid(), 'sophie.dubois@example.com', 'Sophie Dubois', 
 '{"geo": {"departement": "31", "departement_nom": "Haute-Garonne", "region": "Occitanie", "commune": "Toulouse", "code_insee": "31555", "code_postal": "31000"}, "csp": "Profession libérale", "age": 39}', 
 'enabled'),
(gen_random_uuid(), 'antoine.moreau@example.com', 'Antoine Moreau', 
 '{"geo": {"departement": "44", "departement_nom": "Loire-Atlantique", "region": "Pays de la Loire", "commune": "Nantes", "code_insee": "44109", "code_postal": "44000"}, "csp": "Artisan", "age": 33}', 
 'enabled')
ON CONFLICT (email) DO NOTHING;
EOF

print_success "Abonnés d'exemple créés avec données géographiques"

# Étape 6: Ajouter les colonnes géographiques pour compatibilité interface Listmonk
print_status "Étape 6: Configuration des colonnes géographiques pour interface Listmonk..."

docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk << 'EOF'
-- Ajouter des colonnes géographiques réelles à la table subscribers
ALTER TABLE subscribers 
ADD COLUMN IF NOT EXISTS region VARCHAR(100),
ADD COLUMN IF NOT EXISTS departement_numero VARCHAR(3),
ADD COLUMN IF NOT EXISTS departement_nom VARCHAR(100),
ADD COLUMN IF NOT EXISTS commune VARCHAR(100),
ADD COLUMN IF NOT EXISTS code_insee VARCHAR(10),
ADD COLUMN IF NOT EXISTS code_postal VARCHAR(10),
ADD COLUMN IF NOT EXISTS csp VARCHAR(50),
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Migrer les données JSON vers les colonnes réelles
UPDATE subscribers 
SET 
    region = attribs->'geo'->>'region',
    departement_numero = attribs->'geo'->>'departement',
    departement_nom = attribs->'geo'->>'departement_nom',
    commune = attribs->'geo'->>'commune',
    code_insee = attribs->'geo'->>'code_insee',
    code_postal = attribs->'geo'->>'code_postal',
    csp = attribs->>'csp',
    age = CASE 
        WHEN attribs->>'age' ~ '^[0-9]+$' 
        THEN (attribs->>'age')::integer 
        ELSE NULL 
    END
WHERE attribs ? 'geo';

-- Créer des index pour les performances
CREATE INDEX IF NOT EXISTS idx_subscribers_region ON subscribers(region);
CREATE INDEX IF NOT EXISTS idx_subscribers_departement ON subscribers(departement_numero);
CREATE INDEX IF NOT EXISTS idx_subscribers_commune ON subscribers(commune);
CREATE INDEX IF NOT EXISTS idx_subscribers_csp ON subscribers(csp);
CREATE INDEX IF NOT EXISTS idx_subscribers_code_postal ON subscribers(code_postal);

-- Créer des vues simplifiées pour les requêtes fréquentes
CREATE OR REPLACE VIEW abonnes_ile_de_france AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE region = 'Île-de-France' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_paca AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE region = 'Provence-Alpes-Côte d''Azur' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_occitanie AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE region = 'Occitanie' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_auvergne_rhone_alpes AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE region = 'Auvergne-Rhône-Alpes' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_pays_de_la_loire AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE region = 'Pays de la Loire' AND status = 'enabled';

-- Créer des vues par CSP
CREATE OR REPLACE VIEW abonnes_cadres AS
SELECT id, email, name, region, commune, age, status
FROM subscribers 
WHERE csp = 'Cadre' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_employes AS
SELECT id, email, name, region, commune, age, status
FROM subscribers 
WHERE csp = 'Employé' AND status = 'enabled';

-- Créer des vues par département populaire
CREATE OR REPLACE VIEW abonnes_paris AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE departement_numero = '75' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_rhone AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE departement_numero = '69' AND status = 'enabled';

CREATE OR REPLACE VIEW abonnes_bouches_du_rhone AS
SELECT id, email, name, commune, csp, age, status
FROM subscribers 
WHERE departement_numero = '13' AND status = 'enabled';

-- Créer des vues par seuil de population départementale
CREATE OR REPLACE VIEW abonnes_grandes_metropoles AS
SELECT s.id, s.email, s.name, s.region, s.commune, s.csp, s.age, s.status, df.population as pop_dept
FROM subscribers s
JOIN departements_france df ON s.departement_numero = df.numero
WHERE df.population > 1000000 AND s.status = 'enabled';

CREATE OR REPLACE VIEW abonnes_departements_moyens AS
SELECT s.id, s.email, s.name, s.region, s.commune, s.csp, s.age, s.status, df.population as pop_dept
FROM subscribers s
JOIN departements_france df ON s.departement_numero = df.numero
WHERE df.population BETWEEN 500000 AND 1000000 AND s.status = 'enabled';

CREATE OR REPLACE VIEW abonnes_petits_departements AS
SELECT s.id, s.email, s.name, s.region, s.commune, s.csp, s.age, s.status, df.population as pop_dept
FROM subscribers s
JOIN departements_france df ON s.departement_numero = df.numero
WHERE df.population < 500000 AND s.status = 'enabled';

-- Statistiques utiles
CREATE OR REPLACE VIEW stats_geographiques AS
SELECT 
    'Total abonnés' as categorie,
    COUNT(*) as nombre
FROM subscribers
WHERE status = 'enabled'
UNION ALL
SELECT 
    'Avec données géographiques' as categorie,
    COUNT(*) as nombre
FROM subscribers
WHERE region IS NOT NULL AND status = 'enabled'
UNION ALL
SELECT 
    CONCAT('Région: ', region) as categorie,
    COUNT(*) as nombre
FROM subscribers
WHERE region IS NOT NULL AND status = 'enabled'
GROUP BY region
UNION ALL
SELECT 
    CONCAT('CSP: ', csp) as categorie,
    COUNT(*) as nombre
FROM subscribers
WHERE csp IS NOT NULL AND status = 'enabled'
GROUP BY csp
ORDER BY nombre DESC;
EOF

print_success "Colonnes géographiques configurées pour interface Listmonk"

echo ""
echo "🎉 INSTALLATION TERMINÉE !"
echo "========================="
echo ""
echo "✅ Listmonk avec extension géographique française est installé"
echo ""
echo "📋 INFORMATIONS D'ACCÈS :"
echo "🌐 Interface Listmonk : http://localhost:9000"
echo "👤 Nom d'utilisateur  : admin"
echo "🔑 Mot de passe       : admin123"
echo ""
echo "🗄️ Interface Adminer : http://localhost:8080"
echo "   Serveur    : postgres"
echo "   Utilisateur: listmonk"
echo "   Mot de passe: listmonk_secure_password"
echo "   Base       : listmonk"
echo ""
echo "🗺️ FONCTIONNALITÉS GÉOGRAPHIQUES :"
echo "   • 95 départements français disponibles"
echo "   • 13 régions françaises"
echo "   • Données stockées dans le champ 'attribs' JSON"
echo "   • Exemples d'abonnés créés avec données géographiques"
echo ""
echo "📊 UTILISATION :"
echo "   • Filtres simples compatibles interface Listmonk :"
echo "   • region = 'Île-de-France'"
echo "   • departement_numero = '75'"
echo "   • commune = 'Paris'"
echo "   • csp = 'Cadre'"
echo "   • age < 40"
echo "   • Ou utilisez les vues prédéfinies :"
echo "   • SELECT * FROM abonnes_ile_de_france"
echo "   • SELECT * FROM abonnes_cadres"
echo ""
echo "🚀 Bon marketing géographique avec Listmonk !"