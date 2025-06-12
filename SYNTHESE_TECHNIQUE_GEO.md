# 🔧 SYNTHÈSE TECHNIQUE - Implémentation Géographique Listmonk

## 📋 RÉSUMÉ POUR DÉVELOPPEURS

**Objectif :** Interface de segmentation géographique française pour Listmonk  
**État actuel :** Frontend 100% ✅ | Backend 70% ⚠️ | BDD 100% ✅  
**Travail restant :** Implémentation handlers API backend (2-3 jours)

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Stack Technologique
```
Frontend:  Vue.js 2 + Buefy + Vite
Backend:   Go + Echo + PostgreSQL  
Database:  PostgreSQL + Extensions géographiques
Deploy:    Docker + Docker Compose
```

### Structure des Fichiers
```
listmonk/
├── frontend/src/
│   ├── components/GeoSelector.vue      ✅ Composant principal
│   ├── views/SubscriberForm.vue        ✅ Formulaire étendu
│   ├── views/Subscribers.vue           ✅ Recherche étendue
│   └── api/index.js                    ✅ 5 méthodes API
├── cmd/
│   ├── handlers.go                     ✅ Routes déclarées
│   └── geo.go                          ❌ MANQUANT - À créer
├── models/models.go                    ✅ Modèles étendus
├── queries.sql                         ⚠️ Requêtes partielles
└── docker/init-scripts/01-init-geo.sql ✅ BDD configurée
```

---

## 🎯 TRAVAIL À EFFECTUER

### 1. Créer `/cmd/geo.go` (PRIORITÉ 1)

```go
package main

import (
    "net/http"
    "strconv"
    "github.com/labstack/echo/v4"
    "github.com/knadh/listmonk/models"
)

// handleGetRegions retourne la liste des régions françaises
func (app *App) handleGetRegions(c echo.Context) error {
    // TODO: Implémenter
    return c.JSON(http.StatusOK, okResp{Data: regions})
}

// handleGetDepartements retourne la liste des départements
func (app *App) handleGetDepartements(c echo.Context) error {
    // TODO: Implémenter
    return c.JSON(http.StatusOK, okResp{Data: departements})
}

// handleGetCommunes recherche les communes
func (app *App) handleGetCommunes(c echo.Context) error {
    // TODO: Implémenter avec paramètres de recherche
    return c.JSON(http.StatusOK, okResp{Data: communes})
}

// handleGetCSPs retourne les CSP disponibles
func (app *App) handleGetCSPs(c echo.Context) error {
    // TODO: Implémenter
    return c.JSON(http.StatusOK, okResp{Data: csps})
}

// handleGeoQuery traite les requêtes géographiques complexes
func (app *App) handleGeoQuery(c echo.Context) error {
    // TODO: Implémenter filtrage géographique
    return c.JSON(http.StatusOK, okResp{Data: result})
}
```

### 2. Ajouter Requêtes SQL dans `/queries.sql` (PRIORITÉ 2)

