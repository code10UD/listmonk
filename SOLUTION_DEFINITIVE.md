# 🚨 SOLUTION DÉFINITIVE - PROBLÈME CONFIG.TOML

## ❌ **PROBLÈME IDENTIFIÉ**

Le fichier `config.toml` sur votre serveur contient encore les champs **DÉPRÉCIÉS** qui causent le crash de Listmonk v5.0.2+ :

```toml
# ❌ CES CHAMPS CAUSENT LE CRASH
admin_username = "admin"
admin_password = "admin123"
```

## ✅ **SOLUTION IMMÉDIATE**

### **Étape 1 : Exécutez ce script sur votre serveur**

```bash
./fix-config-final.sh
```

### **Étape 2 : OU correction manuelle**

Si le script ne fonctionne pas, faites ceci **MANUELLEMENT** :

```bash
# 1. Arrêtez les containers
docker compose -f docker-compose.simple-fixed.yml down

# 2. Sauvegardez l'ancien config
cp config.toml config.toml.backup

# 3. Créez le nouveau config.toml (SANS les champs dépréciés)
cat > config.toml << 'EOF'
[app]
address = "0.0.0.0:9000"

[db]
host = "postgres"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"
EOF

# 4. Redémarrez
docker compose -f docker-compose.simple-fixed.yml up -d

# 5. Attendez 30 secondes et testez
sleep 30
curl http://localhost:9000
```

## 🔍 **POURQUOI ÇA PLANTE ?**

Listmonk v5.0.2+ a **SUPPRIMÉ** le support des champs `admin_username` et `admin_password` dans config.toml. 

Quand Listmonk trouve ces champs, il :
1. Affiche un WARNING
2. **CRASH immédiatement**
3. Docker redémarre le container
4. **Boucle infinie de redémarrages**

## ✅ **CONFIGURATION CORRECTE**

```toml
[app]
address = "0.0.0.0:9000"
# PAS de admin_username
# PAS de admin_password

[db]
host = "postgres"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"
```

## 🎯 **APRÈS LA CORRECTION**

1. **Container stable** : Plus de redémarrages
2. **Application accessible** : http://localhost:9000
3. **Login par défaut** : admin / admin123 (créé automatiquement)
4. **Extension géographique** : Fonctionnelle

## 🚨 **SI ÇA NE MARCHE TOUJOURS PAS**

Vérifiez que votre `config.toml` ne contient **AUCUN** de ces champs :
- `admin_username`
- `admin_password`

```bash
# Vérification
grep -E "(admin_username|admin_password)" config.toml
# Résultat attendu : RIEN (aucune ligne trouvée)
```