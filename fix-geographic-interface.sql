-- Solution simplifiée : Ajouter des colonnes réelles pour faciliter les requêtes
-- Cela évite les problèmes avec les opérateurs JSON dans l'interface Listmonk

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