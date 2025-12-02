# 🎯 Guide Test Windows - Notifications Toast

## ✅ État Actuel
- ✅ Code serveur : détecte les mentions et publie les événements (vérifié dans les logs)
- ✅ Code desktop : écrit et commité
- ✅ WebSocket : propagation fonctionnelle
- ✅ Permissions : notifications autorisées (test manuel OK)

## 🔧 Résoudre l'Erreur electron-prebuilt-compile

### Sur Windows (D:\Downloads\colanode)

```cmd
# 1. Nettoyer complètement les dépendances
cd D:\Downloads\colanode
rmdir /s /q node_modules
del package-lock.json

# 2. Réinstaller depuis le début
npm install

# 3. Si l'erreur persiste, nettoyer le cache npm
npm cache clean --force
npm install
```

## 🚀 Lancer l'App Desktop

### Méthode 1 : Script Windows (Recommandé)
```cmd
cd D:\Downloads\colanode\apps\desktop
npm run dev:win
```

### Méthode 2 : npm run dev
```cmd
cd D:\Downloads\colanode\apps\desktop
npm run dev
```

### Méthode 3 : Si electron-forge échoue encore
```cmd
cd D:\Downloads\colanode\apps\desktop

# Vérifier que electron est installé
npm list electron

# Si manquant, l'installer
npm install --save-dev electron

# Lancer directement
npx electron .vite/build/main.js
```

## 🧪 Test Complet des Notifications

### 1. Vérifier que Docker tourne (dans WSL ou PowerShell)
```bash
cd /home/user/colanode/hosting/docker
docker-compose -f docker-compose.dev.yaml ps

# Si pas démarré :
docker-compose -f docker-compose.dev.yaml up -d
```

### 2. Lancer l'App Desktop (Windows)
```cmd
cd D:\Downloads\colanode\apps\desktop
npm run dev:win
```

### 3. Configurer 2 Comptes

**Compte Alice (Desktop App Windows) :**
1. Se connecter à `http://localhost:3000`
2. Email : alice@test.com
3. Password : password123
4. Créer ou rejoindre un workspace

**Compte Bob (Navigateur Web) :**
1. Ouvrir http://localhost:4000 dans Chrome/Edge
2. Email : bob@test.com
3. Password : password123
4. Rejoindre le même workspace qu'Alice

### 4. Envoyer une Mention

**Dans le navigateur (Bob) :**
1. Aller dans un canal/conversation
2. Taper `@` pour ouvrir l'autocomplete
3. Sélectionner `@alice` dans la liste
4. Écrire un message : `@alice Test notification !`
5. Envoyer

**IMPORTANT :** Les mentions doivent être créées via l'autocomplete (@), pas en tapant @ directement.

### 5. Résultat Attendu

Sur Windows (App Desktop Alice), une notification Windows native doit apparaître avec :
- **Titre** : "Bob vous a mentionné dans [Workspace Name]"
- **Corps** : "Test notification !" (ou aperçu du message)
- **Son système** (si activé dans Windows)

## 🔍 Déboguer si Pas de Notification

### Vérifier les Logs Serveur
```bash
# Dans WSL ou terminal Docker
docker logs colanode_server_dev 2>&1 | grep -i "MENTION DEBUG"
```

**Vous devriez voir :**
```
[MENTION DEBUG] Extracted 1 mentions from node...
[MENTION DEBUG] Publishing mention event for user 01kbg368...
```

### Vérifier les Logs Desktop
L'app desktop devrait afficher dans la console :
```
desktop:notifications Handling mention received for node abc123
desktop:notifications Notification shown for mention in node abc123 from Bob
```

### Vérifier WebSocket (DevTools Desktop - F12)
```javascript
// Dans la console de l'app desktop
console.log('WebSocket ready:', window.__websocket_ready__)
```

## ❓ Problèmes Courants

### "electron-prebuilt-compile" Error
➡️ Suivre les étapes de nettoyage ci-dessus

### "Cannot find module electron"
```cmd
cd D:\Downloads\colanode
npm install
```

### Notification Permission Denied
```javascript
// Dans DevTools (F12) de l'app desktop
Notification.requestPermission().then(result => {
  console.log('Permission:', result); // Doit être "granted"
});
```

### Pas de mention détectée dans les logs
- Assurez-vous d'utiliser l'autocomplete `@` (pas du texte brut)
- Vérifiez que les 2 comptes sont dans le même workspace
- Redémarrez le serveur Docker si besoin

## ✅ Checklist de Test Final

- [ ] Docker tourne (`docker ps` montre colanode_server_dev)
- [ ] App desktop lancée sans erreur
- [ ] Alice connectée dans l'app desktop
- [ ] Bob connecté dans le navigateur
- [ ] Même workspace pour les 2
- [ ] Bob mentionne @alice via autocomplete
- [ ] Logs serveur montrent "[MENTION DEBUG] Extracted 1 mentions"
- [ ] **Notification Windows apparaît sur le bureau** ✨

## 🎉 Succès !

Si tout fonctionne, vous devriez voir :
1. Logs serveur confirmant la détection de mention
2. Événement WebSocket propagé
3. **Notification Windows native sur le bureau d'Alice**

---

**Note :** Si vous continuez à avoir des problèmes avec electron-forge, essayez :
```cmd
cd D:\Downloads\colanode
npm install -g @electron-forge/cli
cd apps\desktop
electron-forge start
```
