# 🚀 Démarrage Rapide - Test des Notifications

## En 5 minutes chrono ⏱️

### **1. Lancer l'environnement** (2 min)

```bash
cd /home/user/colanode

# Utiliser le script interactif
./test-notifications.sh

# Puis choisir l'option 1 (build avec vos modifications)
```

Ou manuellement :

```bash
cd hosting/docker
docker-compose -f docker-compose.dev.yaml up --build -d
```

### **2. Créer des comptes de test** (2 min)

1. Ouvrir http://localhost:4000
2. Créer **Alice** (alice@test.com / password123)
3. Créer un workspace
4. Ouvrir un **onglet privé** (Ctrl+Shift+N)
5. Créer **Bob** (bob@test.com / password123)
6. Rejoindre le workspace d'Alice

### **3. Tester la notification** (1 min)

**Sur l'onglet de Bob :**
- Aller dans une conversation
- Écrire : `@alice Coucou !`
- Envoyer

**Sur l'onglet d'Alice :**
- ✅ Vérifier que la mention apparaît

**Voir les logs serveur :**
```bash
./test-notifications.sh
# Choisir option 4 (chercher les événements)
```

---

## 🖥️ Test avec l'App Desktop

### **Lancer l'app desktop**

```bash
cd apps/desktop
npm install  # Si pas déjà fait
npm run dev
```

### **Se connecter**

- Serveur : `http://localhost:3000`
- Email : alice@test.com
- Password : password123

### **Envoyer une mention**

Dans le navigateur (onglet de Bob) : écrire `@alice Test notification !`

### **Résultat attendu**

Une notification Windows native apparaît avec :
- **Titre** : "Bob vous a mentionné dans [Workspace]"
- **Corps** : "Test notification !"

---

## 📊 Vérifier que ça marche

### **Logs serveur**

```bash
cd hosting/docker
docker logs colanode_server_dev 2>&1 | grep -i mention
```

**Vous devriez voir :**
```
[DEBUG] Publishing event: node.mention.created
[DEBUG] WebSocket: Sending message type node.mention.created
```

### **Test notification manuelle (Desktop)**

Ouvrir DevTools (F12) dans l'app desktop :

```javascript
new Notification('Test', { body: 'Ça marche !' }).show();
```

Si cette notification apparaît → votre système de notifications fonctionne ! ✅

---

## 🐛 Problèmes Courants

### Pas de notification ?

1. **Vérifier les permissions**
   ```javascript
   // Dans DevTools (F12)
   Notification.permission  // doit être "granted"
   ```

2. **Vérifier WebSocket**
   ```bash
   docker logs colanode_server_dev | grep -i websocket
   ```

3. **Redémarrer proprement**
   ```bash
   ./test-notifications.sh
   # Option 5 (nettoyer)
   # Puis option 1 (redémarrer)
   ```

---

## 🎯 Checklist Ultra-Rapide

- [ ] Docker démarré
- [ ] 2 comptes créés (Alice + Bob)
- [ ] Bob mentionne @alice
- [ ] Logs montrent `node.mention.created`
- [ ] Notification apparaît

---

## 📞 Aide

**Script interactif :**
```bash
./test-notifications.sh
```

**Documentation complète :**
```bash
cat TESTING_NOTIFICATIONS.md
```

**Logs en direct :**
```bash
cd hosting/docker
docker-compose -f docker-compose.dev.yaml logs -f server
```
