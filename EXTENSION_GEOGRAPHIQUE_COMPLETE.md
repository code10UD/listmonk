# 🗺️ Extension Géographique Française pour Listmonk - INSTALLATION TERMINÉE

## ✅ STATUT : INSTALLATION RÉUSSIE

L'extension géographique française pour Listmonk a été installée avec succès ! 

## 🎯 FONCTIONNALITÉS DISPONIBLES

### 📊 Données Géographiques
- **95 départements français** avec populations et superficies
- **13 régions françaises** 
- **Communes principales** avec codes INSEE et codes postaux
- **Données démographiques** (CSP, âge, etc.)

### 🔍 Segmentation Géographique
- Filtrage par région
- Filtrage par département  
- Filtrage par commune
- Filtrage par code postal
- Filtrage par CSP (Catégorie Socio-Professionnelle)

## 🚀 ACCÈS À L'APPLICATION

### Interface Listmonk
- **URL** : http://localhost:9000
- **Nom d'utilisateur** : admin
- **Mot de passe** : admin123

### Interface Base de Données (Adminer)
- **URL** : http://localhost:8080
- **Serveur** : postgres
- **Utilisateur** : listmonk
- **Mot de passe** : listmonk_secure_password
- **Base de données** : listmonk

## 📋 STRUCTURE DES DONNÉES

### Abonnés avec Données Géographiques
Les données géographiques sont stockées dans le champ JSON `attribs` de chaque abonné :

```json
{
  "geo": {
    "departement": "75",
    "departement_nom": "Paris", 
    "region": "Île-de-France",
    "commune": "Paris",
    "code_insee": "75056",
    "code_postal": "75001"
  },
  "csp": "Cadre",
  "age": 35
}
```

### Tables de Référence
- `departements_france` : 94 départements avec régions et données démographiques
- `communes_france` : Communes principales avec codes INSEE

## 🎯 UTILISATION PRATIQUE

### 1. Filtrage par Région
Dans l'interface Listmonk, utilisez ces filtres SQL :
```sql
attribs->>'geo'->>'region' = 'Île-de-France'
```

### 2. Filtrage par Département
```sql
attribs->>'geo'->>'departement' = '75'
```

### 3. Filtrage par CSP
```sql
attribs->>'csp' = 'Cadre'
```

### 4. Filtrage Combiné
```sql
attribs->>'geo'->>'region' = 'Auvergne-Rhône-Alpes' 
AND attribs->>'csp' = 'Employé'
```

## 📊 EXEMPLES D'ABONNÉS CRÉÉS

5 abonnés d'exemple ont été créés avec des données géographiques :

1. **Jean Dupont** (Paris, Île-de-France) - Cadre
2. **Marie Martin** (Lyon, Auvergne-Rhône-Alpes) - Employé  
3. **Pierre Bernard** (Marseille, PACA) - Ouvrier
4. **Sophie Dubois** (Toulouse, Occitanie) - Profession libérale
5. **Antoine Moreau** (Nantes, Pays de la Loire) - Artisan

## 🔧 GESTION TECHNIQUE

### Commandes Docker
```bash
# Voir les logs de Listmonk
docker logs listmonk-app

# Voir les logs de PostgreSQL  
docker logs listmonk-postgres

# Redémarrer Listmonk
docker restart listmonk-app

# Arrêter tous les services
docker compose -f docker-compose.postgres-fixed.yml down
```

### Sauvegarde des Données
```bash
# Sauvegarder la base de données
docker exec listmonk-postgres pg_dump -U listmonk listmonk > backup_listmonk.sql

# Restaurer la base de données
docker exec -i listmonk-postgres psql -U listmonk listmonk < backup_listmonk.sql
```

## 📈 REQUÊTES UTILES

### Statistiques par Région
```sql
SELECT 
  attribs->'geo'->>'region' as region,
  COUNT(*) as nb_abonnes
FROM subscribers 
WHERE attribs ? 'geo'
GROUP BY attribs->'geo'->>'region'
ORDER BY nb_abonnes DESC;
```

