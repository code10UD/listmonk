#!/bin/bash

# Script de correction rapide pour le serveur
echo "🔧 Correction du script d'installation pour votre serveur..."

# Télécharger la version corrigée du script
curl -s https://raw.githubusercontent.com/code10UD/listmonk/feature/french-geographic-segmentation/install-and-test.sh > install-and-test-fixed.sh

# Remplacer l'ancien script
chmod +x install-and-test-fixed.sh
mv install-and-test.sh install-and-test-old.sh
mv install-and-test-fixed.sh install-and-test.sh

echo "✅ Script corrigé ! Vous pouvez maintenant relancer:"
echo "   ./install-and-test.sh"