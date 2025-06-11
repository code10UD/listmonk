# 🔧 Guide de Dépannage - Listmonk Géographique

## ❌ Problèmes Courants et Solutions

### 1. Erreur "dial tcp: lookup postgres on 127.0.0.11:53: server misbehaving"

**Problème :** Le conteneur Listmonk ne peut pas résoudre le nom d'hôte `postgres`.

**Causes possibles :**
- Réseau Docker mal configuré
- Conteneurs pas sur le même réseau
- PostgreSQL pas complètement démarré

**Solutions :**

#### Solution A : Vérifier le réseau Docker
```bash
# Lister les réseaux Docker
docker network ls

# Vérifier que le réseau existe
docker network inspect listmonk-geo_listmonk-network

# Si le réseau n'existe pas, le créer
docker network create listmonk-geo_listmonk-network
```

#### Solution B : Redémarrer l'installation
```bash
# Nettoyer complètement
docker compose -f docker-compose.postgres-fixed.yml down -v
docker system prune -f

# Relancer l'installation
./install-simple.sh
```

#### Solution C : Attendre plus longtemps PostgreSQL
```bash
# Modifier le script pour attendre plus longtemps
# Dans install-simple.sh, ligne 42, changer {1..30} en {1..60}
for i in {1..60}; do
```

### 2. Erreur "Container listmonk-postgres not found"

**Problème :** Le conteneur PostgreSQL n'est pas démarré.

**Solution :**
```bash
# Vérifier les conteneurs
docker ps -a

# Démarrer PostgreSQL manuellement
docker compose -f docker-compose.postgres-fixed.yml up -d postgres

# Attendre qu'il soit prêt
docker compose -f docker-compose.postgres-fixed.yml exec postgres pg_isready -U listmonk -d listmonk
```

### 3. Listmonk ne démarre pas

**Problème :** Le conteneur Listmonk ne démarre pas ou crash.

**Solutions :**

#### Vérifier les logs
```bash
# Voir les logs du conteneur
docker logs listmonk-app

# Ou si utilisation de docker-compose
docker compose -f docker-compose.postgres-fixed.yml logs listmonk
```

#### Vérifier la configuration
```bash
# Vérifier que le fichier config existe
ls -la /tmp/listmonk-install-config.toml

# Vérifier le contenu
cat /tmp/listmonk-install-config.toml
```

#### Redémarrer Listmonk
```bash
# Arrêter le conteneur
docker stop listmonk-app
docker rm listmonk-app

# Relancer avec le script
./install-simple.sh
```

### 4. Interface Listmonk inaccessible (http://localhost:9000)

**Problème :** L'interface web ne répond pas.

**Solutions :**

#### Vérifier que le port est libre
```bash
# Vérifier les ports utilisés
netstat -tlnp | grep 9000
# ou
ss -tlnp | grep 9000
```

#### Vérifier le mapping de port
```bash
# Vérifier que le conteneur expose le bon port
docker port listmonk-app
```

#### Tester avec curl
```bash
# Tester la santé de l'application
curl http://localhost:9000/health

# Si ça ne marche pas, essayer l'IP du conteneur
docker inspect listmonk-app | grep IPAddress
curl http://[IP_CONTAINER]:9000/health
```

### 5. Erreurs de base de données

**Problème :** Erreurs SQL ou connexion base de données.

**Solutions :**

#### Vérifier PostgreSQL
```bash
# Se connecter à PostgreSQL
docker compose -f docker-compose.postgres-fixed.yml exec postgres psql -U listmonk -d listmonk

# Vérifier les tables
\dt

# Vérifier les données
SELECT COUNT(*) FROM subscribers;
SELECT COUNT(*) FROM departements_france;
```

#### Réinitialiser la base
```bash
# Supprimer les volumes
docker compose -f docker-compose.postgres-fixed.yml down -v

# Relancer l'installation
./install-simple.sh
```

### 6. Filtres géographiques ne fonctionnent pas

**Problème :** Les requêtes géographiques retournent des erreurs.

**Solutions :**

#### Vérifier les colonnes géographiques
```bash
docker compose -f docker-compose.postgres-fixed.yml exec postgres psql -U listmonk -d listmonk -c "\d subscribers"
```