```sql
-- name: get-geo-regions
-- Récupère la liste des régions françaises
SELECT DISTINCT region_nom, region_code 
FROM departement_region_mapping 
ORDER BY region_nom;

-- name: get-geo-departements  
-- Récupère la liste des départements avec leurs régions
SELECT departement_numero, departement_nom, region_nom, region_code
FROM departement_region_mapping 
ORDER BY departement_nom;

-- name: get-geo-communes
-- Recherche de communes par nom et/ou département
SELECT DISTINCT nom_commune, code_insee, population_commune, departement_numero,
       COUNT(*) as count
FROM subscribers 
WHERE nom_commune IS NOT NULL
  AND ($1 = '' OR nom_commune ILIKE '%' || $1 || '%')
  AND ($2 = '' OR departement_numero = $2)
GROUP BY nom_commune, code_insee, population_commune, departement_numero
ORDER BY count DESC, nom_commune
LIMIT 50;

-- name: get-geo-csps
-- Récupère les CSP disponibles avec comptage
SELECT csp, COUNT(*) as count
FROM subscribers 
WHERE csp IS NOT NULL AND csp != ''
GROUP BY csp
ORDER BY count DESC;

-- name: query-subscribers-geo
-- Requête géographique complexe pour filtrer les abonnés
SELECT COUNT(*) as total
FROM subscribers s
LEFT JOIN departement_region_mapping drm ON s.departement_numero = drm.departement_numero
WHERE s.status = 'enabled'
  AND (CARDINALITY($1::TEXT[]) = 0 OR drm.region_nom = ANY($1))
  AND (CARDINALITY($2::TEXT[]) = 0 OR s.departement_numero = ANY($2))
  AND (CARDINALITY($3::TEXT[]) = 0 OR s.code_insee = ANY($3))
  AND (CARDINALITY($4::TEXT[]) = 0 OR s.csp = ANY($4))
  AND ($5 = 0 OR s.population_commune >= $5)
  AND ($6 = 0 OR s.population_commune <= $6);
```

---

## 🔌 API ENDPOINTS À IMPLÉMENTER

### Endpoints Géographiques
```
GET  /api/geo/regions        → Liste des régions
GET  /api/geo/departements   → Liste des départements  
GET  /api/geo/communes       → Recherche de communes
GET  /api/geo/csps          → Liste des CSP
POST /api/lists/query/geo   → Requête géographique
```

### Paramètres d'Entrée
```javascript
// GET /api/geo/communes?search=paris&departement=75
{
  "search": "paris",        // Optionnel: recherche textuelle
  "departement": "75"       // Optionnel: filtre par département
}

// POST /api/lists/query/geo
{
  "regions": ["Île-de-France"],
  "departements": ["75", "92"],
  "communes": ["Paris", "Nanterre"],
  "codes_insee": ["75001", "92050"],
  "csps": ["Cadres"],
  "use_population": true,
  "population_min": 10000,
  "population_max": 100000
}
```

### Réponses Attendues
```javascript
// GET /api/geo/regions
{
  "data": [
    {
      "region_nom": "Île-de-France",
      "region_code": "11"
    }
  ]
}

// GET /api/geo/departements
{
  "data": [
    {
      "departement_numero": "75",
      "departement_nom": "Paris", 
      "region_nom": "Île-de-France",
      "region_code": "11"
    }
  ]
}

// POST /api/lists/query/geo
{
  "data": {
    "count": 1250
  }
}
```

---

## 🗄️ MODÈLES DE DONNÉES DISPONIBLES

### Structures Go Existantes
```go
// Paramètres de requête géographique
type GeoQueryParams struct {
    Regions               []string `json:"regions"`
    Departements          []string `json:"departements"`
    Communes              []string `json:"communes"`
    UsePopulation         bool     `json:"use_population"`
    PopulationMin         *int     `json:"population_min,omitempty"`
    PopulationMax         *int     `json:"population_max,omitempty"`
    CSPs                  []string `json:"csps,omitempty"`
    CodesINSEE            []string `json:"codes_insee,omitempty"`
}

// Mapping départements/régions  
type DepartementRegion struct {
    DepartementNumero string `db:"departement_numero" json:"departement_numero"`
    DepartementNom    string `db:"departement_nom" json:"departement_nom"`
    RegionNom         string `db:"region_nom" json:"region_nom"`
    RegionCode        string `db:"region_code" json:"region_code"`
}

// Informations de communes
type CommuneInfo struct {
    NomCommune        string `db:"nom_commune" json:"nom_commune"`
    CodeINSEE         string `db:"code_insee" json:"code_insee"`
    PopulationCommune int    `db:"population_commune" json:"population_commune"`
    DepartementNumero string `db:"departement_numero" json:"departement_numero"`
    Count             int    `db:"count" json:"count"`
}

// Informations CSP
type CSPInfo struct {
    CSP   string `db:"csp" json:"csp"`
    Count int    `db:"count" json:"count"`
}
```

