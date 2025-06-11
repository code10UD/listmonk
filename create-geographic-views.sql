-- Créer des vues simplifiées pour faciliter les requêtes géographiques dans Listmonk
-- Ces vues permettent d'utiliser des requêtes SQL simples au lieu de JSON

-- Vue pour les abonnés avec données géographiques extraites
CREATE OR REPLACE VIEW subscribers_geo AS
SELECT 
    s.id,
    s.uuid,
    s.email,
    s.name,
    s.status,
    s.created_at,
    s.updated_at,
    s.attribs,
    -- Extraction des données géographiques du JSON
    s.attribs->>'geo'->>'region' as region,
    s.attribs->>'geo'->>'departement' as departement_numero,
    s.attribs->>'geo'->>'departement_nom' as departement_nom,
    s.attribs->>'geo'->>'commune' as commune,
    s.attribs->>'geo'->>'code_insee' as code_insee,
    s.attribs->>'geo'->>'code_postal' as code_postal,
    s.attribs->>'csp' as csp,
    CASE 
        WHEN s.attribs->>'age' ~ '^[0-9]+$' 
        THEN (s.attribs->>'age')::integer 
        ELSE NULL 
    END as age
FROM subscribers s
WHERE s.attribs ? 'geo';

-- Vue pour les statistiques par région
CREATE OR REPLACE VIEW stats_par_region AS
SELECT 
    region,
    COUNT(*) as nb_abonnes,
    COUNT(CASE WHEN status = 'enabled' THEN 1 END) as nb_actifs,
    COUNT(CASE WHEN csp IS NOT NULL THEN 1 END) as nb_avec_csp
FROM subscribers_geo
GROUP BY region
ORDER BY nb_abonnes DESC;

-- Vue pour les statistiques par département
CREATE OR REPLACE VIEW stats_par_departement AS
SELECT 
    departement_numero,
    departement_nom,
    region,
    COUNT(*) as nb_abonnes,
    COUNT(CASE WHEN status = 'enabled' THEN 1 END) as nb_actifs
FROM subscribers_geo
GROUP BY departement_numero, departement_nom, region
ORDER BY nb_abonnes DESC;

-- Vue pour les abonnés par CSP
CREATE OR REPLACE VIEW stats_par_csp AS
SELECT 
    csp,
    COUNT(*) as nb_abonnes,
    COUNT(CASE WHEN status = 'enabled' THEN 1 END) as nb_actifs
FROM subscribers_geo
WHERE csp IS NOT NULL
GROUP BY csp
ORDER BY nb_abonnes DESC;

-- Vue combinée avec informations démographiques des départements
CREATE OR REPLACE VIEW subscribers_geo_enriched AS
SELECT 
    sg.*,
    df.population as population_departement,
    df.superficie as superficie_departement,
    df.prefecture
FROM subscribers_geo sg
LEFT JOIN departements_france df ON sg.departement_numero = df.numero;

-- Créer des fonctions pour faciliter les requêtes
CREATE OR REPLACE FUNCTION get_subscribers_by_region(region_name TEXT)
RETURNS TABLE(id INTEGER, email TEXT, name TEXT, status subscriber_status) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.email, s.name, s.status
    FROM subscribers_geo s
    WHERE s.region = region_name AND s.status = 'enabled';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_subscribers_by_departement(dept_numero TEXT)
RETURNS TABLE(id INTEGER, email TEXT, name TEXT, status subscriber_status) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.email, s.name, s.status
    FROM subscribers_geo s
    WHERE s.departement_numero = dept_numero AND s.status = 'enabled';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_subscribers_by_population_limit(min_population INTEGER)
RETURNS TABLE(id INTEGER, email TEXT, name TEXT, departement_nom TEXT, population INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.email, s.name, s.departement_nom, df.population
    FROM subscribers_geo s
    JOIN departements_france df ON s.departement_numero = df.numero
    WHERE df.population >= min_population AND s.status = 'enabled';
END;
$$ LANGUAGE plpgsql;

-- Créer des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_subscribers_geo_region ON subscribers USING GIN ((attribs->'geo'->>'region'));
CREATE INDEX IF NOT EXISTS idx_subscribers_geo_departement ON subscribers USING GIN ((attribs->'geo'->>'departement'));
CREATE INDEX IF NOT EXISTS idx_subscribers_csp ON subscribers USING GIN ((attribs->>'csp'));

-- Insérer des données d'exemple pour tester les vues
COMMENT ON VIEW subscribers_geo IS 'Vue simplifiée des abonnés avec données géographiques extraites du JSON';
COMMENT ON VIEW stats_par_region IS 'Statistiques des abonnés par région française';
COMMENT ON VIEW stats_par_departement IS 'Statistiques des abonnés par département français';
COMMENT ON VIEW subscribers_geo_enriched IS 'Abonnés avec données démographiques des départements';