#### Vérifier les données
```bash
docker compose -f docker-compose.postgres-fixed.yml exec postgres psql -U listmonk -d listmonk -c "SELECT email, region, departement_numero FROM subscribers WHERE region IS NOT NULL;"
```

#### Appliquer les corrections
```bash
# Exécuter le script de correction
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk < fix-geographic-interface.sql
```

### 7. Permissions Docker

**Problème :** Erreurs de permissions Docker.

**Solutions :**

#### Ajouter l'utilisateur au groupe docker
```bash
sudo usermod -aG docker $USER
newgrp docker
```

#### Utiliser sudo temporairement
```bash
sudo ./install-simple.sh
```

### 8. Espace disque insuffisant

**Problème :** Erreur d'espace disque.

**Solutions :**

#### Nettoyer Docker
```bash
# Nettoyer les images inutilisées
docker system prune -a

# Nettoyer les volumes
docker volume prune
```

#### Vérifier l'espace
```bash
df -h
docker system df
```

---

## 🔍 Commandes de Diagnostic

### Vérification Complète du Système

```bash
#!/bin/bash
echo "=== DIAGNOSTIC LISTMONK GÉOGRAPHIQUE ==="

echo "1. État des conteneurs :"
docker ps -a

echo "2. État des réseaux :"
docker network ls

echo "3. État des volumes :"
docker volume ls

echo "4. Test PostgreSQL :"
docker compose -f docker-compose.postgres-fixed.yml exec postgres pg_isready -U listmonk -d listmonk

echo "5. Test Listmonk :"
curl -s http://localhost:9000/health || echo "Listmonk inaccessible"

echo "6. Logs PostgreSQL (dernières 10 lignes) :"
docker compose -f docker-compose.postgres-fixed.yml logs --tail=10 postgres

echo "7. Logs Listmonk (dernières 10 lignes) :"
docker logs --tail=10 listmonk-app 2>/dev/null || echo "Conteneur listmonk-app introuvable"

echo "8. Données géographiques :"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) as departements FROM departements_france; SELECT COUNT(*) as abonnes_geo FROM subscribers WHERE region IS NOT NULL;" 2>/dev/null || echo "Erreur base de données"
```

### Test des Filtres Géographiques

```bash
#!/bin/bash
echo "=== TEST FILTRES GÉOGRAPHIQUES ==="

# Test filtres simples
echo "Test 1: Filtrage par région"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE region = 'Île-de-France';"

echo "Test 2: Filtrage par département"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE departement_numero = '75';"

echo "Test 3: Filtrage par CSP"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers WHERE csp = 'Cadre';"

echo "Test 4: Vue prédéfinie"
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM abonnes_ile_de_france;"
```

---

## 🚨 Procédure de Récupération d'Urgence

Si tout va mal, voici la procédure complète de récupération :

### 1. Nettoyage Complet
```bash
# Arrêter tous les conteneurs
docker stop $(docker ps -aq) 2>/dev/null || true

# Supprimer tous les conteneurs
docker rm $(docker ps -aq) 2>/dev/null || true

# Supprimer les volumes
docker volume prune -f

# Supprimer les réseaux
docker network prune -f

# Nettoyer le système
docker system prune -a -f
```

### 2. Réinstallation Propre
```bash
# Cloner à nouveau le dépôt
cd /tmp
git clone -b feature/french-geographic-segmentation https://github.com/code8UD/listmonk.git listmonk-clean
cd listmonk-clean

# Lancer l'installation
chmod +x install-simple.sh
./install-simple.sh
```

### 3. Validation
```bash
# Tester l'installation
chmod +x test-installation.sh
./test-installation.sh
```

---

## 📞 Support

Si les problèmes persistent :

1. **Vérifiez les prérequis :**
   - Docker installé et fonctionnel
   - Ports 9000 et 5432 libres
   - Espace disque suffisant (>2GB)

2. **Collectez les informations :**
   - Version de Docker : `docker --version`
   - Système d'exploitation : `uname -a`
   - Logs complets : `docker logs listmonk-app`

3. **Consultez la documentation :**
   - `SOLUTION_FINALE_LISTMONK.md`
   - `GUIDE_UTILISATION_SIMPLE.md`

**L'extension géographique Listmonk est robuste et testée. La plupart des problèmes sont liés à la configuration Docker ou aux permissions système.** 🛠️