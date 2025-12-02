# 🔔 Guide de Test - Notifications Toast Windows

Ce guide explique comment tester le système de notifications de mentions implémenté dans Colanode.

---

## 🐳 Test avec Docker (Recommandé)

### **1. Préparation**

```bash
cd /home/user/colanode/hosting/docker
```

### **2. Lancer l'environnement complet**

#### Option A : Avec vos modifications (Build local)

```bash
# Construire et lancer tous les services
docker-compose -f docker-compose.dev.yaml up --build

# Vérifier que tout tourne
docker-compose -f docker-compose.dev.yaml ps
```

#### Option B : Images officielles (plus rapide)

```bash
docker-compose up -d
```

### **3. Accéder aux services**

| Service | URL | Description |
|---------|-----|-------------|
| 🌐 Web App | http://localhost:4000 | Interface utilisateur web |
| 🔌 API Server | http://localhost:3000 | Backend API |
| 🗄️ PostgreSQL | localhost:5432 | Base de données |
| 🔴 Redis | localhost:6379 | Cache & pub/sub |

### **4. Créer des comptes de test**

1. **Ouvrir** http://localhost:4000
2. **Créer** le Compte A (ex: alice@test.com)
3. **Créer** un workspace
4. **Dans un autre navigateur/onglet privé** : Créer le Compte B (ex: bob@test.com)
5. **Inviter** le Compte B dans le même workspace

### **5. Tester les notifications**

#### **Scénario 1 : Test Web (temporaire)**

1. **Ordinateur/Onglet A** (alice@test.com) : Rester connecté
2. **Ordinateur/Onglet B** (bob@test.com) :
   - Aller dans une conversation
   - Écrire : `@alice Bonjour !`
   - Envoyer le message

3. **Résultat attendu** :
   - Alice devrait recevoir un événement WebSocket (visible dans les logs serveur)

#### **Scénario 2 : Test Desktop (notifications natives)**

1. **Installer et lancer l'app desktop**

```bash
cd /home/user/colanode/apps/desktop

# Installer les dépendances (si pas déjà fait)
npm install

# Lancer en mode développement
npm run dev
```

2. **Se connecter avec le Compte A** (alice)
   - Serveur : http://localhost:3000

3. **Dans le navigateur web** (ou autre instance desktop) :
   - Se connecter avec le Compte B (bob)
   - Mentionner @alice dans un message

4. **Résultat attendu** :
   - ✅ Une notification Windows native apparaît sur le bureau d'Alice avec :
     - Titre : "**Bob** vous a mentionné dans **[Workspace Name]**"
     - Corps : Aperçu du message (100 premiers caractères)
     - Son système (si activé)

---

## 🔍 Vérifier les Logs

### **Logs Serveur (Docker)**

```bash
# Voir les logs en temps réel
docker-compose -f docker-compose.dev.yaml logs -f server

# Chercher les événements de mention
docker logs colanode_server_dev 2>&1 | grep "node.mention.created"
```

**Ce que vous devriez voir :**
```
[INFO] EventBus: Publishing NodeMentionCreatedEvent { nodeId: 'abc123', mentionedUserId: 'alice-id', ... }
[DEBUG] WebSocket: Sending message of type node.mention.created to connection xyz
```

### **Logs Desktop**

```bash
# Lancer avec logs de debug
cd apps/desktop
DEBUG=desktop:notifications npm run dev
```

**Ce que vous devriez voir :**
```
desktop:notifications Handling mention received for node abc123
desktop:notifications Notification shown for mention in node abc123 from Bob
```

---

## 🧪 Tests Unitaires

### **Test 1 : Détection des nouvelles mentions**

