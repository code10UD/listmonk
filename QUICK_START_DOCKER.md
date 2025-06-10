# 🚀 Installation Express - Listmonk Géographique avec Docker

## ⚡ Installation en 3 Commandes

### 🚀 Version Standard
```bash
# 1. Cloner et configurer
git clone https://github.com/code7UD/listmonk.git && cd listmonk
git checkout feature/french-geographic-segmentation

# 2. Démarrer (tout automatique)
./start-geo.sh

# 3. Accéder à l'interface
# http://localhost:9000 (admin/admin123!)
```

### 🛡️ Version Simplifiée (Recommandée si problèmes)
```bash
# 1. Cloner et configurer
git clone https://github.com/code7UD/listmonk.git && cd listmonk
git checkout feature/french-geographic-segmentation

# 2. Démarrer (version sans build frontend)
./start-geo-simple.sh

# 3. Accéder à l'interface
# http://localhost:9000 (admin/admin123!)
```

### 🔧 En cas de Problème
```bash
# Si erreur de build frontend
./fix-frontend-build.sh

# Si erreur de version Go
./fix-docker-go-version.sh

# Version de secours
./start-geo-simple.sh
```

## 🎯 Ce que vous obtenez

### ✅ Listmonk Complet
- Interface d'administration complète
- Gestion des abonnés et campagnes
- Templates d'emails
- Statistiques et analytics

### ✅ Extension Géographique Française
- **13 régions** françaises métropolitaines
- **95 départements** français
- **Toutes les communes** avec codes INSEE
- **Filtrage par population** communale
- **Catégories socio-professionnelles** (CSP)

### ✅ API REST Géographique
- `/api/geo/regions` - Régions françaises
- `/api/geo/departements` - Départements
- `/api/geo/communes` - Communes avec autocomplete
- `/api/geo/csps` - Catégories socio-professionnelles
- `/api/geo/stats` - Statistiques géographiques
- `/api/lists/query/geo` - Segmentation avancée

### ✅ Base de Données Optimisée
- PostgreSQL 15 avec extensions géographiques
- Index optimisés pour les requêtes géographiques
- Mapping complet départements/régions français
- Migration automatique des données

## 📊 Exemples d'Utilisation

### 🎯 Campagne Régionale
```sql
-- Cibler les abonnés d'Auvergne-Rhône-Alpes
SELECT COUNT(*) FROM subscribers s 
LEFT JOIN departement_region_mapping drm ON s.departement_numero = drm.departement_numero 
WHERE s.status = 'enabled' AND drm.region_nom = 'Auvergne-Rhône-Alpes';
```

### 🏙️ Marketing Urbain/Rural
```sql
-- Cibler les villes moyennes (10k-50k habitants)
SELECT COUNT(*) FROM subscribers 
WHERE status = 'enabled' 
AND population_commune BETWEEN 10000 AND 50000;
```

### 👥 Segmentation Démographique
```sql
-- Cibler les cadres en Île-de-France
SELECT COUNT(*) FROM subscribers s 
LEFT JOIN departement_region_mapping drm ON s.departement_numero = drm.departement_numero 
WHERE s.status = 'enabled' 
AND drm.region_nom = 'Île-de-France'
AND s.csp LIKE '%Cadres%';
```

## 📥 Import CSV Géographique

### Format Supporté
```csv
email,firstname,lastname,code_insee,population_commune,nom_commune,departement_numero,state,csp
marie.dupont@example.com,Marie,DUPONT,75101,50000,PARIS 1ER ARRONDISSEMENT,75,PARIS,Cadres et professions intellectuelles supérieures
```

### Procédure d'Import
1. **Interface Web** : http://localhost:9000 → Subscribers → Import
2. **Mapper les colonnes** géographiques
3. **Lancer l'import** avec validation automatique

## 🔧 Commandes Utiles

```bash
# Voir les logs
docker-compose -f docker-compose.geo.yml logs -f

# Arrêter les services
docker-compose -f docker-compose.geo.yml down

# Redémarrer
docker-compose -f docker-compose.geo.yml restart

# Test complet
./test-docker-geo.sh

# Sauvegarde
docker-compose -f docker-compose.geo.yml exec postgres \
  pg_dump -U listmonk listmonk > backup_$(date +%Y%m%d).sql
```

## 🌐 Accès aux Services

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Listmonk** | http://localhost:9000 | admin / admin123! |
| **Adminer** | http://localhost:8080 | listmonk / [voir .env] |

## 🐛 Dépannage Express

### Problème de Démarrage
```bash
# Nettoyer et redémarrer
docker-compose -f docker-compose.geo.yml down -v
./start-geo.sh
```

### Erreur de Port
```bash
# Vérifier les ports utilisés
netstat -tulpn | grep -E ':(9000|5432|8080)'

# Modifier les ports dans docker-compose.geo.yml si nécessaire
```

### Import CSV Échoue
```bash
# Vérifier l'encodage
file -i votre_fichier.csv

# Convertir en UTF-8 si nécessaire
iconv -f ISO-8859-1 -t UTF-8 votre_fichier.csv > votre_fichier_utf8.csv
```

## 📚 Documentation Complète

- **[README_DOCKER_GEO.md](README_DOCKER_GEO.md)** - Guide complet Docker
- **[INSTALLATION_DOCKER.md](INSTALLATION_DOCKER.md)** - Installation détaillée
- **[GEOGRAPHIC_FEATURES.md](GEOGRAPHIC_FEATURES.md)** - Fonctionnalités géographiques
- **[demo_geographic_queries.sql](demo_geographic_queries.sql)** - Exemples SQL

## 🎉 Support

1. **Documentation** : Consultez les guides complets
2. **Tests** : Exécutez `./test-docker-geo.sh`
3. **Logs** : `docker-compose -f docker-compose.geo.yml logs`
4. **GitHub** : Ouvrez une issue sur le repository

---

**🗺️ Prêt pour le géomarketing français avec Listmonk !**