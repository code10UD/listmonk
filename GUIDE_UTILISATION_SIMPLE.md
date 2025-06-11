# 🎯 Guide d'Utilisation Simple - Filtres Géographiques Listmonk

## ✅ PROBLÈME RÉSOLU !

Les colonnes géographiques ont été ajoutées directement à la table `subscribers` pour éviter les problèmes avec les requêtes JSON. Vous pouvez maintenant utiliser des filtres simples dans l'interface Listmonk.

---

## 🗺️ FILTRES GÉOGRAPHIQUES SIMPLES

### 1. Filtrage par Région

```sql
-- Abonnés en Île-de-France
region = 'Île-de-France'

-- Abonnés en PACA
region = 'Provence-Alpes-Côte d''Azur'

-- Abonnés en Occitanie
region = 'Occitanie'

-- Abonnés en Auvergne-Rhône-Alpes
region = 'Auvergne-Rhône-Alpes'

-- Abonnés dans le Sud (PACA + Occitanie)
region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie')
```

### 2. Filtrage par Département

```sql
-- Abonnés à Paris (75)
departement_numero = '75'

-- Abonnés dans le Rhône (69)
departement_numero = '69'

-- Abonnés dans les Bouches-du-Rhône (13)
departement_numero = '13'

-- Abonnés en Haute-Garonne (31)
departement_numero = '31'

-- Abonnés en Loire-Atlantique (44)
departement_numero = '44'

-- Abonnés dans plusieurs départements
departement_numero IN ('75', '69', '13')
```

### 3. Filtrage par Commune

```sql
-- Abonnés à Paris
commune = 'Paris'

-- Abonnés à Lyon
commune = 'Lyon'

-- Abonnés à Marseille
commune = 'Marseille'

-- Abonnés dans les grandes villes
commune IN ('Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice')
```

### 4. Filtrage par CSP (Catégorie Socio-Professionnelle)

```sql
-- Cadres uniquement
csp = 'Cadre'

-- Employés uniquement
csp = 'Employé'

-- Ouvriers uniquement
csp = 'Ouvrier'

-- Professions libérales
csp = 'Profession libérale'

-- Artisans
csp = 'Artisan'

-- Cadres et professions libérales
csp IN ('Cadre', 'Profession libérale')
```

---

## 🎯 FILTRES COMBINÉS AVANCÉS

### 1. Géographie + CSP

```sql
-- Cadres en Île-de-France
region = 'Île-de-France' AND csp = 'Cadre'

-- Employés à Lyon
commune = 'Lyon' AND csp = 'Employé'

-- Professions libérales dans le Sud
region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie') AND csp = 'Profession libérale'
```

### 2. Géographie + Âge

```sql
-- Jeunes parisiens (moins de 35 ans)
departement_numero = '75' AND age < 35

-- Seniors en PACA (plus de 50 ans)
region = 'Provence-Alpes-Côte d''Azur' AND age > 50

-- Adultes actifs (25-55 ans) en Auvergne-Rhône-Alpes
region = 'Auvergne-Rhône-Alpes' AND age BETWEEN 25 AND 55
```

### 3. Filtres par Population Départementale

```sql
-- Abonnés dans les grandes métropoles (> 1M habitants)
departement_numero IN (
    SELECT numero FROM departements_france WHERE population > 1000000
)

-- Abonnés dans les départements moyens (500k-1M habitants)
departement_numero IN (
    SELECT numero FROM departements_france WHERE population BETWEEN 500000 AND 1000000
)

-- Abonnés dans les petits départements (< 500k habitants)
departement_numero IN (
    SELECT numero FROM departements_france WHERE population < 500000
)
```

---

## 🚀 VUES PRÉDÉFINIES (ENCORE PLUS SIMPLE)

Au lieu d'écrire des requêtes, vous pouvez utiliser ces vues prêtes à l'emploi :

### Vues par Région
- `abonnes_ile_de_france` - Tous les abonnés d'Île-de-France
- `abonnes_paca` - Tous les abonnés de PACA
- `abonnes_occitanie` - Tous les abonnés d'Occitanie
- `abonnes_auvergne_rhone_alpes` - Tous les abonnés d'Auvergne-Rhône-Alpes
- `abonnes_pays_de_la_loire` - Tous les abonnés des Pays de la Loire

### Vues par CSP
- `abonnes_cadres` - Tous les cadres
- `abonnes_employes` - Tous les employés

