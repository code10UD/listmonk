#!/bin/bash

# Script pour créer un utilisateur admin dans Listmonk

set -e

echo "👤 CRÉATION D'UN UTILISATEUR ADMIN"
echo "=================================="

cd "$(dirname "$0")"

# Vérifier que PostgreSQL est en cours
if ! docker ps | grep -q "dev-db-1"; then
    echo "❌ PostgreSQL n'est pas en cours. Démarrez-le d'abord avec:"
    echo "   cd dev && docker-compose up -d db"
    exit 1
fi

echo "👤 Création de l'utilisateur admin..."

# Vérifier les rôles disponibles et créer un utilisateur admin
docker-compose -f dev/docker-compose.yml exec -T db psql -U listmonk-dev -d listmonk-dev << 'EOF'
-- Vérifier les rôles disponibles
SELECT id, name FROM roles ORDER BY id;

-- Insérer un utilisateur admin si il n'existe pas
INSERT INTO users (username, email, name, password, password_login, type, user_role_id, status, created_at, updated_at)
SELECT 
    'admin',
    'admin@listmonk.local',
    'Admin',
    '$2a$10$8.xn/nC8dvko7NDmx4qCa.3UiD/PlqJY1lWgfuVgLOtI6aOLZqUAm', -- password: admin123
    true,
    'user',
    1, -- Utiliser le premier rôle disponible
    'enabled',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'admin@listmonk.local'
);

-- Vérifier que l'utilisateur a été créé
SELECT id, username, email, name, type, status FROM users WHERE email = 'admin@listmonk.local';

\q
EOF

echo "✅ Utilisateur admin créé!"
echo ""
echo "🔑 INFORMATIONS DE CONNEXION :"
echo "   Email    : admin@listmonk.local"
echo "   Password : admin123"
echo ""
echo "🌐 Vous pouvez maintenant vous connecter à :"
echo "   http://localhost:9000/admin"
echo ""