#!/bin/bash

echo "🔧 CORRECTION DÉFINITIVE DU FICHIER CONFIG.TOML"
echo "==============================================="

# Arrêt de tous les containers
echo "ℹ️ Arrêt des containers..."
docker compose -f docker-compose.simple-fixed.yml down

# Sauvegarde de l'ancien config.toml
if [ -f "config.toml" ]; then
    echo "ℹ️ Sauvegarde de l'ancien config.toml..."
    cp config.toml config.toml.backup
fi

# Création du nouveau config.toml SANS les champs dépréciés
echo "ℹ️ Création du nouveau config.toml..."
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

echo "✅ Nouveau config.toml créé"

# Vérification du contenu
echo "ℹ️ Contenu du nouveau config.toml:"
cat config.toml

# Redémarrage avec la nouvelle configuration
echo ""
echo "ℹ️ Redémarrage avec la configuration corrigée..."
docker compose -f docker-compose.simple-fixed.yml up -d

# Attente et vérification
echo "ℹ️ Attente du démarrage (30 secondes)..."
sleep 30

echo ""
echo "📋 Statut des containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep listmonk

echo ""
echo "📋 Logs de l'application (dernières 10 lignes):"
docker logs listmonk-app --tail 10

echo ""
echo "🌐 Test d'accès HTTP:"
curl -s -o /dev/null -w "Status HTTP: %{http_code}\n" http://localhost:9000

echo ""
echo "🎉 CORRECTION TERMINÉE !"
echo "========================"
echo "✅ Fichier config.toml corrigé (champs dépréciés supprimés)"
echo "✅ Application redémarrée avec la nouvelle configuration"
echo ""
echo "📱 Si l'application fonctionne:"
echo "   • URL: http://localhost:9000"
echo "   • Login: admin / admin123"