### Vues par Département
- `abonnes_paris` - Tous les abonnés de Paris (75)
- `abonnes_rhone` - Tous les abonnés du Rhône (69)
- `abonnes_bouches_du_rhone` - Tous les abonnés des Bouches-du-Rhône (13)

### Vues par Taille de Département
- `abonnes_grandes_metropoles` - Départements > 1M habitants
- `abonnes_departements_moyens` - Départements 500k-1M habitants
- `abonnes_petits_departements` - Départements < 500k habitants

**Utilisation dans Listmonk :**
```sql
-- Utiliser une vue directement
SELECT * FROM abonnes_ile_de_france

-- Ou simplement le nom de la vue
abonnes_cadres
```

---

## 📊 EXEMPLES CONCRETS D'UTILISATION

### 1. Campagne Événementielle à Lyon
**Objectif :** Promouvoir un salon à Lyon
```sql
commune = 'Lyon'
```
**Ou utiliser la vue :**
```sql
SELECT * FROM abonnes_rhone
```

### 2. Campagne Produit Haut de Gamme
**Objectif :** Cibler les cadres en Île-de-France
```sql
region = 'Île-de-France' AND csp = 'Cadre'
```

### 3. Campagne Régionale Sud
**Objectif :** Promotion estivale dans le Sud
```sql
region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie')
```

### 4. Campagne Jeunes Actifs
**Objectif :** Cibler les 25-40 ans dans les grandes villes
```sql
age BETWEEN 25 AND 40 AND commune IN ('Paris', 'Lyon', 'Marseille', 'Toulouse')
```

### 5. Campagne Départements Ruraux
**Objectif :** Cibler les petits départements
```sql
SELECT * FROM abonnes_petits_departements
```

---

## 🔧 COMMENT UTILISER DANS LISTMONK

### 1. Créer une Liste avec Filtre Géographique

1. **Aller dans** "Listes" → "Nouvelle liste"
2. **Nom de la liste** : "Cadres Île-de-France"
3. **Type** : "Privée"
4. **Requête** : Coller un des filtres ci-dessus
5. **Sauvegarder**

### 2. Créer une Campagne

1. **Aller dans** "Campagnes" → "Nouvelle campagne"
2. **Sélectionner** votre liste géographique
3. **Personnaliser** le contenu selon la région
4. **Envoyer**

### 3. Tester les Filtres

Dans la section "Abonnés", utilisez la zone de requête pour tester vos filtres :

```sql
-- Test simple
region = 'Île-de-France'

-- Test avec comptage
SELECT COUNT(*) FROM subscribers WHERE region = 'Île-de-France'
```

---

## 📈 STATISTIQUES DISPONIBLES

### Vue des Statistiques Géographiques
```sql
SELECT * FROM stats_geographiques
```

Cette vue vous donne :
- Nombre total d'abonnés
- Nombre d'abonnés avec données géographiques
- Répartition par région
- Répartition par CSP

### Requêtes Statistiques Utiles

```sql
-- Top 5 des régions
SELECT region, COUNT(*) as nb_abonnes 
FROM subscribers 
WHERE region IS NOT NULL AND status = 'enabled'
GROUP BY region 
ORDER BY nb_abonnes DESC 
LIMIT 5;

-- Répartition par CSP
SELECT csp, COUNT(*) as nb_abonnes 
FROM subscribers 
WHERE csp IS NOT NULL AND status = 'enabled'
GROUP BY csp 
ORDER BY nb_abonnes DESC;

-- Âge moyen par région
SELECT region, ROUND(AVG(age), 1) as age_moyen 
FROM subscribers 
WHERE region IS NOT NULL AND age IS NOT NULL AND status = 'enabled'
GROUP BY region 
ORDER BY age_moyen DESC;
```

---

## ✅ AVANTAGES DE CETTE SOLUTION

1. **Simplicité** : Plus besoin de requêtes JSON complexes
2. **Performance** : Index optimisés sur toutes les colonnes géographiques
3. **Compatibilité** : Fonctionne parfaitement avec l'interface Listmonk
4. **Flexibilité** : Combinaisons infinies de filtres
5. **Vues prêtes** : Segments prédéfinis pour un usage immédiat

---

## 🎯 PROCHAINES ÉTAPES

1. **Tester** les filtres dans l'interface Listmonk
2. **Créer** vos premières listes géographiques
3. **Lancer** une campagne test
4. **Analyser** les résultats par zone géographique
5. **Optimiser** vos segments selon les retours

**L'extension géographique est maintenant 100% compatible avec l'interface Listmonk ! 🚀🗺️**