# 🇫🇷 Listmonk - Extensions Géographiques Françaises

## 📋 Vue d'ensemble

Cette version de Listmonk inclut des extensions géographiques spécifiquement conçues pour la France :
- **94 départements français** avec leurs régions
- **API géographiques** pour la segmentation
- **Colonnes géographiques** dans la base de données
- **Interface de sélection** par région/département

## 🗺️ Données Géographiques

### Base de Données
- **Table** : `departement_region_mapping`
- **94 départements** : 01 (Ain) à 95 (Val-d'Oise)
- **13 régions** : Toutes les régions françaises actuelles

### Colonnes Subscribers
```sql
-- Nouvelles colonnes géographiques
code_insee VARCHAR(10)           -- Code INSEE de la commune
nom_commune VARCHAR(255)         -- Nom de la commune  
departement_numero VARCHAR(3)    -- Numéro du département (01-95)
csp VARCHAR(100)                -- Catégorie socio-professionnelle
population_commune INTEGER      -- Population de la commune
```

## 🔌 API Endpoints

### Géographiques
- `GET /api/geo/regions` - Liste des régions françaises
- `GET /api/geo/departements` - Liste des départements avec régions
- `GET /api/geo/communes?search=<terme>&departement=<num>` - Recherche de communes
- `GET /api/geo/csps` - Liste des catégories socio-professionnelles
- `GET /api/geo/stats` - Statistiques géographiques des abonnés

### Segmentation
- `POST /api/lists/query/geo` - Requête de segmentation géographique

## 🚀 Installation

### Prérequis
- PostgreSQL 15+
- Go 1.24+
- Node.js (pour le frontend)

### Installation Automatique
```bash
# Script d'installation complet
./install-no-docker-final.sh
```

### Installation Manuelle
```bash
# 1. Configurer PostgreSQL
sudo -u postgres createuser -s listmonk
sudo -u postgres createdb listmonk -O listmonk
sudo -u postgres psql -c "ALTER USER listmonk PASSWORD 'listmonk';"

# 2. Compiler Listmonk
go build -o listmonk cmd/*.go

# 3. Initialiser la base
./listmonk --install --config config.toml

# 4. Appliquer les migrations géographiques
./check-migration-status.sh

# 5. Compiler le frontend
./build-frontend.sh

# 6. Démarrer
./listmonk --config config.toml
```

## 🧪 Tests

### Test Complet
```bash
./test-geo-final.sh
```

### Tests Spécifiques
```bash
# Vérifier les requêtes SQL
./test-sql-queries.sh

# Vérifier les migrations
./check-migration-status.sh
```

## 📁 Structure des Fichiers

### Backend
- `cmd/geo.go` - Handlers API géographiques
- `cmd/handlers.go` - Routes API
- `queries.sql` - Requêtes SQL géographiques
- `models/models.go` - Modèles de données

### Scripts
- `install-no-docker-final.sh` - Installation complète
- `check-migration-status.sh` - Vérification migrations
- `test-geo-final.sh` - Tests finaux
- `build-frontend.sh` - Compilation frontend

### Configuration
- `config.toml` - Configuration Listmonk
- `schema.sql` - Schéma de base avec extensions

## 🔧 Configuration

### PostgreSQL
```toml
[db]
host = "localhost"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"
```

### Listmonk
```toml
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "password"
```

## 📊 Utilisation

### Interface Web
1. Accéder à http://localhost:9000
2. Se connecter avec vos identifiants
3. Utiliser les menus déroulants géographiques dans :
   - Création de listes
   - Segmentation d'abonnés
   - Statistiques géographiques

### API
```bash
# Récupérer les régions
curl -H "Cookie: session=..." http://localhost:9000/api/geo/regions

# Rechercher des communes
curl -H "Cookie: session=..." "http://localhost:9000/api/geo/communes?search=Paris"

# Statistiques géographiques
curl -H "Cookie: session=..." http://localhost:9000/api/geo/stats
```

## 🐛 Dépannage

### Problèmes Courants

**1. Colonnes manquantes**
```bash
./check-migration-status.sh
```

**2. Frontend non compilé**
```bash
./build-frontend.sh
```

**3. Permissions PostgreSQL**
```bash
sudo -u postgres psql -c "ALTER USER listmonk CREATEDB;"
```

**4. API géographiques inaccessibles**
- Vérifier l'authentification
- Vérifier les permissions utilisateur

### Logs
```bash
# Logs Listmonk
./listmonk --config config.toml

# Logs PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

## 🔄 Mise à Jour

```bash
# Sauvegarder la base
pg_dump -h localhost -U listmonk listmonk > backup.sql

# Mettre à jour le code
git pull origin feature/french-geographic-segmentation

# Recompiler
go build -o listmonk cmd/*.go
./build-frontend.sh

# Redémarrer
./listmonk --config config.toml
```

## 📝 Développement

### Ajouter de Nouvelles Régions
1. Modifier `schema.sql`
2. Ajouter les données dans `departement_region_mapping`
3. Mettre à jour les requêtes dans `queries.sql`

### Nouvelles API Géographiques
1. Ajouter les handlers dans `cmd/geo.go`
2. Enregistrer les routes dans `cmd/handlers.go`
3. Ajouter les requêtes SQL dans `queries.sql`
4. Mettre à jour les modèles dans `models/models.go`

## ✅ État Actuel

- ✅ Installation fonctionnelle
- ✅ Base de données complète (94 départements)
- ✅ API géographiques opérationnelles
- ✅ Frontend compilé
- ✅ Migration v5.1.0 appliquée
- ⚠️ Interface géographique à tester en production

## 🤝 Contribution

Pour contribuer aux extensions géographiques :
1. Fork le repository
2. Créer une branche feature
3. Tester avec `./test-geo-final.sh`
4. Soumettre une pull request

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-06-12  
**Compatibilité** : Listmonk v3.0.0+