```typescript
// Créer un fichier test-mention-changes.ts
import { checkMentionChanges } from '@colanode/core';

const before = [{ id: '1', target: 'user-alice' }];
const after = [
  { id: '1', target: 'user-alice' },
  { id: '2', target: 'user-bob' }, // Nouvelle mention
];

const { addedMentions } = checkMentionChanges(before, after);

console.log('✅ Nouvelles mentions détectées:', addedMentions);
// Attendu: [{ id: '2', target: 'user-bob' }]
```

### **Test 2 : Notification manuelle (Electron)**

Ouvrir les DevTools (F12) dans l'app desktop et exécuter :

```javascript
// Tester que les notifications fonctionnent
new Notification('Test Mention', {
  body: 'Quelqu\'un vous a mentionné dans un message',
  silent: false,
  timeoutType: 'default'
}).show();
```

**Résultat attendu :** Une notification Windows apparaît immédiatement.

---

## 🐛 Débogage

### **Problème : Pas de notification affichée**

1. **Vérifier les permissions**
   ```javascript
   // Dans DevTools (F12) de l'app desktop
   console.log(Notification.permission); // Doit être "granted"

   // Si "denied" ou "default", demander la permission
   Notification.requestPermission().then(console.log);
   ```

2. **Vérifier la connexion WebSocket**
   ```bash
   # Logs serveur
   docker logs colanode_server_dev | grep "WebSocket"

   # Chercher : "Socket connection opened"
   ```

3. **Vérifier que l'événement est émis**
   ```bash
   # Logs serveur avec pattern précis
   docker logs colanode_server_dev | grep -E "(mention|NodeMentionCreatedEvent)"
   ```

### **Problème : Serveur ne démarre pas**

```bash
# Vérifier les logs d'erreur
docker-compose -f docker-compose.dev.yaml logs server

# Redémarrer proprement
docker-compose -f docker-compose.dev.yaml down -v
docker-compose -f docker-compose.dev.yaml up --build
```

### **Problème : Build échoue**

```bash
# Nettoyer et reconstruire
cd /home/user/colanode
rm -rf node_modules
npm install
npm run build

# Puis relancer Docker
cd hosting/docker
docker-compose -f docker-compose.dev.yaml up --build
```

---

## 📊 Checklist de Test

- [ ] **Serveur démarré** (`docker-compose ps` montre tous les services "Up")
- [ ] **2 comptes créés** (Alice et Bob)
- [ ] **Même workspace** (Bob invité dans le workspace d'Alice)
- [ ] **WebSocket connecté** (logs montrent "Socket connection opened")
- [ ] **Message avec mention envoyé** (Bob écrit `@alice Hello`)
- [ ] **Événement émis** (logs serveur montrent `node.mention.created`)
- [ ] **Message WebSocket reçu** (logs client montrent `workspace.mention.received`)
- [ ] **Notification affichée** (toast Windows apparaît sur le bureau d'Alice)

---

## 🎯 Commandes Rapides

```bash
# Démarrer l'environnement
cd hosting/docker && docker-compose -f docker-compose.dev.yaml up --build -d

# Voir les logs en direct
docker-compose -f docker-compose.dev.yaml logs -f

# Arrêter tout
docker-compose -f docker-compose.dev.yaml down

# Nettoyer complètement (⚠️ efface les données)
docker-compose -f docker-compose.dev.yaml down -v

# Lancer l'app desktop
cd apps/desktop && npm run dev
```

---

## 📝 Notes

- **Desktop** : Les notifications sont natives (Windows/macOS/Linux)
- **Web** : Les notifications utilisent l'API Notification du navigateur
- **Temps réel** : Les notifications arrivent instantanément via WebSocket
- **Badge** : Le système de badge macOS fonctionne déjà (compteur d'unread)

---

## 🚀 Prochaines Étapes

1. [ ] Ajouter navigation au clic sur la notification
2. [ ] Créer un centre de notifications dans l'UI
3. [ ] Ajouter des préférences utilisateur (activer/désactiver)
4. [ ] Supporter d'autres types de notifications (réactions, commentaires, etc.)
