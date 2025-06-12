# 🚀 GUIDE D'INSTALLATION SERVEUR - LISTMONK GÉOGRAPHIQUE

## 📋 INSTALLATION RAPIDE (RECOMMANDÉE)

### 🔧 Prérequis
```bash
# Vérifier Go (version 1.19+)
go version

# Vérifier PostgreSQL ou Docker
psql --version
# OU
docker --version
```

### ⚡ Installation en Une Commande
```bash
# Cloner et installer automatiquement
git clone https://github.com/code10UD/listmonk.git
cd listmonk
git checkout feature/french-geographic-segmentation
chmod +x install-and-test.sh
./install-and-test.sh
```

**C'est tout ! 🎉**

---

## 🔧 INSTALLATION MANUELLE (SI NÉCESSAIRE)

### 1. Cloner le Projet
```bash
git clone https://github.com/code10UD/listmonk.git
cd listmonk
git checkout feature/french-geographic-segmentation
```

### 2. Démarrer PostgreSQL
```bash
# Avec Docker (recommandé)
docker run -d \
  --name listmonk_db \
  -e POSTGRES_USER=listmonk \
  -e POSTGRES_PASSWORD=listmonk \
  -e POSTGRES_DB=listmonk \
  -p 5432:5432 \
  postgres:17-alpine

# OU avec PostgreSQL local
sudo -u postgres createdb listmonk
sudo -u postgres createuser listmonk
sudo -u postgres psql -c "ALTER USER listmonk PASSWORD 'listmonk';"
```

### 3. Configuration
```bash
cat > config.toml << EOF
[db]
host = "localhost"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"

[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "admin"
EOF
```

### 4. Installation Base + Extensions
```bash
# Installation de base (sur branche master)
git checkout master
go run cmd/*.go --config config.toml --install --yes

# Application des extensions géographiques
git checkout feature/french-geographic-segmentation
go run cmd/*.go --config config.toml --upgrade --yes
```

### 5. Démarrage
```bash
# Démarrer Listmonk
go run cmd/*.go --config config.toml

# OU en arrière-plan
nohup go run cmd/*.go --config config.toml > listmonk.log 2>&1 &
```

---

## ✅ VÉRIFICATION

### Tests Rapides
```bash
# Backend actif
curl http://localhost:9000/api/health

# Endpoints géographiques (403 = normal sans auth)
curl -w "%{http_code}" http://localhost:9000/api/geo/regions

# Base de données
docker exec listmonk_db psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM departement_region_mapping;"
```

### Résultats Attendus
```
✅ Backend: {"message":"invalid session"} ou HTTP 200
✅ API Géo: HTTP 403 (Forbidden - normal sans auth)
✅ Base: 94 départements français
```

---

## 🌐 ACCÈS

### URLs
- **Interface Admin**: http://votre-serveur:9000
- **API Géographique**: http://votre-serveur:9000/api/geo/

### Identifiants
- **Email**: admin
- **Mot de passe**: admin

---

## 🔧 MAINTENANCE

### Commandes Utiles
```bash
# Arrêter Listmonk
pkill -f "go run cmd"

# Redémarrer
go run cmd/*.go --config config.toml

# Logs
tail -f listmonk.log

# Arrêter PostgreSQL Docker
docker stop listmonk_db

# Sauvegarde DB
pg_dump -U listmonk listmonk > backup.sql
```

### Dépannage
```bash
# Port occupé
sudo lsof -i :9000

# Vérifier PostgreSQL
docker ps | grep postgres

# Logs détaillés
go run cmd/*.go --config config.toml --verbose
```

---

## 🎯 FONCTIONNALITÉS DISPONIBLES

### ✨ Sélection Géographique
- 🗺️ **12 régions françaises** avec sélection multiple
- 🏛️ **94 départements** avec mapping automatique
- 🏘️ **Recherche de communes** avec autocomplétion
- 👔 **Filtrage par CSP** (Catégories Socio-Professionnelles)
- 📊 **Statistiques géographiques** en temps réel

### 🔗 API REST (6 Endpoints)
```
GET  /api/geo/regions        # Liste des régions
GET  /api/geo/departements   # Liste des départements  
GET  /api/geo/communes       # Recherche de communes
GET  /api/geo/csps          # Catégories socio-professionnelles
GET  /api/geo/stats         # Statistiques géographiques
POST /api/lists/query/geo   # Requête géographique avancée
```

### 📊 Données Intégrées
- **12 régions** métropolitaines françaises
- **94 départements** avec codes officiels
- **Mapping région ↔ département** automatique
- **Données INSEE** de population
- **CSP françaises** standardisées

---

## 🚨 SUPPORT

### En Cas de Problème
1. **Vérifier les logs**: `tail -f listmonk.log`
2. **Tester la DB**: `docker exec listmonk_db psql -U listmonk -d listmonk`
3. **Vérifier les ports**: `sudo lsof -i :9000`
4. **Relancer les tests**: `./test-final.sh`

### Scripts Inclus
- `install-and-test.sh` - Installation complète automatique
- `test-final.sh` - Validation de l'installation
- `test-geo-simple.sh` - Test rapide des fonctionnalités

---

## 🎉 RÉSULTAT FINAL

**LISTMONK AVEC EXTENSIONS GÉOGRAPHIQUES FRANÇAISES**

Votre installation inclut :
- ✅ Interface utilisateur complète
- ✅ API REST sécurisée  
- ✅ Base de données optimisée
- ✅ Données françaises officielles
- ✅ Performance optimisée
- ✅ Documentation complète

**🎯 Prêt pour la production !**

---

*Guide d'installation - Version 1.0*  
*Listmonk Géographique Français*