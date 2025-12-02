#!/bin/bash

# 🔔 Script de Test - Notifications Toast Colanode
# Ce script aide à tester le système de notifications de mentions

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔔 Test des Notifications Toast - Colanode          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fonction pour afficher les étapes
step() {
    echo -e "${GREEN}▶${NC} $1"
}

# Fonction pour les warnings
warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Fonction pour les erreurs
error() {
    echo -e "${RED}✗${NC} $1"
}

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé. Veuillez installer Docker d'abord."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    error "docker-compose n'est pas installé. Veuillez installer docker-compose d'abord."
    exit 1
fi

# Menu principal
echo "Choisissez une option de test :"
echo ""
echo "  1) 🚀 Démarrer l'environnement Docker (build local avec modifications)"
echo "  2) ⚡ Démarrer avec images officielles (plus rapide)"
echo "  3) 📊 Voir les logs serveur en temps réel"
echo "  4) 🔍 Chercher les événements de mentions dans les logs"
echo "  5) 🧹 Arrêter et nettoyer l'environnement"
echo "  6) 🖥️  Lancer l'app desktop en mode dev"
echo "  7) 📖 Afficher le guide complet"
echo ""
read -p "Votre choix (1-7) : " choice

case $choice in
    1)
        step "Démarrage de l'environnement avec build local..."
        cd hosting/docker
        docker-compose -f docker-compose.dev.yaml up --build -d
        echo ""
        step "Environnement démarré !"
        echo ""
        echo -e "${GREEN}✓${NC} Web App      : http://localhost:4000"
        echo -e "${GREEN}✓${NC} API Server   : http://localhost:3000"
        echo -e "${GREEN}✓${NC} PostgreSQL   : localhost:5432"
        echo -e "${GREEN}✓${NC} Redis        : localhost:6379"
        echo ""
        warn "Prochaine étape : Créez 2 comptes utilisateurs et testez une mention !"
        warn "Utilisez l'option 3 pour voir les logs en temps réel."
        ;;

    2)
        step "Démarrage avec images officielles..."
        cd hosting/docker
        docker-compose up -d
        echo ""
        step "Environnement démarré !"
        echo ""
        echo -e "${GREEN}✓${NC} Web App      : http://localhost:4000"
        echo -e "${GREEN}✓${NC} API Server   : http://localhost:3000"
        echo ""
        warn "Note : Cette option utilise les images officielles sans vos modifications."
        warn "Pour tester vos changements, utilisez l'option 1."
        ;;

    3)
        step "Affichage des logs serveur..."
        echo ""
        warn "Appuyez sur Ctrl+C pour quitter"
        echo ""
        cd hosting/docker
        docker-compose -f docker-compose.dev.yaml logs -f server
        ;;

    4)
        step "Recherche des événements de mentions..."
        echo ""
        cd hosting/docker

        echo -e "${BLUE}═══ Événements NodeMentionCreatedEvent ═══${NC}"
        docker logs colanode_server_dev 2>&1 | grep -i "mention" | tail -20 || echo "Aucun événement de mention trouvé"

        echo ""
        echo -e "${BLUE}═══ Messages WebSocket ═══${NC}"
        docker logs colanode_server_dev 2>&1 | grep -i "websocket.*mention\|node.mention.created" | tail -10 || echo "Aucun message WebSocket de mention trouvé"

        echo ""
        if [ $(docker logs colanode_server_dev 2>&1 | grep -c "mention") -eq 0 ]; then
            warn "Aucun événement de mention détecté."
            echo "Avez-vous :"
            echo "  1. Créé 2 comptes utilisateurs ?"
            echo "  2. Envoyé un message avec @mention ?"
        else
            step "Des événements de mentions ont été détectés !"
        fi
        ;;

    5)
        step "Arrêt de l'environnement..."
        cd hosting/docker
        docker-compose -f docker-compose.dev.yaml down
        echo ""
        read -p "Voulez-vous aussi supprimer les volumes (données) ? (y/N) : " delete_volumes
        if [[ $delete_volumes =~ ^[Yy]$ ]]; then
            docker-compose -f docker-compose.dev.yaml down -v
            step "Environnement et données nettoyés !"
        else
            step "Environnement arrêté (données conservées)"
        fi
        ;;

    6)
        step "Lancement de l'app desktop en mode dev..."
        echo ""
        warn "Assurez-vous que l'environnement Docker est démarré (option 1 ou 2)"
        echo ""
        cd apps/desktop

        if [ ! -d "node_modules" ]; then
            warn "node_modules manquant, installation des dépendances..."
            npm install
        fi

        echo ""
        step "Lancement de l'app desktop..."
        DEBUG=desktop:notifications npm run dev
        ;;

    7)
        step "Affichage du guide complet..."
        echo ""
        if [ -f "TESTING_NOTIFICATIONS.md" ]; then
            cat TESTING_NOTIFICATIONS.md
        else
            error "Fichier TESTING_NOTIFICATIONS.md introuvable"
            echo "Consultez : /home/user/colanode/TESTING_NOTIFICATIONS.md"
        fi
        ;;

    *)
        error "Option invalide"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
