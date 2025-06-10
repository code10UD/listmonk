# 🐳 Listmonk avec Extension Géographique Française - Installation Docker

## 🚀 Installation Rapide (5 minutes)

```bash
# 1. Cloner le repository
git clone https://github.com/code7UD/listmonk.git listmonk-geo
cd listmonk-geo

# 2. Basculer sur la branche géographique
git checkout feature/french-geographic-segmentation

# 3. Démarrage automatique
./start-geo.sh
```

**C'est tout !** Listmonk sera accessible sur http://localhost:9000 avec toutes les fonctionnalités géographiques.

## 📋 Prérequis

- **Docker** 20.10+ et **Docker Compose** 2.0+
- **4 GB RAM** minimum
- **2 GB d'espace disque**
- **Ports libres** : 9000 (Listmonk), 5432 (PostgreSQL), 8080 (Adminer)

## 🎯 Fonctionnalités Incluses

### 🗺️ Segmentation Géographique
- **13 régions françaises** métropolitaines
- **95 départements** français
- **Toutes les communes** avec codes INSEE
- **Filtrage par population** communale
- **Catégories socio-professionnelles** (CSP)

### 📊 Données Géographiques
- **Codes INSEE** officiels
- **Population communale** 
- **Mapping départements/régions** automatique
- **Données démographiques** complètes
- **Import CSV** avec validation géographique

### 🔌 API REST Complète
- `/api/geo/regions` - Liste des régions
- `/api/geo/departements` - Liste des départements
- `/api/geo/communes` - Recherche de communes
- `/api/geo/csps` - Catégories socio-professionnelles
- `/api/geo/stats` - Statistiques géographiques
- `/api/lists/query/geo` - Requêtes de segmentation

## 📁 Structure des Fichiers

```
listmonk-geo/
├── 🐳 docker-compose.geo.yml     # Configuration Docker principale
├── 🐳 Dockerfile.geo             # Image personnalisée avec extension géo
├── ⚙️ .env.example               # Configuration d'environnement
├── 🚀 start-geo.sh               # Script de démarrage rapide
├── 🧪 test-docker-geo.sh         # Script de test complet
├── 📚 INSTALLATION_DOCKER.md     # Documentation détaillée
├── 📚 GEOGRAPHIC_FEATURES.md     # Guide des fonctionnalités
├── docker/
│   ├── entrypoint.sh             # Point d'entrée avec init géographique
│   ├── init-scripts/             # Scripts d'initialisation PostgreSQL
│   └── scripts/                  # Scripts d'import et maintenance
├── config/
│   └── config.toml               # Configuration Listmonk
└── demo/
    ├── demo_geo_data.csv         # Données de démonstration
    └── demo_geographic_queries.sql # Exemples de requêtes
```

## 🔧 Installation Manuelle

### 1. Préparation

```bash
# Cloner et configurer
git clone https://github.com/code7UD/listmonk.git listmonk-geo
cd listmonk-geo
git checkout feature/french-geographic-segmentation

# Créer la configuration
cp .env.example .env
mkdir -p data/postgres data/uploads demo
```

### 2. Configuration

Éditez le fichier `.env` selon vos besoins :

```env
# Mots de passe sécurisés
POSTGRES_PASSWORD=votre_mot_de_passe_securise
ADMIN_PASSWORD=votre_mot_de_passe_admin

# Import de données de démonstration
IMPORT_DEMO_DATA=true

# Configuration SMTP (optionnel)
LISTMONK_SMTP_HOST=smtp.gmail.com
LISTMONK_SMTP_USERNAME=votre_email@gmail.com
LISTMONK_SMTP_PASSWORD=votre_mot_de_passe_app
```

### 3. Démarrage

```bash
# Construction et démarrage
docker-compose -f docker-compose.geo.yml build
docker-compose -f docker-compose.geo.yml up -d

# Vérification
docker-compose -f docker-compose.geo.yml ps
```

## 🧪 Tests et Validation

### Test Automatique Complet

```bash
./test-docker-geo.sh
```

### Tests Manuels

```bash
# 1. Test de connectivité
curl http://localhost:9000/health

# 2. Test de la base de données
docker-compose -f docker-compose.geo.yml exec postgres \
  psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departement_region_mapping;"

# 3. Test des API (nécessite authentification)
curl -X GET http://localhost:9000/api/geo/regions

# 4. Requêtes de démonstration
docker-compose -f docker-compose.geo.yml exec postgres \
  psql -U listmonk -d listmonk -f /listmonk/demo/demo_geographic_queries.sql
```

## 📊 Import de Données CSV

### Format CSV Supporté

```csv
email,firstname,lastname,code_insee,population_commune,nom_commune,departement_numero,state,csp
marie.dupont@example.com,Marie,DUPONT,75101,50000,PARIS 1ER ARRONDISSEMENT,75,PARIS,Cadres et professions intellectuelles supérieures
```

