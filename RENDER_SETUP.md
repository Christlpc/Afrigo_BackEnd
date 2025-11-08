# Configuration Render - Guide étape par étape

## ⚠️ Problème courant : Build non exécuté

Si vous voyez l'erreur `Cannot find module '/opt/render/project/src/dist/server.js'`, c'est que la commande de build n'a pas été exécutée.

## Solution : Configurer la commande de build dans Render

### Étape 1 : Accéder aux paramètres du service

1. Connectez-vous à [Render Dashboard](https://dashboard.render.com)
2. Sélectionnez votre service web
3. Cliquez sur **"Settings"** dans le menu de gauche

### Étape 2 : Configurer les commandes

Dans la section **"Build & Deploy"**, configurez :

#### Build Command
```
yarn install && yarn build
```

#### Start Command
```
yarn start
```

### Étape 3 : Sauvegarder

1. Cliquez sur **"Save Changes"** en bas de la page
2. Render redéploiera automatiquement avec la nouvelle configuration

## Vérification

Après le redéploiement, vérifiez les logs :

1. Allez dans l'onglet **"Logs"**
2. Vous devriez voir :
   ```
   🔨 Installation des dépendances...
   📦 Compilation TypeScript...
   ✅ Build terminé avec succès!
   🚀 Serveur démarré sur le port 3000
   ```

## Configuration complète

### Variables d'environnement requises

Dans **"Environment"** → **"Environment Variables"**, ajoutez :

```
DB_HOST=<votre-host-postgres>
DB_PORT=5432
DB_NAME=afrigo_db
DB_USER=<votre-user>
DB_PASSWORD=<votre-password>

JWT_SECRET=<votre-secret-jwt-super-securise>
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=<votre-secret-refresh-super-securise>
JWT_REFRESH_EXPIRES_IN=7d

NODE_ENV=production
```

**Note** : `PORT` est automatiquement défini par Render, ne le configurez pas manuellement.

## Alternative : Utiliser render.yaml

Si vous préférez utiliser le fichier `render.yaml` :

1. Assurez-vous que le fichier `render.yaml` est à la racine du repository
2. Dans Render, lors de la création du service, sélectionnez **"Apply render.yaml"**
3. Les commandes seront automatiquement configurées

## Dépannage

### Le build échoue

- Vérifiez que TypeScript est bien installé (il est maintenant dans `dependencies`)
- Vérifiez les logs pour voir l'erreur exacte
- Assurez-vous que `tsconfig.json` est présent

### Le serveur ne démarre pas

- Vérifiez que le dossier `dist/` existe après le build
- Vérifiez les variables d'environnement (surtout la connexion DB)
- Consultez les logs pour les erreurs de connexion

### La base de données ne se connecte pas

- Vérifiez que PostGIS est activé : `CREATE EXTENSION IF NOT EXISTS "postgis";`
- Vérifiez que le script SQL a été exécuté
- Vérifiez les credentials dans les variables d'environnement

## Support

Si le problème persiste, vérifiez :
1. Les logs complets dans Render
2. Que toutes les dépendances sont installées
3. Que la version de Node.js est correcte (22.16.0 via .nvmrc)

