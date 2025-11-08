# Documentation API AfriGo

## Table des matières

1. [Introduction](#introduction)
2. [Authentification](#authentification)
3. [Endpoints](#endpoints)
   - [Authentification](#endpoints-authentification)
   - [Adresses](#endpoints-adresses)
   - [Routes (Commandes)](#endpoints-routes)
   - [Wallet](#endpoints-wallet)
4. [Modèles de données](#modèles-de-données)
5. [Codes d'erreur](#codes-derreur)
6. [Exemples complets](#exemples-complets)

---

## Introduction

L'API AfriGo est une API RESTful pour la gestion d'une application VTC (Véhicule de Transport avec Chauffeur).

**Base URL**: `http://localhost:3000/api`

**Format des réponses**: JSON

**Authentification**: Bearer Token (JWT)

---

## Authentification

La plupart des endpoints nécessitent une authentification via un token JWT. Le token doit être inclus dans le header `Authorization` :

```
Authorization: Bearer <votre_token_jwt>
```

---

## Endpoints

### Endpoints Authentification

#### 1. Inscription

Crée un nouveau compte utilisateur.

**Endpoint**: `POST /api/auth/register`

**Authentification**: Non requise

**Corps de la requête**:

```json
{
  "email": "client@example.com",
  "phone": "+237612345678",
  "password": "password123",
  "firstName": "Jean",
  "lastName": "Dupont",
  "userType": "client"
}
```

**Paramètres**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| email | string | Oui | Adresse email (format email valide) |
| phone | string | Oui | Numéro de téléphone (9-20 caractères) |
| password | string | Oui | Mot de passe (minimum 6 caractères) |
| firstName | string | Non | Prénom |
| lastName | string | Non | Nom de famille |
| userType | enum | Oui | Type d'utilisateur: `client`, `driver`, `merchant`, `livreur` |

**Réponse succès (201)**:

```json
{
  "success": true,
  "message": "Inscription réussie",
  "data": {
    "user": {
      "id": 1,
      "email": "client@example.com",
      "phone": "+237612345678",
      "firstName": "Jean",
      "lastName": "Dupont",
      "userType": "client",
      "status": "pending"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Réponse erreur (400)**:

```json
{
  "success": false,
  "message": "Données invalides",
  "errors": [
    {
      "field": "body.email",
      "message": "Invalid email"
    }
  ]
}
```

---

#### 2. Connexion

Authentifie un utilisateur et retourne un token JWT.

**Endpoint**: `POST /api/auth/login`

**Authentification**: Non requise

**Corps de la requête**:

```json
{
  "email": "client@example.com",
  "password": "password123"
}
```

**Paramètres**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| email | string | Oui | Adresse email |
| password | string | Oui | Mot de passe |

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "user": {
      "id": 1,
      "email": "client@example.com",
      "phone": "+237612345678",
      "firstName": "Jean",
      "lastName": "Dupont",
      "userType": "client",
      "status": "active"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Réponse erreur (401)**:

```json
{
  "success": false,
  "message": "Email ou mot de passe incorrect"
}
```

---

#### 3. Profil utilisateur

Récupère les informations du profil de l'utilisateur connecté.

**Endpoint**: `GET /api/auth/profile`

**Authentification**: Requise

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Profil récupéré avec succès",
  "data": {
    "id": 1,
    "email": "client@example.com",
    "phone": "+237612345678",
    "firstName": "Jean",
    "lastName": "Dupont",
    "userType": "client",
    "status": "active",
    "kycStatus": "pending"
  }
}
```

---

### Endpoints Adresses

#### 1. Créer une adresse

Crée une nouvelle adresse pour l'utilisateur connecté.

**Endpoint**: `POST /api/addresses`

**Authentification**: Requise

**Corps de la requête**:

```json
{
  "fullAddress": "123 Rue de la République, Douala",
  "latitude": 4.0511,
  "longitude": 9.7679,
  "addressLabel": "Maison",
  "city": "Douala",
  "district": "Akwa",
  "additionalInfo": "Près de la pharmacie"
}
```

**Paramètres**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| fullAddress | string | Oui | Adresse complète (minimum 5 caractères) |
| latitude | number | Oui | Latitude (-90 à 90) |
| longitude | number | Oui | Longitude (-180 à 180) |
| addressLabel | string | Non | Libellé de l'adresse (ex: "Maison", "Bureau") |
| city | string | Non | Ville |
| district | string | Non | Quartier/Arrondissement |
| additionalInfo | string | Non | Informations complémentaires |

**Réponse succès (201)**:

```json
{
  "success": true,
  "message": "Adresse créée avec succès",
  "data": {
    "address": {
      "id": 1,
      "user_id": 1,
      "full_address": "123 Rue de la République, Douala",
      "latitude": 4.0511,
      "longitude": 9.7679,
      "address_label": "Maison",
      "city": "Douala",
      "district": "Akwa",
      "is_favorite": false,
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

---

#### 2. Récupérer mes adresses

Récupère toutes les adresses de l'utilisateur connecté.

**Endpoint**: `GET /api/addresses`

**Authentification**: Requise

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Adresses récupérées avec succès",
  "data": {
    "addresses": [
      {
        "id": 1,
        "user_id": 1,
        "full_address": "123 Rue de la République, Douala",
        "latitude": 4.0511,
        "longitude": 9.7679,
        "address_label": "Maison",
        "city": "Douala",
        "district": "Akwa",
        "is_favorite": true,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

---

#### 3. Mettre à jour une adresse favorite

Marque ou retire le statut de favorite d'une adresse.

**Endpoint**: `PATCH /api/addresses/:id/favorite`

**Authentification**: Requise

**Paramètres URL**:

| Paramètre | Type | Description |
|-----------|------|-------------|
| id | number | ID de l'adresse |

**Corps de la requête**:

```json
{
  "isFavorite": true
}
```

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Adresse mise à jour avec succès",
  "data": {
    "address": {
      "id": 1,
      "is_favorite": true,
      ...
    }
  }
}
```

---

### Endpoints Routes (Commandes)

#### 1. Créer une commande

Crée une nouvelle commande de taxi.

**Endpoint**: `POST /api/routes`

**Authentification**: Requise (Client uniquement)

**Corps de la requête**:

```json
{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "taxi",
  "vipClass": "luxe",
  "scheduledAt": "2024-12-25T10:00:00Z",
  "thirdPartyOrder": true,
  "thirdPartyName": "Marie Martin",
  "thirdPartyPhone": "+237698765432",
  "notes": "Appeler à l'arrivée"
}
```

**Paramètres**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| pickupAddressId | number | Oui | ID de l'adresse de prise en charge |
| dropoffAddressId | number | Oui | ID de l'adresse de destination |
| pickupLatitude | number | Oui | Latitude du point de départ |
| pickupLongitude | number | Oui | Longitude du point de départ |
| dropoffLatitude | number | Oui | Latitude du point d'arrivée |
| dropoffLongitude | number | Oui | Longitude du point d'arrivée |
| routeType | enum | Oui | Type: `taxi`, `moto`, `vip`, `carpool` |
| vipClass | enum | Non | Classe VIP si routeType=vip: `business`, `luxe`, `xl` |
| scheduledAt | string | Non | Date/heure de réservation (ISO 8601) |
| thirdPartyOrder | boolean | Non | Commande pour quelqu'un d'autre |
| thirdPartyName | string | Non | Nom de la personne (si thirdPartyOrder=true) |
| thirdPartyPhone | string | Non | Téléphone de la personne (si thirdPartyOrder=true) |
| notes | string | Non | Notes supplémentaires |

**Réponse succès (201)**:

```json
{
  "success": true,
  "message": "Commande créée avec succès",
  "data": {
    "route": {
      "id": 1,
      "client_id": 1,
      "pickup_address_id": 1,
      "dropoff_address_id": 2,
      "route_type": "taxi",
      "vip_class": null,
      "status": "pending",
      "scheduled_at": null,
      "third_party_order": false,
      "estimated_distance": 5.2,
      "estimated_duration": 10,
      "base_fare": 500,
      "distance_fare": 1300,
      "time_fare": 500,
      "total_fare": 2300,
      "commission_amount": 345,
      "commission_rate": 15,
      "driver_earnings": 1955,
      "payment_status": "pending",
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

**Exemples de commandes**:

**Taxi standard**:
```json
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

**VIP Luxe**:
```json
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

**Réservation pour quelqu'un d'autre**:
```json
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

**Réservation pour une date future**:
```json
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

---

#### 2. Récupérer mes commandes

Récupère toutes les commandes de l'utilisateur connecté.

**Endpoint**: `GET /api/routes`

**Authentification**: Requise (Client uniquement)

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Commandes récupérées avec succès",
  "data": {
    "routes": [
      {
        "id": 1,
        "client_id": 1,
        "driver_id": null,
        "pickup_address": "123 Rue de la République",
        "dropoff_address": "456 Avenue du Port",
        "route_type": "taxi",
        "status": "pending",
        "total_fare": 2300,
        "payment_status": "pending",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

---

#### 3. Récupérer une commande

Récupère les détails d'une commande spécifique.

**Endpoint**: `GET /api/routes/:id`

**Authentification**: Requise (Client uniquement)

**Paramètres URL**:

| Paramètre | Type | Description |
|-----------|------|-------------|
| id | number | ID de la commande |

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Commande récupérée avec succès",
  "data": {
    "route": {
      "id": 1,
      "client_id": 1,
      "driver_id": 5,
      "pickup_address": "123 Rue de la République",
      "dropoff_address": "456 Avenue du Port",
      "route_type": "taxi",
      "status": "accepted",
      "scheduled_at": null,
      "third_party_order": false,
      "estimated_distance": 5.2,
      "estimated_duration": 10,
      "base_fare": 500,
      "distance_fare": 1300,
      "time_fare": 500,
      "total_fare": 2300,
      "commission_amount": 345,
      "driver_earnings": 1955,
      "payment_method": "wallet",
      "payment_status": "completed",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:35:00Z"
    }
  }
}
```

---

#### 4. Annuler une commande

Annule une commande en attente.

**Endpoint**: `POST /api/routes/:id/cancel`

**Authentification**: Requise (Client uniquement)

**Paramètres URL**:

| Paramètre | Type | Description |
|-----------|------|-------------|
| id | number | ID de la commande |

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Commande annulée avec succès",
  "data": {
    "route": {
      "id": 1,
      "status": "cancelled",
      "cancelled_at": "2024-01-15T10:40:00Z",
      ...
    }
  }
}
```

**Note**: Si la commande était payée avec le wallet, le remboursement est automatique.

---

#### 5. Payer avec le wallet

Effectue le paiement d'une commande avec le wallet.

**Endpoint**: `POST /api/routes/:id/pay-wallet`

**Authentification**: Requise (Client uniquement)

**Paramètres URL**:

| Paramètre | Type | Description |
|-----------|------|-------------|
| id | number | ID de la commande |

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Paiement effectué avec succès",
  "data": {
    "route": {
      "id": 1,
      "payment_method": "wallet",
      "payment_status": "completed",
      ...
    }
  }
}
```

**Réponse erreur (400)** - Solde insuffisant:

```json
{
  "success": false,
  "message": "Solde insuffisant"
}
```

---

#### 6. Trouver des chauffeurs disponibles

Recherche des chauffeurs disponibles près d'une position.

**Endpoint**: `GET /api/routes/available-drivers`

**Authentification**: Requise (Client uniquement)

**Paramètres de requête**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| latitude | number | Oui | Latitude de la position |
| longitude | number | Oui | Longitude de la position |
| routeType | enum | Oui | Type de véhicule: `taxi`, `moto`, `vip` |
| radiusKm | number | Non | Rayon de recherche en km (défaut: 5) |

**Exemple de requête**:

```
GET /api/routes/available-drivers?latitude=4.0511&longitude=9.7679&routeType=taxi&radiusKm=5
```

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Chauffeurs disponibles récupérés",
  "data": {
    "drivers": [
      {
        "id": 1,
        "user_id": 5,
        "first_name": "Paul",
        "last_name": "Martin",
        "phone": "+237612345678",
        "vehicle_type": "taxi",
        "vehicle_brand": "Toyota",
        "vehicle_model": "Corolla",
        "license_plate": "CE-1234-AB",
        "average_rating": 4.5,
        "distance_km": 2.3
      }
    ]
  }
}
```

---

### Endpoints Wallet

#### 1. Récupérer le solde

Récupère le solde actuel du wallet.

**Endpoint**: `GET /api/wallet/balance`

**Authentification**: Requise

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Solde récupéré avec succès",
  "data": {
    "balance": 5000,
    "wallet": {
      "id": 1,
      "user_id": 1,
      "balance": 5000,
      "pending_balance": 0,
      "total_earned": 10000,
      "last_withdrawal_date": null,
      "created_at": "2024-01-10T08:00:00Z"
    }
  }
}
```

---

#### 2. Recharger le wallet

Recharge le wallet avec un montant.

**Endpoint**: `POST /api/wallet/recharge`

**Authentification**: Requise

**Corps de la requête**:

```json
{
  "amount": 5000
}
```

**Paramètres**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| amount | number | Oui | Montant à recharger (minimum 100 XAF) |

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Portefeuille rechargé avec succès",
  "data": {
    "transaction": {
      "id": 1,
      "wallet_id": 1,
      "transaction_type": "credit",
      "amount": 5000,
      "description": "Recharge de portefeuille de 5000 XAF",
      "status": "completed",
      "created_at": "2024-01-15T10:30:00Z"
    },
    "newBalance": 10000
  }
}
```

---

#### 3. Historique des transactions

Récupère l'historique des transactions du wallet.

**Endpoint**: `GET /api/wallet/transactions`

**Authentification**: Requise

**Paramètres de requête**:

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| limit | number | Non | Nombre de résultats (défaut: 50) |
| offset | number | Non | Décalage pour la pagination (défaut: 0) |

**Exemple de requête**:

```
GET /api/wallet/transactions?limit=20&offset=0
```

**Réponse succès (200)**:

```json
{
  "success": true,
  "message": "Transactions récupérées avec succès",
  "data": {
    "transactions": [
      {
        "id": 1,
        "wallet_id": 1,
        "transaction_type": "credit",
        "amount": 5000,
        "description": "Recharge de portefeuille de 5000 XAF",
        "reference_type": "recharge",
        "reference_id": null,
        "status": "completed",
        "created_at": "2024-01-15T10:30:00Z"
      },
      {
        "id": 2,
        "wallet_id": 1,
        "transaction_type": "debit",
        "amount": 2300,
        "description": "Paiement pour commande #1",
        "reference_type": "route",
        "reference_id": 1,
        "status": "completed",
        "created_at": "2024-01-15T10:35:00Z"
      }
    ]
  }
}
```

---

## Modèles de données

### Types de véhicules (routeType)

- `taxi` : Taxi standard
- `moto` : Moto-taxi
- `vip` : Véhicule VIP (nécessite `vipClass`)
- `carpool` : Covoiturage

### Classes VIP (vipClass)

- `business` : Classe affaires (multiplicateur 1.2x)
- `luxe` : Classe luxe (multiplicateur 1.5x)
- `xl` : Classe XL (multiplicateur 1.8x)

### Statuts de commande (status)

- `pending` : En attente d'acceptation
- `accepted` : Acceptée par un chauffeur
- `pickup` : En cours de prise en charge
- `in_transit` : En transit vers la destination
- `completed` : Trajet terminé
- `cancelled` : Annulée

### Statuts de paiement (paymentStatus)

- `pending` : En attente de paiement
- `completed` : Paiement effectué
- `failed` : Échec du paiement
- `cancelled` : Paiement annulé

### Types de transactions (transactionType)

- `credit` : Crédit (recharge, remboursement)
- `debit` : Débit (paiement)
- `commission` : Commission
- `withdrawal` : Retrait
- `refund` : Remboursement

---

## Codes d'erreur

### Codes HTTP

| Code | Description |
|------|-------------|
| 200 | Succès |
| 201 | Créé avec succès |
| 400 | Erreur de validation |
| 401 | Non autorisé (token manquant ou invalide) |
| 403 | Accès interdit (permissions insuffisantes) |
| 404 | Ressource non trouvée |
| 500 | Erreur serveur |

### Format des erreurs

**Erreur de validation (400)**:

```json
{
  "success": false,
  "message": "Données invalides",
  "errors": [
    {
      "field": "body.email",
      "message": "Invalid email"
    },
    {
      "field": "body.password",
      "message": "String must contain at least 6 character(s)"
    }
  ]
}
```

**Erreur générique**:

```json
{
  "success": false,
  "message": "Message d'erreur descriptif"
}
```

---

## Exemples complets

### Scénario 1 : Créer une commande et payer avec le wallet

1. **Créer une adresse de départ**:
```bash
POST /api/addresses
Authorization: Bearer <token>
{
  "fullAddress": "123 Rue de la République, Douala",
  "latitude": 4.0511,
  "longitude": 9.7679,
  "addressLabel": "Maison"
}
```

2. **Créer une adresse de destination**:
```bash
POST /api/addresses
Authorization: Bearer <token>
{
  "fullAddress": "456 Avenue du Port, Douala",
  "latitude": 4.0611,
  "longitude": 9.7779,
  "addressLabel": "Bureau"
}
```

3. **Créer la commande**:
```bash
POST /api/routes
Authorization: Bearer <token>
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

4. **Payer avec le wallet**:
```bash
POST /api/routes/1/pay-wallet
Authorization: Bearer <token>
```

---

### Scénario 2 : Réservation VIP pour quelqu'un d'autre

```bash
POST /api/routes
Authorization: Bearer <token>
{
  "pickupAddressId": 1,
  "dropoffAddressId": 2,
  "pickupLatitude": 4.0511,
  "pickupLongitude": 9.7679,
  "dropoffLatitude": 4.0611,
  "dropoffLongitude": 9.7779,
  "routeType": "vip",
  "vipClass": "luxe",
  "thirdPartyOrder": true,
  "thirdPartyName": "Marie Martin",
  "thirdPartyPhone": "+237698765432",
  "scheduledAt": "2024-12-25T10:00:00Z"
}
```

---

### Scénario 3 : Recharger le wallet et consulter l'historique

1. **Recharger**:
```bash
POST /api/wallet/recharge
Authorization: Bearer <token>
{
  "amount": 10000
}
```

2. **Consulter le solde**:
```bash
GET /api/wallet/balance
Authorization: Bearer <token>
```

3. **Consulter l'historique**:
```bash
GET /api/wallet/transactions?limit=10
Authorization: Bearer <token>
```

---

## Tarification

### Tarifs de base

| Type | Base | Par km | Par minute | Minimum |
|------|------|--------|------------|---------|
| Taxi | 500 XAF | 250 XAF | 50 XAF | 1000 XAF |
| Moto | 300 XAF | 150 XAF | 30 XAF | 500 XAF |
| VIP | 2000 XAF | 500 XAF | 100 XAF | 3000 XAF |
| Carpool | 400 XAF | 200 XAF | 40 XAF | 800 XAF |

### Multiplicateurs VIP

- Business : 1.2x
- Luxe : 1.5x
- XL : 1.8x

### Commission

- Taux par défaut : 15%
- Calcul : `commission = total_fare × 15%`
- Gains chauffeur : `driver_earnings = total_fare - commission`

---

## Limites et contraintes

- **Taille maximale des requêtes** : 10 MB
- **Rate limiting** : 100 requêtes par 15 minutes par IP
- **Durée de vie du token JWT** : 24 heures
- **Montant minimum de recharge** : 100 XAF
- **Rayon de recherche de chauffeurs** : 5 km par défaut (max 20 km)

---

## Support

Pour toute question ou problème, contactez le support technique.

**Version API** : 1.0.0  
**Dernière mise à jour** : 2024-01-15

