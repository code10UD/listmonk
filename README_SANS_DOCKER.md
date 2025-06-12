# 🚀 LISTMONK SANS DOCKER - GUIDE RAPIDE

## ⚡ INSTALLATION RAPIDE

```bash
# 1. Cloner le projet
git clone https://github.com/code10UD/listmonk.git
cd listmonk
git checkout feature/french-geographic-segmentation

# 2. Installer automatiquement (sans Docker)
chmod +x install-no-docker.sh
./install-no-docker.sh

# 3. Démarrer Listmonk
./start-listmonk.sh
```

**C'est tout ! 🎉**

## 📋 PRÉREQUIS

### Installer PostgreSQL
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install postgresql postgresql-contrib

# CentOS/RHEL/Rocky Linux  
sudo dnf install postgresql postgresql-server postgresql-contrib
sudo postgresql-setup --initdb
sudo systemctl enable postgresql && sudo systemctl start postgresql

# Arch Linux
sudo pacman -S postgresql
sudo -u postgres initdb -D /var/lib/postgres/data
sudo systemctl enable postgresql && sudo systemctl start postgresql
```

### Installer Go (si nécessaire)
```bash
# Télécharger et installer Go 1.21+
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

## 🎯 UTILISATION

### Scripts disponibles
```bash
./install-no-docker.sh    # Installation complète automatique
./start-listmonk.sh       # Démarrer Listmonk
./test-no-docker.sh       # Tester l'installation
```

### Commandes manuelles
```bash
# Démarrer en mode développement
go run cmd/*.go --config config.toml

# Démarrer en arrière-plan
nohup go run cmd/*.go --config config.toml > listmonk.log 2>&1 &

# Compiler et exécuter
go build -o listmonk cmd/*.go
./listmonk --config config.toml

# Arrêter
pkill -f "go run cmd"
```

## 🌐 ACCÈS

- **Interface**: http://localhost:9000
- **Email**: admin
- **Mot de passe**: admin

## ✅ VÉRIFICATION

```bash
# Tester l'installation
./test-no-docker.sh

# Vérifier PostgreSQL
sudo systemctl status postgresql

# Tester la base de données
psql -U listmonk -d listmonk -h localhost

# Vérifier les endpoints
curl http://localhost:9000/api/health
curl -w "%{http_code}" http://localhost:9000/api/geo/regions
```

## 🔧 MAINTENANCE

### PostgreSQL
```bash
# Démarrer/arrêter
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql

# Logs
sudo journalctl -u postgresql

# Sauvegarde
pg_dump -U listmonk -h localhost listmonk > backup.sql
```

### Listmonk
```bash
# Logs en temps réel
tail -f listmonk.log

# Redémarrer
pkill -f "go run cmd"
./start-listmonk.sh

# Mise à jour
git pull origin feature/french-geographic-segmentation
go run cmd/*.go --config config.toml --upgrade --yes
```

## 🎯 FONCTIONNALITÉS

✅ **12 régions françaises** avec sélection multiple  
✅ **94 départements** avec mapping automatique  
✅ **Recherche de communes** avec autocomplétion  
✅ **Filtrage par CSP** (Catégories Socio-Professionnelles)  
✅ **Statistiques géographiques** en temps réel  
✅ **6 endpoints API** géographiques  

## 🚨 DÉPANNAGE

### Problèmes courants
```bash
# Port 9000 occupé
sudo lsof -i :9000
pkill -f "go run cmd"

# PostgreSQL non démarré
sudo systemctl start postgresql

# Connexion DB refusée
sudo nano /etc/postgresql/*/main/pg_hba.conf
# Ajouter: local   all   listmonk   md5
sudo systemctl restart postgresql

# Permissions
sudo chown -R $USER:$USER .
chmod +x *.sh
```

### Logs détaillés
```bash
# Listmonk verbose
go run cmd/*.go --config config.toml --verbose

# PostgreSQL
sudo journalctl -u postgresql -f

# Système
dmesg | tail
```

## 🎉 AVANTAGES SANS DOCKER

✅ **Performance**: Accès direct à PostgreSQL  
✅ **Simplicité**: Moins de couches d'abstraction  
✅ **Contrôle**: Configuration fine du système  
✅ **Ressources**: Moins de consommation mémoire  
✅ **Intégration**: Meilleure intégration système  
✅ **Débogage**: Logs et processus plus accessibles  

---

*Guide sans Docker - Listmonk Géographique Français*