### Statistiques par Département
```sql
SELECT 
  attribs->'geo'->>'departement_nom' as departement,
  COUNT(*) as nb_abonnes
FROM subscribers 
WHERE attribs ? 'geo'
GROUP BY attribs->'geo'->>'departement_nom'
ORDER BY nb_abonnes DESC;
```

### Répartition par CSP
```sql
SELECT 
  attribs->>'csp' as csp,
  COUNT(*) as nb_abonnes
FROM subscribers 
WHERE attribs ? 'csp'
GROUP BY attribs->>'csp'
ORDER BY nb_abonnes DESC;
```

## 🎨 CRÉATION DE CAMPAGNES GÉOGRAPHIQUES

### 1. Campagne Régionale
1. Aller dans **Campagnes** → **Nouvelle campagne**
2. Dans **Listes**, créer une nouvelle liste avec le filtre :
   ```sql
   attribs->>'geo'->>'region' = 'Île-de-France'
   ```
3. Personnaliser le contenu avec des références géographiques

### 2. Campagne par CSP
1. Créer une liste avec le filtre :
   ```sql
   attribs->>'csp' = 'Cadre'
   ```
2. Adapter le message au profil professionnel

### 3. Campagne Locale
1. Créer une liste avec le filtre :
   ```sql
   attribs->>'geo'->>'departement' = '75' 
   AND attribs->>'geo'->>'commune' = 'Paris'
   ```
2. Inclure des informations locales pertinentes

## 📝 IMPORT CSV AVEC DONNÉES GÉOGRAPHIQUES

Format CSV recommandé :
```csv
email,name,region,departement,departement_nom,commune,code_insee,code_postal,csp,age
user@example.com,Nom Utilisateur,Île-de-France,75,Paris,Paris,75056,75001,Cadre,35
```

Script d'import (à adapter) :
```sql
INSERT INTO subscribers (uuid, email, name, attribs, status) 
VALUES (
  gen_random_uuid(),
  'email@example.com',
  'Nom Complet',
  '{"geo": {"region": "Région", "departement": "XX", "departement_nom": "Nom Dept", "commune": "Ville", "code_insee": "XXXXX", "code_postal": "XXXXX"}, "csp": "CSP", "age": XX}',
  'enabled'
);
```

## 🔍 DÉPANNAGE

### Listmonk ne démarre pas
```bash
# Vérifier les logs
docker logs listmonk-app

# Redémarrer
docker restart listmonk-app
```

### Base de données inaccessible
```bash
# Vérifier PostgreSQL
docker logs listmonk-postgres

# Tester la connexion
docker exec listmonk-postgres pg_isready -U listmonk -d listmonk
```

### Interface web inaccessible
1. Vérifier que le port 9000 est libre
2. Attendre quelques minutes après le démarrage
3. Vérifier les logs : `docker logs listmonk-app`

## 🎉 PROCHAINES ÉTAPES

1. **Créer vos premières listes géographiques**
2. **Importer vos données avec les attributs géographiques**
3. **Tester les campagnes ciblées par région/département**
4. **Analyser les performances par zone géographique**

## 📞 SUPPORT

Pour toute question ou problème :
1. Consulter les logs Docker
2. Vérifier la documentation Listmonk officielle
3. Tester les requêtes SQL dans Adminer

---

## 🏆 RÉSUMÉ DE L'INSTALLATION

✅ **PostgreSQL 17** installé et configuré  
✅ **Listmonk 5.0.2** installé avec succès  
✅ **94 départements français** chargés  
✅ **Tables de référence géographique** créées  
✅ **5 abonnés d'exemple** avec données géographiques  
✅ **Interface web** accessible sur http://localhost:9000  
✅ **Interface admin DB** accessible sur http://localhost:8080  

**🎯 L'extension géographique française pour Listmonk est opérationnelle !**

Bon marketing géographique ! 🚀🗺️