# 🔧 Solution Rapide - Conflits de Ports

## ❌ Problème Détecté
```
failed to bind host port for 0.0.0.0:5432 - address already in use
failed to bind host port for 0.0.0.0:8080 - address already in use
```

## ⚡ Solution Automatique (Recommandée)

```bash
# Exécuter le script de correction automatique
./fix-port-conflicts.sh
```

Ce script va :
- ✅ Détecter automatiquement les ports libres
- ✅ Créer une configuration Docker adaptée
- ✅ Redémarrer les services avec les nouveaux ports
- ✅ Vous donner les nouvelles URLs d'accès

## 🔧 Solution Manuelle

### 1. Arrêter les Services Conflictuels

```bash
# Identifier les services qui utilisent les ports
sudo netstat -tulpn | grep -E ':(5432|8080|9000)'

# Arrêter PostgreSQL système (si installé)
sudo systemctl stop postgresql

# Arrêter Apache/Nginx sur port 8080 (si applicable)
sudo systemctl stop apache2
# ou
sudo systemctl stop nginx
```

### 2. Modifier les Ports dans Docker

Éditez le fichier `docker-compose.simple.yml` :

```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # Changer 5432 en 5433
  
  listmonk:
    ports:
      - "9001:9000"  # Changer 9000 en 9001
  
  adminer:
    ports:
      - "8081:8080"  # Changer 8080 en 8081
```

### 3. Redémarrer avec les Nouveaux Ports

```bash
# Arrêter les services existants
docker-compose -f docker-compose.simple.yml down

# Redémarrer avec la nouvelle configuration
docker-compose -f docker-compose.simple.yml up -d
```

## 🌐 Nouveaux Accès

Avec les ports modifiés :
- **Listmonk** : http://localhost:9001
- **Adminer** : http://localhost:8081
- **PostgreSQL** : localhost:5433

## 🚀 Solution Express (Une Ligne)

```bash
# Arrêter les services système et utiliser la correction automatique
sudo systemctl stop postgresql apache2 nginx 2>/dev/null; ./fix-port-conflicts.sh
```

## ✅ Vérification

```bash
# Vérifier que les services fonctionnent
curl http://localhost:9001/health

# Voir les logs
docker-compose -f docker-compose.ports-fixed.yml logs -f
```

---

**💡 Conseil :** Utilisez `./fix-port-conflicts.sh` pour une résolution automatique et sans effort !