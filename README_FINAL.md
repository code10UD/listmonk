# 🗺️ Extension Géographique Française pour Listmonk

## ✅ PROBLÈME RÉSOLU - Installation 100% Fonctionnelle

L'erreur `dial tcp: lookup postgres on 127.0.0.11:53: server misbehaving` a été **corrigée** ! 

Le problème venait d'un nom de réseau Docker incorrect dans le script d'installation.

---

## 🚀 Installation en Une Commande

```bash
git clone -b feature/french-geographic-segmentation https://github.com/code8UD/listmonk.git listmonk-geo && cd listmonk-geo && chmod +x install-simple.sh && ./install-simple.sh
```

## 📋 Après l'Installation (2-3 minutes)

- **Interface Listmonk** : http://localhost:9000
  - Identifiants : `admin` / `admin123`
- **Interface Base de Données** : http://localhost:8080
  - Serveur : `postgres`
  - Utilisateur : `listmonk` 
  - Mot de passe : `listmonk_secure_password`
  - Base : `listmonk`

## 🎯 Validation de l'Installation

```bash
# Tester que tout fonctionne
./test-installation.sh
```

---

## 🗺️ Filtres Géographiques Disponibles

### ✅ Filtres Simples (Compatible Interface Listmonk)

```sql
-- Par région
region = 'Île-de-France'
region = 'Provence-Alpes-Côte d''Azur'
region = 'Occitanie'

-- Par département
departement_numero = '75'
departement_numero = '69'
departement_numero = '13'

-- Par commune
commune = 'Paris'
commune = 'Lyon'
commune = 'Marseille'

-- Par CSP
csp = 'Cadre'
csp = 'Employé'
csp = 'Ouvrier'

-- Par âge
age < 30
age > 50
age BETWEEN 25 AND 45
```

### ✅ Filtres Combinés

```sql
-- Cadres en Île-de-France
region = 'Île-de-France' AND csp = 'Cadre'

-- Jeunes dans le Sud
region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie') AND age < 35

-- Employés dans les grandes villes
commune IN ('Paris', 'Lyon', 'Marseille') AND csp = 'Employé'
```

### ✅ Vues Prédéfinies (Ultra-Simple)

```sql
-- Utilisation directe dans Listmonk
SELECT * FROM abonnes_ile_de_france
SELECT * FROM abonnes_cadres
SELECT * FROM abonnes_paris
SELECT * FROM abonnes_grandes_metropoles
```

---

## 📊 Données Disponibles

- **94 départements français** avec données démographiques
- **13 régions françaises**
- **5 abonnés d'exemple** avec données géographiques complètes
- **15+ vues prédéfinies** pour segmentation immédiate

### Exemples d'Abonnés Créés

| Email | Région | Département | Commune | CSP | Âge |
|-------|--------|-------------|---------|-----|-----|
| jean.dupont@example.com | Île-de-France | 75 | Paris | Cadre | 35 |
| marie.martin@example.com | Auvergne-Rhône-Alpes | 69 | Lyon | Employé | 28 |
| pierre.bernard@example.com | Provence-Alpes-Côte d'Azur | 13 | Marseille | Ouvrier | 42 |
| sophie.dubois@example.com | Occitanie | 31 | Toulouse | Profession libérale | 39 |
| antoine.moreau@example.com | Pays de la Loire | 44 | Nantes | Artisan | 33 |

---

## 🎯 Utilisation dans Listmonk

### 1. Créer une Liste Géographique

1. **Aller dans** "Listes" → "Nouvelle liste"
2. **Nom** : "Cadres Parisiens"
3. **Type** : "Privée"
4. **Requête** : `region = 'Île-de-France' AND csp = 'Cadre'`
5. **Sauvegarder**

### 2. Créer une Campagne

1. **Aller dans** "Campagnes" → "Nouvelle campagne"
2. **Sélectionner** votre liste géographique
3. **Personnaliser** le contenu selon la région
4. **Envoyer**

### 3. Exemples de Campagnes

```sql
-- Événement à Lyon
commune = 'Lyon'

-- Promotion Sud de la France
region IN ('Provence-Alpes-Côte d''Azur', 'Occitanie')

-- Ciblage jeunes actifs
age BETWEEN 25 AND 40 AND commune IN ('Paris', 'Lyon', 'Marseille')

-- Départements ruraux
SELECT * FROM abonnes_petits_departements
```

---

## 🛠️ Dépannage

Si vous rencontrez des problèmes :

### 1. Vérification Rapide
```bash
# Vérifier que tout fonctionne
curl http://localhost:9000/health
```

### 2. Diagnostic Complet
```bash
# Lancer le diagnostic
./test-installation.sh
```

### 3. Guide de Dépannage
Consultez `GUIDE_DEPANNAGE.md` pour les solutions aux problèmes courants.

### 4. Réinstallation Propre
```bash
# En cas de problème majeur
docker compose -f docker-compose.postgres-fixed.yml down -v
./install-simple.sh
```

---

## 📚 Documentation Complète

- **`SOLUTION_FINALE_LISTMONK.md`** : Guide d'utilisation détaillé
- **`GUIDE_UTILISATION_SIMPLE.md`** : Filtres et exemples
- **`GUIDE_DEPANNAGE.md`** : Solutions aux problèmes
- **`EXTENSION_GEOGRAPHIQUE_COMPLETE.md`** : Documentation technique

---

## 🎉 Fonctionnalités Clés

### ✅ Segmentation Géographique
- Filtrage par région, département, commune
- Ciblage par CSP et données démographiques
- Vues prédéfinies pour usage immédiat

### ✅ Performance Optimisée
- Index sur toutes les colonnes géographiques
- Requêtes SQL optimisées
- Compatible interface Listmonk native

### ✅ Facilité d'Utilisation
- Filtres simples sans JSON complexe
- Installation automatique en une commande
- Documentation complète et exemples

### ✅ Production Ready
- Basé sur Listmonk officiel v5.0.2
- PostgreSQL 17 avec données françaises
- Scripts de test et validation

---

## 🚀 Prêt pour Production

L'extension géographique française pour Listmonk est maintenant **100% opérationnelle** et prête pour vos campagnes de marketing géographique !

**Commande d'installation :**
```bash
git clone -b feature/french-geographic-segmentation https://github.com/code8UD/listmonk.git listmonk-geo && cd listmonk-geo && ./install-simple.sh
```

**Interface :** http://localhost:9000 (admin/admin123)

**Bon marketing géographique ! 🗺️📧🎯**