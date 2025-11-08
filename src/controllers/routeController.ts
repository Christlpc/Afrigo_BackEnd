import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { RouteModel } from '../models/Route';
import { PricingService } from '../services/pricingService';
import { sendSuccess } from '../utils/response';
import { NotFoundError, ValidationError } from '../utils/errors';
import { WalletModel } from '../models/Wallet';

export class RouteController {
  /**
   * Créer une nouvelle commande de taxi
   */
  static async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const {
        pickupAddressId,
        dropoffAddressId,
        pickupLatitude,
        pickupLongitude,
        dropoffLatitude,
        dropoffLongitude,
        routeType,
        vipClass,
        scheduledAt,
        thirdPartyOrder,
        thirdPartyName,
        thirdPartyPhone,
        notes,
      } = req.body;

      // Créer le trajet
      const route = await RouteModel.create(
        userId,
        pickupAddressId,
        dropoffAddressId,
        pickupLatitude,
        pickupLongitude,
        dropoffLatitude,
        dropoffLongitude,
        routeType,
        vipClass,
        scheduledAt ? new Date(scheduledAt) : undefined,
        thirdPartyOrder,
        thirdPartyName,
        thirdPartyPhone,
        notes
      );

      // Calculer la distance et la durée estimées
      const { distanceKm, durationMinutes } =
        await PricingService.estimateDistanceAndDuration(
          pickupLatitude,
          pickupLongitude,
          dropoffLatitude,
          dropoffLongitude
        );

      // Calculer le tarif
      const fare = PricingService.calculateFare(
        routeType,
        distanceKm,
        durationMinutes,
        vipClass
      );

      // Mettre à jour le trajet avec les informations de tarification
      // Commission par défaut de 15%
      const commissionRate = 15;
      const updatedRoute = await RouteModel.updateFare(
        route.id,
        fare.baseFare,
        fare.distanceFare,
        fare.timeFare,
        fare.totalFare,
        distanceKm,
        durationMinutes,
        commissionRate
      );

      sendSuccess(
        res,
        {
          route: {
            ...updatedRoute,
            estimatedDistance: distanceKm,
            estimatedDuration: durationMinutes,
          },
        },
        'Commande créée avec succès',
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Récupérer toutes les commandes d'un client
   */
  static async getMyRoutes(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const routes = await RouteModel.findByClientId(userId);

      sendSuccess(res, { routes }, 'Commandes récupérées avec succès');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Récupérer une commande spécifique
   */
  static async getRoute(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const routeId = parseInt(req.params.id, 10);
      const route = await RouteModel.findById(routeId);

      if (!route) {
        throw new NotFoundError('Commande non trouvée');
      }

      // Vérifier que le client est propriétaire de la commande
      if (route.client_id !== req.user!.id) {
        throw new ValidationError('Vous n\'avez pas accès à cette commande');
      }

      sendSuccess(res, { route }, 'Commande récupérée avec succès');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Annuler une commande
   */
  static async cancel(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const routeId = parseInt(req.params.id, 10);
      const route = await RouteModel.findById(routeId);

      if (!route) {
        throw new NotFoundError('Commande non trouvée');
      }

      if (route.client_id !== req.user!.id) {
        throw new ValidationError('Vous n\'avez pas accès à cette commande');
      }

      if (route.status === 'completed' || route.status === 'cancelled') {
        throw new ValidationError('Cette commande ne peut pas être annulée');
      }

      const cancelledRoute = await RouteModel.updateStatus(routeId, 'cancelled');

      // Si le paiement a été effectué, rembourser
      if (route.payment_method === 'wallet' && route.payment_status === 'completed') {
        await WalletModel.credit(
          req.user!.id,
          route.total_fare!,
          `Remboursement pour annulation de commande #${routeId}`,
          'route',
          routeId
        );
      }

      sendSuccess(res, { route: cancelledRoute }, 'Commande annulée avec succès');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Payer une commande avec le wallet
   */
  static async payWithWallet(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const routeId = parseInt(req.params.id, 10);
      const route = await RouteModel.findById(routeId);

      if (!route) {
        throw new NotFoundError('Commande non trouvée');
      }

      if (route.client_id !== req.user!.id) {
        throw new ValidationError('Vous n\'avez pas accès à cette commande');
      }

      if (route.payment_status === 'completed') {
        throw new ValidationError('Cette commande est déjà payée');
      }

      if (!route.total_fare) {
        throw new ValidationError('Le tarif n\'a pas été calculé');
      }

      // Débiter le wallet
      await WalletModel.debit(
        req.user!.id,
        route.total_fare,
        `Paiement pour commande #${routeId}`,
        'route',
        routeId
      );

      // Mettre à jour le statut de paiement
      const updatedRoute = await RouteModel.updatePayment(
        routeId,
        'wallet',
        'completed'
      );

      sendSuccess(res, { route: updatedRoute }, 'Paiement effectué avec succès');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Trouver des chauffeurs disponibles
   */
  static async findAvailableDrivers(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { latitude, longitude, routeType, radiusKm = 5 } = req.query;

      if (!latitude || !longitude || !routeType) {
        throw new ValidationError('Latitude, longitude et routeType sont requis');
      }

      const drivers = await RouteModel.findAvailableDrivers(
        routeType as any,
        parseFloat(latitude as string),
        parseFloat(longitude as string),
        parseFloat(radiusKm as string)
      );

      sendSuccess(res, { drivers }, 'Chauffeurs disponibles récupérés');
    } catch (error) {
      next(error);
    }
  }
}

