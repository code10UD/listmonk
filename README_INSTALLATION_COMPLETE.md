# 🚀 INSTALLATION COMPLÈTE LISTMONK + DONNÉES GÉOGRAPHIQUES

## 🎯 **INSTALLATION EN UNE COMMANDE**

```bash
./setup-complete-with-data.sh
```

## 📋 **CE QUE FAIT LE SCRIPT :**

### 1. 🚨 **Installation de base Listmonk**
- Reset complet (suppression des conflits)
- PostgreSQL 13 avec configuration standard
- Binding sur 0.0.0.0:9000 (accessible de l'extérieur)

### 2. 🗺️ **Extension géographique française**
- 10 colonnes géographiques sur la table subscribers
- Tables de référence (13 régions, 95+ départements)
- Index optimisés pour les recherches

### 3. 📊 **Import des données des mairies**
- Téléchargement automatique de `mairielist.csv`
- Import de toutes les mairies françaises avec :
  - Données de contact (email, téléphone, adresse)
  - Informations géographiques (région, département, commune)
  - Codes INSEE et populations
  - Catégories socio-professionnelles

### 4. 🔐 **Configuration du compte admin**
- Interface web pour créer le compte au premier accès
- Script optionnel `./create-admin-user.sh`

## ✅ **RÉSULTAT FINAL**

### 🌐 **Accès à l'application :**
- **URL** : http://0.0.0.0:9000 (ou http://VOTRE_IP:9000)
- **Premier accès** : Interface de création du compte admin

### 📊 **Données importées :**
- ✅ **Mairies françaises** avec données géographiques complètes
- ✅ **13 régions françaises** 
- ✅ **95+ départements**
- ✅ **Codes INSEE et populations**
- ✅ **Catégories socio-professionnelles**

### 🗺️ **Colonnes géographiques disponibles :**
- `region` - Région française
- `departement` - Département (numéro)
- `commune` - Commune
- `code_postal` - Code postal
- `code_insee` - Code INSEE
- `latitude` - Latitude GPS (prêt pour géolocalisation)
- `longitude` - Longitude GPS (prêt pour géolocalisation)
- `population` - Population de la commune
- `csp` - Catégorie Socio-Professionnelle
- `nom_commune` - Nom complet de la commune

## 🔧 **SCRIPTS DISPONIBLES**

- `setup-complete-with-data.sh` - Installation complète avec données
- `fix-brutal.sh` - Installation de base seulement
- `fix-address-binding.sh` - Correction du binding address
- `create-admin-user.sh` - Création du compte admin
- `add-geo-extension-simple.sql` - Extension géographique SQL

## 🎯 **UTILISATION APRÈS INSTALLATION**

### 1. **Premier accès :**
```bash
# Ouvrir dans le navigateur
http://VOTRE_IP:9000
```

### 2. **Créer le compte admin :**
- Via l'interface web (recommandé)
- Ou via le script : `./create-admin-user.sh`

### 3. **Vérifier les données :**
```bash
# Statut des containers
docker-compose ps

# Nombre d'abonnés importés
docker-compose exec db psql -U postgres -d listmonk -c "SELECT COUNT(*) FROM subscribers;"

# Vérification des régions
docker-compose exec db psql -U postgres -d listmonk -c "SELECT region, COUNT(*) FROM subscribers GROUP BY region;"
```

## 🎉 **PRÊT POUR LA SEGMENTATION GÉOGRAPHIQUE !**

Vous pouvez maintenant créer des campagnes ciblées par :
- Région
- Département  
- Code postal
- Population de la commune
- Catégorie socio-professionnelle

**L'extension géographique française est complètement opérationnelle !**