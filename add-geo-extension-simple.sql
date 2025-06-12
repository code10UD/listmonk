-- Extension géographique française pour Listmonk
-- À exécuter après l'installation de base

-- Ajout des colonnes géographiques
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS region VARCHAR(100);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS departement VARCHAR(100);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS commune VARCHAR(255);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS code_postal VARCHAR(10);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS code_insee VARCHAR(10);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS population INTEGER;
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS csp VARCHAR(100);
ALTER TABLE subscribers ADD COLUMN IF NOT EXISTS nom_commune VARCHAR(255);

-- Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_subscribers_region ON subscribers(region);
CREATE INDEX IF NOT EXISTS idx_subscribers_departement ON subscribers(departement);
CREATE INDEX IF NOT EXISTS idx_subscribers_commune ON subscribers(commune);
CREATE INDEX IF NOT EXISTS idx_subscribers_code_postal ON subscribers(code_postal);
CREATE INDEX IF NOT EXISTS idx_subscribers_code_insee ON subscribers(code_insee);
CREATE INDEX IF NOT EXISTS idx_subscribers_population ON subscribers(population);
CREATE INDEX IF NOT EXISTS idx_subscribers_csp ON subscribers(csp);
CREATE INDEX IF NOT EXISTS idx_subscribers_nom_commune ON subscribers(nom_commune);

-- Table des régions françaises
CREATE TABLE IF NOT EXISTS regions_france (
    id SERIAL PRIMARY KEY,
    code VARCHAR(2) UNIQUE NOT NULL,
    nom VARCHAR(100) NOT NULL
);

-- Insertion des 13 régions françaises
INSERT INTO regions_france (code, nom) VALUES
('01', 'Auvergne-Rhône-Alpes'),
('02', 'Bourgogne-Franche-Comté'),
('03', 'Bretagne'),
('04', 'Centre-Val de Loire'),
('05', 'Corse'),
('06', 'Grand Est'),
('07', 'Hauts-de-France'),
('08', 'Île-de-France'),
('09', 'Normandie'),
('10', 'Nouvelle-Aquitaine'),
('11', 'Occitanie'),
('12', 'Pays de la Loire'),
('13', 'Provence-Alpes-Côte d''Azur')
ON CONFLICT (code) DO NOTHING;

-- Table des départements français
CREATE TABLE IF NOT EXISTS departements_france (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) UNIQUE NOT NULL,
    nom VARCHAR(100) NOT NULL,
    region_code VARCHAR(2) REFERENCES regions_france(code)
);

-- Insertion de quelques départements principaux
INSERT INTO departements_france (code, nom, region_code) VALUES
('01', 'Ain', '01'),
('02', 'Aisne', '07'),
('03', 'Allier', '01'),
('04', 'Alpes-de-Haute-Provence', '13'),
('05', 'Hautes-Alpes', '13'),
('06', 'Alpes-Maritimes', '13'),
('07', 'Ardèche', '01'),
('08', 'Ardennes', '06'),
('09', 'Ariège', '11'),
('10', 'Aube', '06'),
('11', 'Aude', '11'),
('12', 'Aveyron', '11'),
('13', 'Bouches-du-Rhône', '13'),
('14', 'Calvados', '09'),
('15', 'Cantal', '01'),
('16', 'Charente', '10'),
('17', 'Charente-Maritime', '10'),
('18', 'Cher', '04'),
('19', 'Corrèze', '10'),
('21', 'Côte-d''Or', '02'),
('22', 'Côtes-d''Armor', '03'),
('23', 'Creuse', '10'),
('24', 'Dordogne', '10'),
('25', 'Doubs', '02'),
('26', 'Drôme', '01'),
('27', 'Eure', '09'),
('28', 'Eure-et-Loir', '04'),
('29', 'Finistère', '03'),
('30', 'Gard', '11'),
('31', 'Haute-Garonne', '11'),
('32', 'Gers', '11'),
('33', 'Gironde', '10'),
('34', 'Hérault', '11'),
('35', 'Ille-et-Vilaine', '03'),
('36', 'Indre', '04'),
('37', 'Indre-et-Loire', '04'),
('38', 'Isère', '01'),
('39', 'Jura', '02'),
('40', 'Landes', '10'),
('41', 'Loir-et-Cher', '04'),
('42', 'Loire', '01'),
('43', 'Haute-Loire', '01'),
('44', 'Loire-Atlantique', '12'),
('45', 'Loiret', '04'),
('46', 'Lot', '11'),
('47', 'Lot-et-Garonne', '10'),
('48', 'Lozère', '11'),
('49', 'Maine-et-Loire', '12'),
('50', 'Manche', '09'),
('51', 'Marne', '06'),
('52', 'Haute-Marne', '06'),
('53', 'Mayenne', '12'),
('54', 'Meurthe-et-Moselle', '06'),
('55', 'Meuse', '06'),
('56', 'Morbihan', '03'),
('57', 'Moselle', '06'),
('58', 'Nièvre', '02'),
('59', 'Nord', '07'),
('60', 'Oise', '07'),
('61', 'Orne', '09'),
('62', 'Pas-de-Calais', '07'),
('63', 'Puy-de-Dôme', '01'),
('64', 'Pyrénées-Atlantiques', '10'),
('65', 'Hautes-Pyrénées', '11'),
('66', 'Pyrénées-Orientales', '11'),
('67', 'Bas-Rhin', '06'),
('68', 'Haut-Rhin', '06'),
('69', 'Rhône', '01'),
('70', 'Haute-Saône', '02'),
('71', 'Saône-et-Loire', '02'),
('72', 'Sarthe', '12'),
('73', 'Savoie', '01'),
('74', 'Haute-Savoie', '01'),
('75', 'Paris', '08'),
('76', 'Seine-Maritime', '09'),
('77', 'Seine-et-Marne', '08'),
('78', 'Yvelines', '08'),
('79', 'Deux-Sèvres', '10'),
('80', 'Somme', '07'),
('81', 'Tarn', '11'),
('82', 'Tarn-et-Garonne', '11'),
('83', 'Var', '13'),
('84', 'Vaucluse', '13'),
('85', 'Vendée', '12'),
('86', 'Vienne', '10'),
('87', 'Haute-Vienne', '10'),
('88', 'Vosges', '06'),
('89', 'Yonne', '02'),
('90', 'Territoire de Belfort', '02'),
('91', 'Essonne', '08'),
('92', 'Hauts-de-Seine', '08'),
('93', 'Seine-Saint-Denis', '08'),
('94', 'Val-de-Marne', '08'),
('95', 'Val-d''Oise', '08')
ON CONFLICT (code) DO NOTHING;

SELECT 'Extension géographique française installée avec succès!' as status;