### Import via Interface Web

1. Connectez-vous à http://localhost:9000
2. **Subscribers** → **Import**
3. Uploadez votre fichier CSV
4. Mappez les colonnes géographiques
5. Lancez l'import

### Import via Script

```bash
# Copier le fichier dans le container
docker cp votre_fichier.csv listmonk-app-geo:/listmonk/import.csv

# Importer (script personnalisé à créer)
docker-compose -f docker-compose.geo.yml exec listmonk \
  ./scripts/import_csv.sh /listmonk/import.csv
```

## 🎯 Exemples d'Utilisation

### 1. Segmentation par Région

```bash
curl -X POST http://localhost:9000/api/lists/query/geo \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "regions": ["Auvergne-Rhône-Alpes", "Provence-Alpes-Côte d'\''Azur"]
  }'
```

### 2. Filtrage par Population

```bash
curl -X POST http://localhost:9000/api/lists/query/geo \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "use_population": true,
    "population_min": 10000,
    "population_max": 100000
  }'
```

### 3. Segmentation par CSP

```bash
curl -X POST http://localhost:9000/api/lists/query/geo \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "csps": ["Cadres et professions intellectuelles supérieures"]
  }'
```

## 🔧 Maintenance

### Sauvegarde

```bash
# Base de données
docker-compose -f docker-compose.geo.yml exec postgres \
  pg_dump -U listmonk listmonk > backup_$(date +%Y%m%d).sql

# Fichiers uploadés
docker cp listmonk-app-geo:/listmonk/uploads ./backup_uploads_$(date +%Y%m%d)
```

### Mise à Jour

```bash
# Arrêter les services
docker-compose -f docker-compose.geo.yml down

# Mettre à jour le code
git pull origin feature/french-geographic-segmentation

# Reconstruire et redémarrer
docker-compose -f docker-compose.geo.yml build --no-cache
docker-compose -f docker-compose.geo.yml up -d
```

### Monitoring

```bash
# Logs en temps réel
docker-compose -f docker-compose.geo.yml logs -f

# Statistiques des containers
docker stats listmonk-app-geo listmonk-postgres-geo

# Performance de la base de données
docker-compose -f docker-compose.geo.yml exec postgres \
  psql -U listmonk -d listmonk -c "
  SELECT schemaname, tablename, attname, n_distinct 
  FROM pg_stats 
  WHERE tablename = 'subscribers' 
  AND attname IN ('departement_numero', 'code_insee');"
```

## 🐛 Dépannage

### Problèmes Courants

#### Services ne démarrent pas

```bash
# Vérifier les logs
docker-compose -f docker-compose.geo.yml logs

# Vérifier les ports
netstat -tulpn | grep -E ':(9000|5432|8080)'

# Nettoyer et redémarrer
docker-compose -f docker-compose.geo.yml down -v
docker-compose -f docker-compose.geo.yml up -d
```

#### Erreur de migration

```bash
# Forcer la migration
docker-compose -f docker-compose.geo.yml exec listmonk \
  ./listmonk --config config.toml --upgrade --yes

# Vérifier l'état de la base
docker-compose -f docker-compose.geo.yml exec postgres \
  psql -U listmonk -d listmonk -c "SELECT version FROM schema_migrations;"
```

#### Import CSV échoue

```bash
# Vérifier l'encodage
file -i votre_fichier.csv

# Convertir en UTF-8
iconv -f ISO-8859-1 -t UTF-8 votre_fichier.csv > votre_fichier_utf8.csv

# Vérifier les logs d'import
docker-compose -f docker-compose.geo.yml logs listmonk | grep -i import
```

## 🌐 Accès aux Services

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Listmonk** | http://localhost:9000 | admin / admin123! |
| **Adminer** | http://localhost:8080 | listmonk / [mot_de_passe] |
| **PostgreSQL** | localhost:5432 | listmonk / [mot_de_passe] |

## 📚 Documentation Complète

- **[GEOGRAPHIC_FEATURES.md](GEOGRAPHIC_FEATURES.md)** - Guide complet des fonctionnalités
- **[INSTALLATION_DOCKER.md](INSTALLATION_DOCKER.md)** - Documentation détaillée
- **[demo_geographic_queries.sql](demo_geographic_queries.sql)** - Exemples de requêtes
- **Repository GitHub** : https://github.com/code7UD/listmonk/tree/feature/french-geographic-segmentation

## 🎉 Support

Pour toute question ou problème :

1. Consultez la documentation complète
2. Exécutez le script de test : `./test-docker-geo.sh`
3. Vérifiez les logs : `docker-compose -f docker-compose.geo.yml logs`
4. Ouvrez une issue sur GitHub

---

**🗺️ Bon géomarketing avec Listmonk !**