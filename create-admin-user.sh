#!/bin/bash

echo "🔐 CRÉATION DU COMPTE ADMINISTRATEUR"
echo "===================================="

# Attendre que l'application soit prête
echo "⏳ Attente que l'application soit prête..."
sleep 10

# Vérifier que l'application répond
echo "🌐 Test de connectivité..."
if curl -s -f http://localhost:9000 > /dev/null; then
    echo "✅ Application accessible"
else
    echo "❌ Application non accessible, attente supplémentaire..."
    sleep 10
fi

# Création du compte admin via l'API REST
echo "👤 Création du compte administrateur..."

# Première tentative : vérifier si un admin existe déjà
ADMIN_EXISTS=$(curl -s -X POST http://localhost:9000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"listmonk"}' | grep -o "success" || echo "not_found")

if [ "$ADMIN_EXISTS" = "success" ]; then
    echo "✅ Compte admin déjà configuré (admin/listmonk)"
else
    echo "🔧 Configuration du compte admin..."
    
    # Tentative de création via l'installation
    docker-compose exec app ./listmonk --install --yes --config /dev/null << 'EOF'
admin
listmonk
EOF

    # Vérification
    sleep 5
    ADMIN_CHECK=$(curl -s -X POST http://localhost:9000/api/admin/login \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"listmonk"}' | grep -o "success" || echo "failed")
    
    if [ "$ADMIN_CHECK" = "success" ]; then
        echo "✅ Compte admin créé avec succès"
    else
        echo "⚠️ Création automatique échouée, utilisez l'interface web"
        echo "   Allez sur http://localhost:9000 pour configurer le compte"
    fi
fi

echo ""
echo "🎯 INFORMATIONS DE CONNEXION"
echo "============================"
echo "🌐 URL : http://localhost:9000"
echo "👤 Username : admin"
echo "🔑 Password : listmonk"
echo ""
echo "Si la connexion échoue, allez sur l'interface web pour créer le compte."