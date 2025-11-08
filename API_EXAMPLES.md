# Exemples d'utilisation de l'API AfriGo

## Authentification

### Inscription
```bash
POST /api/auth/register
Content-Type: application/json

{
  "email": "client@example.com",
  "phone": "+237612345678",
  "password": "password123",
  "firstName": "Jean",
  "lastName": "Dupont",
  "userType": "client"
}
```

### Connexion
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "client@example.com",
  "password": "password123"
}
```

## Adresses

### Créer une adresse
```bash
POST /api/addresses
Authorization: Bearer <token>
Content-Type: application/json

{
  "fullAddress": "123 Rue de la République, Douala",
  "latitude": 4.0511,
  "longitude": 9.7679,
  "addressLabel": "Maison",
  "city": "Douala",
  "district": "Akwa"
}
```

### Récupérer mes adresses
```bash
GET /api/addresses
Authorization: Bearer <token>
```

## Commandes de Taxi

### Créer une commande de taxi standard
```bash
POST /api/routes
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "taxi"
}
```

### Créer une commande VIP Luxe
```bash
POST /api/routes
Authorization: Bearer <token>
Content-Type: application/json

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

### Créer une commande pour quelqu'un d'autre
```bash
POST /api/routes
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "taxi",
  "thirdPartyOrder": true,
  "thirdPartyName": "Marie Martin",
  "thirdPartyPhone": "+237698765432"
}
```

### Créer une réservation pour une date future
```bash
POST /api/routes
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "taxi",
  "scheduledAt": "2024-12-25T10:00:00Z"
}
```

### Récupérer mes commandes
```bash
GET /api/routes
Authorization: Bearer <token>
```

### Récupérer une commande spécifique
```bash
GET /api/routes/1
Authorization: Bearer <token>
```

### Annuler une commande
```bash
POST /api/routes/1/cancel
Authorization: Bearer <token>
```

### Trouver des chauffeurs disponibles
```bash
GET /api/routes/available-drivers?latitude=4.0511&longitude=9.7679&routeType=taxi&radiusKm=5
Authorization: Bearer <token>
```

## Wallet

### Récupérer le solde
```bash
GET /api/wallet/balance
Authorization: Bearer <token>
```

### Recharger le wallet
```bash
POST /api/wallet/recharge
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 5000
}
```

### Payer une commande avec le wallet
```bash
POST /api/routes/1/pay-wallet
Authorization: Bearer <token>
```

### Historique des transactions
```bash
GET /api/wallet/transactions?limit=50&offset=0
Authorization: Bearer <token>
```

## Types de véhicules disponibles

- `taxi` : Taxi standard
- `moto` : Moto-taxi
- `vip` : Véhicule VIP (nécessite `vipClass`)
  - `business` : Classe affaires
  - `luxe` : Classe luxe
  - `xl` : Classe XL
- `carpool` : Covoiturage

## Statuts de commande

- `pending` : En attente
- `accepted` : Acceptée par un chauffeur
- `pickup` : En cours de prise en charge
- `in_transit` : En transit
- `completed` : Terminée
- `cancelled` : Annulée

## Codes de réponse

- `200` : Succès
- `201` : Créé avec succès
- `400` : Erreur de validation
- `401` : Non autorisé
- `403` : Accès interdit
- `404` : Non trouvé
- `500` : Erreur serveur