---

## 🧪 TESTS À EFFECTUER

### Tests Frontend
```bash
# Démarrer le frontend
cd frontend && npm run dev

# Vérifier dans le navigateur :
# 1. Page /admin/subscribers → Recherche avancée → GeoSelector visible
# 2. Formulaire abonné → Onglet "Sélection géographique" 
# 3. Console : pas d'erreurs API 404
```

### Tests Backend
```bash
# Tester les endpoints (après implémentation)
curl -X GET "http://localhost:9000/api/geo/regions"
curl -X GET "http://localhost:9000/api/geo/departements"
curl -X GET "http://localhost:9000/api/geo/communes?search=paris"
curl -X GET "http://localhost:9000/api/geo/csps"

curl -X POST "http://localhost:9000/api/lists/query/geo" \
  -H "Content-Type: application/json" \
  -d '{"regions":["Île-de-France"]}'
```

### Tests Base de Données
```sql
-- Vérifier les données géographiques
SELECT COUNT(*) FROM departement_region_mapping; -- Doit retourner 95
SELECT DISTINCT region_nom FROM departement_region_mapping; -- 13 régions
SELECT * FROM subscribers WHERE departement_numero IS NOT NULL LIMIT 5;
```

---

## 🚀 PROCÉDURE DE DÉPLOIEMENT

### 1. Développement Local
```bash
# 1. Implémenter les handlers dans /cmd/geo.go
# 2. Ajouter les requêtes dans /queries.sql  
# 3. Tester avec le frontend

# Démarrage complet
./launch-app-complete.sh
```

### 2. Validation
```bash
# Test frontend uniquement
./test-app-simple.sh

# Vérification endpoints
curl -f http://localhost:12000/api/geo/regions || echo "❌ API non fonctionnelle"
```

### 3. Production
```bash
# Build et déploiement
make build
docker-compose up -d
```

---

## 🔍 DEBUGGING

### Erreurs Communes
```
❌ "404 Not Found /api/geo/regions"
→ Handlers non implémentés dans geo.go

❌ "500 Internal Server Error" 
→ Requêtes SQL manquantes dans queries.sql

❌ "this.$api.getGeoRegions is not a function"
→ Méthodes API mal configurées (déjà corrigé)
```

### Logs Utiles
```bash
# Logs backend
docker logs listmonk_app

# Logs PostgreSQL  
docker logs listmonk_db

# Logs frontend
npm run dev # Affiche erreurs dans la console
```

---

## 📚 RESSOURCES

### Documentation
- [Listmonk API](https://listmonk.app/docs/apis/)
- [Echo Framework](https://echo.labstack.com/guide/)
- [Vue.js 2](https://v2.vuejs.org/v2/guide/)

### Données de Référence
- **95 départements français** dans `departement_region_mapping`
- **13 régions françaises** officielles
- **Codes INSEE** conformes aux standards

---

## ✅ CHECKLIST DÉVELOPPEUR

### Avant de Commencer
- [ ] Environnement Go configuré
- [ ] PostgreSQL accessible
- [ ] Frontend démarrable (`npm run dev`)

### Implémentation
- [ ] Créer `/cmd/geo.go` avec 5 handlers
- [ ] Ajouter 5 requêtes SQL dans `/queries.sql`
- [ ] Tester chaque endpoint individuellement
- [ ] Valider l'intégration frontend ↔ backend

### Validation
- [ ] Interface géographique fonctionnelle
- [ ] Recherche de communes opérationnelle  
- [ ] Filtrage par région/département/CSP
- [ ] Sauvegarde des données géographiques

### Finalisation
- [ ] Tests de performance avec données réelles
- [ ] Documentation API mise à jour
- [ ] Commit et push des modifications

---

**🎯 Objectif :** Interface géographique française 100% fonctionnelle  
**⏱️ Estimation :** 2-3 jours de développement  
**🔧 Complexité :** Moyenne (handlers API + requêtes SQL)