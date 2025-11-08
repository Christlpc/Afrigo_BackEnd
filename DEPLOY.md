# Guide de déploiement sur Render

## Configuration Render

### Variables d'environnement requises

Dans le dashboard Render, configurez les variables d'environnement suivantes :

```
DB_HOST=votre-host-postgres
DB_PORT=5432
DB_NAME=afrigo_db
DB_USER=votre-user
DB_PASSWORD=votre-password

JWT_SECRET=votre-secret-jwt-super-securise
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=votre-secret-refresh-super-securise
JWT_REFRESH_EXPIRES_IN=7d

PORT=3000
NODE_ENV=production
```

### Commandes de build

Dans les paramètres du service Render :

- **Build Command**: `yarn install && yarn build`
- **Start Command**: `yarn start`

### Base de données PostgreSQL

1. Créez une base de données PostgreSQL sur Render
2. Assurez-vous que l'extension PostGIS est activée :
   ```sql
   CREATE EXTENSION IF NOT EXISTS "postgis";
   ```
3. Exécutez le script SQL `afrigo_db_architecture (2).sql` sur la base de données

### Étapes de déploiement

1. Connectez votre repository GitHub à Render
2. Configurez les variables d'environnement
3. Spécifiez les commandes de build et start
4. Déployez !

### Vérification

Après le déploiement, vérifiez que :
- Le service démarre sans erreur
- La connexion à la base de données fonctionne
- L'endpoint `/api/health` répond correctement

