#!/bin/bash

echo "🔧 CORRECTION DES ERREURS ESLINT"
echo "================================="

cd frontend

# Corriger automatiquement les erreurs ESLint
echo "ℹ️ Correction automatique des erreurs ESLint..."
npx eslint --ext .js,.vue src --fix

echo "✅ Corrections ESLint appliquées"

# Tenter le build
echo "ℹ️ Tentative de build..."
npm run build

echo "✅ Build terminé"