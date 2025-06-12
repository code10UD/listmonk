#!/bin/bash

echo "🔧 CORRECTION BINDING ADDRESS - 0.0.0.0:9000"
echo "============================================"

echo "1. Arrêt des containers..."
docker-compose down

echo "2. Mise à jour du docker-compose.yml avec binding 0.0.0.0..."
cat > docker-compose.yml << 'EOF'
version: '3.7'
services:
  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_USER: postgres
      POSTGRES_DB: listmonk
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  app:
    image: listmonk/listmonk:latest
    depends_on:
      - db
    environment:
      LISTMONK_app__address: "0.0.0.0:9000"
      LISTMONK_db__host: db
      LISTMONK_db__port: 5432
      LISTMONK_db__user: postgres
      LISTMONK_db__password: password
      LISTMONK_db__database: listmonk
      LISTMONK_db__ssl_mode: disable
    ports:
      - "9000:9000"
    volumes:
      - ./uploads:/listmonk/uploads

volumes:
  db_data:
EOF

echo "3. Redémarrage avec binding 0.0.0.0..."
docker-compose up -d

echo "4. Attente du démarrage..."
sleep 10

echo "5. Vérification du binding..."
docker-compose logs app | grep "http server started"

echo ""
echo "✅ CORRECTION TERMINÉE"
echo "====================="
echo "🌐 Application accessible sur : http://0.0.0.0:9000"
echo "🌐 Accessible depuis l'extérieur : http://VOTRE_IP:9000"