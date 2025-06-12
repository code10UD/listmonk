-- Vérifier que la table departement_region_mapping existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departement_region_mapping') 
        THEN 'Table departement_region_mapping: ✅ EXISTE'
        ELSE 'Table departement_region_mapping: ❌ MANQUANTE'
    END as status;

-- Vérifier les colonnes géographiques dans subscribers
SELECT 
    column_name,
    data_type,
    CASE WHEN column_name IN ('code_insee', 'population_commune', 'date_naissance', 'csp', 'nom_commune', 'departement_numero') 
         THEN '✅ REQUIS' 
         ELSE '📋 OPTIONNEL' 
    END as importance
FROM information_schema.columns 
WHERE table_name = 'subscribers' 
  AND column_name IN ('code_insee', 'population_commune', 'date_naissance', 'csp', 'siren', 'siret', 'telecopie', 'nom_commune', 'departement_numero', 'phone', 'website', 'address1', 'city', 'state', 'zipcode', 'country', 'title')
ORDER BY importance DESC, column_name;
