# Architecture du Backend AfriGo

## Vue d'ensemble

Le backend AfriGo est une application Node.js/TypeScript utilisant Express et PostgreSQL avec PostGIS pour la géolocalisation.

## Structure du projet

```
backend/
├── src/
│   ├── config/           # Configuration (database, env)
│   ├── controllers/      # Contrôleurs API
│   ├── middleware/       # Middlewares (auth, validation)
│   ├── models/          # Modèles de données (accès DB)
│   ├── routes/          # Routes API
│   ├── services/        # Services métier
│   ├── types/           # Types TypeScript
│   ├── utils/           # Utilitaires
│   ├── scripts/         # Scripts utilitaires
│   ├── app.ts           # Application Express
│   └── server.ts        # Point d'entrée
├── logs/                # Fichiers de logs
├── package.json
├── tsconfig.json
├── nodemon.json
└── README.md
```

## Architecture en couches

### 1. Routes (src/routes/)
- Définition des endpoints API
- Liaison avec les middlewares
- Appel des contrôleurs

### 2. Middlewares (src/middleware/)
- **auth.ts** : Authentification JWT
- **validation.ts** : Validation des données avec Zod

### 3. Controllers (src/controllers/)
- Gestion des requêtes HTTP
- Validation des données
- Appel des services et modèles
- Retour des réponses

### 4. Models (src/models/)
- Accès à la base de données
- Requêtes SQL
- Mapping des données

### 5. Services (src/services/)
- Logique métier
- Calculs (tarifs, distances, etc.)
- Intégrations externes

### 6. Types (src/types/)
- Définitions TypeScript
- Interfaces de données
- Types de la base de données

## Flux de données

### Création d'une commande

1. **Client** → POST /api/routes
2. **Route** → Validation (middleware)
3. **Controller** → RouteController.create()
4. **Model** → RouteModel.create() (création en DB)
5. **Service** → PricingService (calcul tarif)
6. **Model** → RouteModel.updateFare() (mise à jour tarif)
7. **Controller** → Retour de la réponse

### Paiement avec wallet

1. **Client** → POST /api/routes/:id/pay-wallet
2. **Route** → Authentification (middleware)
3. **Controller** → RouteController.payWithWallet()
4. **Model** → WalletModel.debit() (débit wallet)
5. **Model** → RouteModel.updatePayment() (mise à jour paiement)
6. **Controller** → Retour de la réponse

## Base de données

### Tables principales

- **users** : Utilisateurs
- **client_profile** : Profils clients
- **driver_profile** : Profils chauffeurs
- **routes** : Commandes/trajets
- **addresses** : Adresses
- **wallet** : Portefeuilles
- **wallet_transactions** : Transactions wallet

### Relations clés

- `routes.client_id` → `users.id`
- `routes.driver_id` → `users.id`
- `routes.pickup_address_id` → `addresses.id`
- `routes.dropoff_address_id` → `addresses.id`
- `wallet.user_id` → `users.id`
- `wallet_transactions.wallet_id` → `wallet.id`

## Sécurité

### Authentification
- JWT tokens
- Hashage bcrypt pour les mots de passe
- Refresh tokens (à implémenter)

### Validation
- Zod pour la validation des schémas
- Validation côté serveur
- Sanitization des entrées

### Protection
- Helmet pour les headers HTTP
- CORS configuré
- Rate limiting
- Validation des types

## Services métier

### PricingService
- Calcul des tarifs par type de véhicule
- Estimation distance/durée (Haversine)
- Calcul des commissions
- Multiplicateurs VIP

### Tarification
- **Taxi** : Base 500 XAF, 250 XAF/km, 50 XAF/min
- **Moto** : Base 300 XAF, 150 XAF/km, 30 XAF/min
- **VIP Business** : Base 2000 XAF × 1.2
- **VIP Luxe** : Base 2000 XAF × 1.5
- **VIP XL** : Base 2000 XAF × 1.8
- **Carpool** : Réduction de 20%

### Commission
- Taux par défaut : 15%
- Calcul : `commission = total_fare * 15%`
- Gains chauffeur : `driver_earnings = total_fare - commission`

## Géolocalisation

### PostGIS
- Extension PostgreSQL pour la géolocalisation
- Type `geometry(POINT, 4326)` pour les coordonnées
- Fonctions : `ST_MakePoint`, `ST_Distance`, `ST_DWithin`

### Calcul de distance
- Formule Haversine pour estimation
- Distance en km
- Durée estimée basée sur vitesse moyenne (30 km/h)

## Gestion des erreurs

### Classes d'erreur
- `AppError` : Erreur de base
- `ValidationError` : Erreur de validation (400)
- `NotFoundError` : Ressource non trouvée (404)
- `UnauthorizedError` : Non autorisé (401)
- `ForbiddenError` : Accès interdit (403)

### Format de réponse
```json
{
  "success": false,
  "message": "Message d'erreur",
  "errors": [
    {
      "field": "email",
      "message": "Email invalide"
    }
  ]
}
```

## Logging

### Winston
- Logs dans `logs/error.log` et `logs/combined.log`
- Niveaux : error, warn, info, debug
- Format JSON en production
- Format console en développement

## Variables d'environnement

```env
# Base de données
DB_HOST=localhost
DB_PORT=5432
DB_NAME=afrigo_db
DB_USER=postgres
DB_PASSWORD=***

# JWT
JWT_SECRET=***
JWT_EXPIRES_IN=24h

# Application
PORT=3000
NODE_ENV=development
```

## Améliorations futures

1. **Intégration API de cartographie** (Google Maps, OSRM)
2. **Notifications push** (FCM)
3. **WebSockets** pour le suivi en temps réel
4. **Tests unitaires et d'intégration**
5. **Cache Redis** pour les performances
6. **File upload** pour les photos de profil
7. **SMS/Email** pour les notifications
8. **Système de notation** et avis
9. **Gestion des promotions** et coupons
10. **Dashboard admin**

## Déploiement

### Prérequis
- Node.js 18+
- PostgreSQL 14+ avec PostGIS
- npm ou yarn

### Étapes
1. Installer les dépendances : `npm install`
2. Configurer la base de données
3. Exécuter le script SQL
4. Configurer les variables d'environnement
5. Créer le dossier logs
6. Démarrer : `npm run dev` ou `npm start`

## Maintenance

### Logs
- Vérifier régulièrement `logs/error.log`
- Monitorer les performances
- Surveiller les erreurs de base de données

### Base de données
- Backups réguliers
- Optimisation des index
- Nettoyage des anciennes données

### Sécurité
- Mettre à jour les dépendances
- Rotation des secrets JWT
- Monitoring des tentatives d'intrusion

