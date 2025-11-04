# 🇫🇷 Installation Listmonk avec Extensions Géographiques Françaises

## ✅ Installation Réussie

Cette installation inclut :
- **Listmonk** fonctionnel avec base PostgreSQL
- **Extensions géographiques françaises** : 94 départements et régions
- **API géographiques** : endpoints pour régions, départements, communes, CSP
- **Frontend compilé** et accessible
- **Migration v5.1.0** appliquée avec colonnes géographiques

## 📊 Données Géographiques Disponibles

### Base de Données
- **94 départements français** avec leurs régions
- **Colonnes géographiques** dans la table `subscribers` :
  - `code_insee` : Code INSEE de la commune
  - `nom_commune` : Nom de la commune
  - `departement_numero` : Numéro du département (01-95)
  - `csp` : Catégorie socio-professionnelle
  - `population_commune` : Population de la commune

### API Endpoints
- `GET /api/geo/regions` : Liste des régions françaises
- `GET /api/geo/departements` : Liste des départements avec régions
- `GET /api/geo/communes?search=<terme>` : Recherche de communes
- `GET /api/geo/csps` : Liste des CSP
- `GET /api/geo/stats` : Statistiques géographiques

## 🚀 Démarrage

```bash
# Démarrer PostgreSQL
sudo systemctl start postgresql

# Démarrer Listmonk
cd /tmp/listmonk
./listmonk --config config.toml
```

## 🧪 Tests

```bash
# Tester les API géographiques
./test-geo-api-public.sh

# Tester les requêtes SQL
./test-sql-queries.sh

# Vérifier la base de données
./check-migration-status.sh
```

## 📝 Configuration

### PostgreSQL
- **Base** : `listmonk`
- **Utilisateur** : `listmonk`
- **Port** : `5432`

### Listmonk
- **Interface** : http://localhost:9000
- **Utilisateur** : `vincent@updigit.fr`
- **Type** : `user`

## 🔧 Prochaines Étapes

1. **Corriger l'authentification** des API géographiques
2. **Remettre les permissions** appropriées
3. **Tester l'interface** avec les menus déroulants
4. **Optimiser les performances** des requêtes géographiques

## 📁 Fichiers Importants

- `config.toml` : Configuration Listmonk
- `cmd/geo.go` : Handlers API géographiques
- `queries.sql` : Requêtes SQL géographiques
- `models/models.go` : Modèles de données géographiques
- `cmd/handlers.go` : Routes API

## ✅ État Actuel

- ✅ Listmonk démarre sans erreur
- ✅ Base de données complète avec données géographiques
- ✅ API géographiques fonctionnelles (groupe public temporaire)
- ✅ Frontend compilé et accessible
- ⚠️ Authentification API à corriger pour production