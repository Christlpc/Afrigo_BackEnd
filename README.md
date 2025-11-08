# AfriGo Backend - Application VTC

Backend complet pour une application VTC (Véhicule de Transport avec Chauffeur) avec support pour :
- Commandes de taxi de différents standings (taxi, moto, VIP)
- Réservation pour quelqu'un d'autre
- Réservation pour une date future
- Paiement avec wallet rechargeable

## 🚀 Fonctionnalités

### 1. Authentification
- Inscription/Connexion
- JWT tokens
- Gestion des profils utilisateurs

### 2. Commandes de Taxi
- Création de commandes avec différents types de véhicules :
  - Taxi standard
  - Moto
  - VIP (business, luxe, XL)
  - Covoiturage
- Calcul automatique des tarifs
- Recherche de chauffeurs disponibles
- Suivi des commandes

### 3. Réservations
- Réservation pour une date future (scheduled_at)
- Réservation pour quelqu'un d'autre (third_party_order)
- Gestion des informations tierces (nom, téléphone)

### 4. Wallet (Portefeuille)
- Recharge du wallet
- Paiement avec le wallet
- Historique des transactions
- Gestion du solde

### 5. Adresses
- Création et gestion d'adresses
- Adresses favorites
- Géolocalisation avec PostGIS

## 📋 Prérequis

- Node.js 18+
- PostgreSQL 14+
- PostGIS extension
- npm ou yarn

## 🛠️ Installation

1. Cloner le repository
```bash
git clone <repository-url>
cd backend
```

2. Installer les dépendances
```bash
npm install
```

3. Configurer la base de données
- Créer une base de données PostgreSQL
- Exécuter le script SQL : `afrigo_db_architecture (2).sql`
- Configurer les extensions PostGIS

4. Configurer les variables d'environnement
Créer un fichier `.env` à la racine du projet :
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=afrigo_db
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=your_super_secret_refresh_key
JWT_REFRESH_EXPIRES_IN=7d

PORT=3000
NODE_ENV=development
```

5. Créer le dossier de logs
```bash
mkdir logs
```

## 🚀 Démarrage

### Mode développement
```bash
npm run dev
```

### Mode production
```bash
npm run build
npm start
```

## 📚 Documentation API

### Documentation complète

- **[API_DOCUMENTATION.md](./API_DOCUMENTATION.md)** - Documentation complète de l'API avec tous les détails
- **[openapi.yaml](./openapi.yaml)** - Spécification OpenAPI/Swagger
- **[API_EXAMPLES.md](./API_EXAMPLES.md)** - Exemples d'utilisation de l'API

### Endpoints principaux

#### Authentification
- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/auth/profile` - Profil utilisateur

#### Routes (Commandes)
- `POST /api/routes` - Créer une commande
- `GET /api/routes` - Liste des commandes
- `GET /api/routes/:id` - Détails d'une commande
- `POST /api/routes/:id/cancel` - Annuler une commande
- `POST /api/routes/:id/pay-wallet` - Payer avec le wallet
- `GET /api/routes/available-drivers` - Chauffeurs disponibles

#### Wallet
- `GET /api/wallet/balance` - Solde du wallet
- `POST /api/wallet/recharge` - Recharger le wallet
- `GET /api/wallet/transactions` - Historique des transactions

#### Adresses
- `POST /api/addresses` - Créer une adresse
- `GET /api/addresses` - Liste des adresses
- `PATCH /api/addresses/:id/favorite` - Marquer comme favorite

## 📝 Exemples d'utilisation

### Créer une commande de taxi
```json
POST /api/routes
{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "taxi",
  "scheduledAt": "2024-12-25T10:00:00Z",
  "thirdPartyOrder": true,
  "thirdPartyName": "Jean Dupont",
  "thirdPartyPhone": "+237612345678"
}
```

### Créer une commande VIP
```json
POST /api/routes
{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "vip",
  "vipClass": "luxe"
}
```

### Recharger le wallet
```json
POST /api/wallet/recharge
{
  "amount": 5000
}
```

## 🔒 Sécurité

- Authentification JWT
- Rate limiting
- Helmet pour la sécurité HTTP
- Validation des données avec Zod
- Hashage des mots de passe avec bcrypt

## 🧪 Structure du projet

```
src/
├── config/          # Configuration (database, env)
├── controllers/     # Contrôleurs
├── middleware/      # Middlewares (auth, validation)
├── models/          # Modèles de données
├── routes/          # Routes API
├── services/        # Services métier
├── types/           # Types TypeScript
├── utils/           # Utilitaires
├── app.ts           # Application Express
└── server.ts        # Point d'entrée
```

## 📄 Licence

ISC

## 👥 Auteur

AfriGo Team

