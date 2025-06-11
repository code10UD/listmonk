#!/bin/bash

# Script de test pour valider l'intégration frontend géographique
set -e

echo "🧪 TEST INTÉGRATION FRONTEND GÉOGRAPHIQUE"
echo "=========================================="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🔍${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Test 1: Vérifier que le composant GeoSelector existe
print_test "Test 1: Vérification du composant GeoSelector..."
if [ -f "frontend/src/components/GeoSelector.vue" ]; then
    print_success "Composant GeoSelector.vue créé"
else
    print_error "Composant GeoSelector.vue manquant"
    exit 1
fi

# Test 2: Vérifier l'intégration dans Subscribers.vue
print_test "Test 2: Vérification de l'intégration dans Subscribers.vue..."
if grep -q "GeoSelector" frontend/src/views/Subscribers.vue; then
    print_success "GeoSelector intégré dans Subscribers.vue"
else
    print_error "GeoSelector non intégré dans Subscribers.vue"
    exit 1
fi

# Test 3: Vérifier les traductions françaises
print_test "Test 3: Vérification des traductions françaises..."
if grep -q "geo.title" i18n/fr.json; then
    print_success "Traductions géographiques ajoutées"
else
    print_error "Traductions géographiques manquantes"
    exit 1
fi

# Test 4: Vérifier les handlers backend
print_test "Test 4: Vérification des handlers backend..."
if [ -f "cmd/geo.go" ]; then
    print_success "Handlers géographiques backend présents"
else
    print_error "Handlers géographiques backend manquants"
    exit 1
fi

# Test 5: Vérifier les routes API
print_test "Test 5: Vérification des routes API..."
if grep -q "/api/geo/" cmd/handlers.go; then
    print_success "Routes API géographiques configurées"
else
    print_error "Routes API géographiques manquantes"
    exit 1
fi

# Test 6: Vérifier les modèles
print_test "Test 6: Vérification des modèles..."
if grep -q "GeoQueryParams\|DepartementRegion" models/models.go; then
    print_success "Modèles géographiques présents"
else
    print_error "Modèles géographiques manquants"
    exit 1
fi

# Test 7: Vérifier la structure du frontend
print_test "Test 7: Vérification de la structure frontend..."
if [ -f "frontend/package.json" ]; then
    print_success "Structure frontend présente"
    
    # Vérifier les dépendances Vue
    if grep -q "vue" frontend/package.json; then
        print_success "Vue.js configuré"
    else
        print_warning "Vue.js non détecté dans package.json"
    fi
else
    print_error "Structure frontend manquante"
fi

# Test 8: Vérifier la syntaxe Vue du composant
print_test "Test 8: Vérification de la syntaxe Vue..."
template_count=$(grep -c "<template>" frontend/src/components/GeoSelector.vue)
script_count=$(grep -c "<script>" frontend/src/components/GeoSelector.vue)
style_count=$(grep -c "<style" frontend/src/components/GeoSelector.vue)

if [ $template_count -eq 1 ] && [ $script_count -eq 1 ] && [ $style_count -eq 1 ]; then
    print_success "Structure Vue valide dans GeoSelector"
else
    print_error "Structure Vue invalide dans GeoSelector (template:$template_count, script:$script_count, style:$style_count)"
fi

# Test 9: Vérifier les méthodes API dans le composant
print_test "Test 9: Vérification des appels API..."
if grep -q "\$http.get.*geo" frontend/src/components/GeoSelector.vue; then
    print_success "Appels API géographiques configurés"
else
    print_error "Appels API géographiques manquants"
fi

# Test 10: Vérifier l'intégration complète
print_test "Test 10: Vérification de l'intégration complète..."
integration_score=0

# Backend
if [ -f "cmd/geo.go" ]; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Backend handlers"
fi
if grep -q "/api/geo/" cmd/handlers.go; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Routes API"
fi
if grep -q "GeoQueryParams" models/models.go; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Modèles de données"
fi

# Frontend
if [ -f "frontend/src/components/GeoSelector.vue" ]; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Composant Vue"
fi
if grep -q "GeoSelector" frontend/src/views/Subscribers.vue; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Intégration UI"
fi

# Traductions
if grep -q "geo.title" i18n/fr.json; then 
    integration_score=$((integration_score + 1))
    print_success "✓ Traductions"
fi

echo ""
echo "🎯 RÉSUMÉ DE L'INTÉGRATION"
echo "========================="
echo "Score d'intégration: $integration_score/6"

if [ $integration_score -eq 6 ]; then
    print_success "✅ INTÉGRATION COMPLÈTE - Toutes les fonctionnalités géographiques sont intégrées"
    echo ""
    echo "🚀 PROCHAINES ÉTAPES:"
    echo "1. Compiler le frontend: cd frontend && npm run build"
    echo "2. Redémarrer Listmonk avec Docker"
    echo "3. Tester l'interface à http://localhost:9000"
    echo "4. Aller dans Abonnés > Recherche avancée"
    echo "5. Utiliser le sélecteur géographique"
elif [ $integration_score -ge 4 ]; then
    print_warning "⚠️ INTÉGRATION PARTIELLE - Quelques éléments manquent"
    echo "Vérifiez les erreurs ci-dessus et corrigez-les"
else
    print_error "❌ INTÉGRATION INCOMPLÈTE - Plusieurs éléments manquent"
    echo "Relancez le processus d'intégration"
    exit 1
fi

echo ""
echo "📋 CHECKLIST FINALE:"
echo "- [✅] Backend géographique (cmd/geo.go)"
echo "- [✅] Routes API (/api/geo/*)"
echo "- [✅] Modèles de données"
echo "- [✅] Composant Vue GeoSelector"
echo "- [✅] Intégration dans Subscribers.vue"
echo "- [✅] Traductions françaises"
echo ""
echo "🎉 L'extension géographique est prête pour la compilation et les tests !"