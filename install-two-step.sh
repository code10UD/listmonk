#!/bin/bash

# Installation en deux étapes pour Listmonk avec extension géographique
set -e

echo "🗺️ INSTALLATION LISTMONK EN DEUX ÉTAPES"
echo "========================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Étape 1: Démarrer PostgreSQL
print_status "Étape 1: Démarrage de PostgreSQL..."
docker compose -f docker-compose.postgres-fixed.yml up -d postgres

# Attendre PostgreSQL
print_status "Attente de PostgreSQL..."
for i in {1..30}; do
    if docker compose -f docker-compose.postgres-fixed.yml exec postgres pg_isready -U listmonk -d listmonk &>/dev/null; then
        print_success "PostgreSQL est prêt"
        break
    fi
    
    if [ $i -eq 30 ]; then
        print_error "Timeout - PostgreSQL ne répond pas"
        exit 1
    fi
    
    echo -n "."
    sleep 2
done

# Étape 2: Installation Listmonk standard (sans colonnes géographiques)
print_status "Étape 2: Installation Listmonk standard..."

# Créer un fichier de configuration temporaire pour l'installation
cat > /tmp/listmonk-install-config.toml << EOF
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "admin123"

[db]
host = "postgres"
port = 5432
user = "listmonk"
password = "listmonk_secure_password"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"

[smtp]
[[smtp.host]]
enabled = false
host = "localhost"
port = 587
auth_protocol = "cram"
username = ""
password = ""
hello_hostname = ""
max_conns = 10
idle_timeout = "15s"
wait_timeout = "5s"
max_msg_retries = 2
tls_enabled = true
tls_skip_verify = false

[upload]
provider = "filesystem"
filesystem.upload_path = "uploads"
filesystem.upload_uri = "/uploads"

[privacy]
individual_tracking = false
unsubscribe_header = true
allow_blocklist = true
allow_export = true
allow_wipe = true
exportable = ["profile", "subscriptions", "campaign_views", "link_clicks"]

[media]
upload.provider = "filesystem"
upload.filesystem.upload_path = "uploads"
upload.filesystem.upload_uri = "/uploads"
EOF

# Utiliser l'image officielle de Listmonk pour l'installation initiale
docker run --rm --network listmonk_listmonk-network \
    -v /tmp/listmonk-install-config.toml:/listmonk/config.toml \
    listmonk/listmonk:latest \
    ./listmonk --install --yes

print_success "Installation Listmonk standard terminée"

# Étape 3: Ajouter les colonnes géographiques
print_status "Étape 3: Ajout des colonnes géographiques..."

# Exécuter le script d'ajout des colonnes géographiques
docker compose -f docker-compose.postgres-fixed.yml exec -T postgres psql -U listmonk -d listmonk << 'EOF'
-- Ajouter les colonnes géographiques à la table subscribers
DO $$
BEGIN
    -- Colonnes géographiques de base
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='code_insee') THEN
        ALTER TABLE subscribers ADD COLUMN code_insee VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='departement_numero') THEN
        ALTER TABLE subscribers ADD COLUMN departement_numero VARCHAR(3);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='departement_nom') THEN
        ALTER TABLE subscribers ADD COLUMN departement_nom VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='region_nom') THEN
        ALTER TABLE subscribers ADD COLUMN region_nom VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='commune_nom') THEN
        ALTER TABLE subscribers ADD COLUMN commune_nom VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='population_commune') THEN
        ALTER TABLE subscribers ADD COLUMN population_commune INTEGER;
    END IF;
    
    -- Colonnes adresse
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='adresse_numero') THEN
        ALTER TABLE subscribers ADD COLUMN adresse_numero VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='adresse_voie') THEN
        ALTER TABLE subscribers ADD COLUMN adresse_voie VARCHAR(200);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='adresse_complement') THEN
        ALTER TABLE subscribers ADD COLUMN adresse_complement VARCHAR(200);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='code_postal') THEN
        ALTER TABLE subscribers ADD COLUMN code_postal VARCHAR(10);
    END IF;
    
    -- Colonnes démographiques
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='date_naissance') THEN
        ALTER TABLE subscribers ADD COLUMN date_naissance DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='csp') THEN
        ALTER TABLE subscribers ADD COLUMN csp VARCHAR(50);
    END IF;
    
    -- Colonnes entreprise
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='siren') THEN
        ALTER TABLE subscribers ADD COLUMN siren VARCHAR(9);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='siret') THEN
        ALTER TABLE subscribers ADD COLUMN siret VARCHAR(14);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='secteur_activite') THEN
        ALTER TABLE subscribers ADD COLUMN secteur_activite VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='taille_entreprise') THEN
        ALTER TABLE subscribers ADD COLUMN taille_entreprise VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='chiffre_affaires') THEN
        ALTER TABLE subscribers ADD COLUMN chiffre_affaires BIGINT;
    END IF;
END $$;

-- Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_subscribers_code_insee ON subscribers(code_insee);
CREATE INDEX IF NOT EXISTS idx_subscribers_departement ON subscribers(departement_numero);
CREATE INDEX IF NOT EXISTS idx_subscribers_region ON subscribers(region_nom);
CREATE INDEX IF NOT EXISTS idx_subscribers_commune ON subscribers(commune_nom);
CREATE INDEX IF NOT EXISTS idx_subscribers_code_postal ON subscribers(code_postal);
CREATE INDEX IF NOT EXISTS idx_subscribers_csp ON subscribers(csp);
EOF

print_success "Colonnes géographiques ajoutées"

# Étape 4: Charger les données géographiques françaises
print_status "Étape 4: Chargement des données géographiques françaises..."
./add-geo-columns.sh

# Étape 5: Démarrer Listmonk avec extension géographique
print_status "Étape 5: Démarrage de Listmonk avec extension géographique..."
docker compose -f docker-compose.postgres-fixed.yml up -d listmonk

print_status "Attente du démarrage de Listmonk..."
sleep 15

# Vérifier que Listmonk fonctionne
if curl -f http://localhost:9000/health &>/dev/null; then
    print_success "Listmonk est accessible sur http://localhost:9000"
else
    print_warning "Listmonk n'est pas encore accessible (peut nécessiter quelques minutes)"
fi

echo ""
echo "🎉 INSTALLATION TERMINÉE !"
echo "========================="
echo ""
echo "✅ Listmonk avec extension géographique française est installé"
echo ""
echo "📋 INFORMATIONS D'ACCÈS :"
echo "🌐 Interface Listmonk : http://localhost:9000"
echo "👤 Nom d'utilisateur  : admin"
echo "🔑 Mot de passe       : admin123"
echo ""
echo "🗄️ Interface Adminer : http://localhost:8080"
echo "   Serveur    : postgres"
echo "   Utilisateur: listmonk"
echo "   Mot de passe: listmonk_secure_password"
echo "   Base       : listmonk"
echo ""
echo "🚀 Bon marketing géographique avec Listmonk !"