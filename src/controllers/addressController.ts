import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { AddressModel } from '../models/Address';
import { sendSuccess } from '../utils/response';
import { NotFoundError } from '../utils/errors';

export class AddressController {
  /**
   * Créer une nouvelle adresse
   */
  static async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const {
        fullAddress,
        latitude,
        longitude,
        addressLabel,
        city,
        district,
        additionalInfo,
      } = req.body;

      const address = await AddressModel.create(
        userId,
        fullAddress,
        latitude,
        longitude,
        addressLabel,
        city,
        district,
        additionalInfo
      );

      sendSuccess(res, { address }, 'Adresse créée avec succès', 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Récupérer toutes les adresses de l'utilisateur
   */
  static async getMyAddresses(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const addresses = await AddressModel.findByUserId(userId);

      sendSuccess(res, { addresses }, 'Adresses récupérées avec succès');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mettre à jour une adresse favorite
   */
  static async updateFavorite(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const addressId = parseInt(req.params.id, 10);
      const { isFavorite } = req.body;

      const address = await AddressModel.updateFavorite(
        addressId,
        userId,
        isFavorite
      );

      if (!address) {
        throw new NotFoundError('Adresse non trouvée');
      }

      sendSuccess(res, { address }, 'Adresse mise à jour avec succès');
    } catch (error) {
      next(error);
    }
  }
}

