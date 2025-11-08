import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { WalletModel } from '../models/Wallet';
import { sendSuccess } from '../utils/response';
import { ValidationError } from '../utils/errors';

export class WalletController {
  /**
   * Récupérer le solde du wallet
   */
  static async getBalance(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const balance = await WalletModel.getBalance(userId);
      const wallet = await WalletModel.findByUserId(userId);

      sendSuccess(
        res,
        {
          balance,
          wallet: wallet || null,
        },
        'Solde récupéré avec succès'
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Recharger le wallet
   */
  static async recharge(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const { amount } = req.body;

      if (amount < 100) {
        throw new ValidationError('Le montant minimum de recharge est de 100 XAF');
      }

      // Dans une vraie application, on intégrerait ici un système de paiement
      // Pour l'instant, on simule juste le crédit du wallet
      const transaction = await WalletModel.credit(
        userId,
        amount,
        `Recharge de portefeuille de ${amount} XAF`,
        'recharge'
      );

      sendSuccess(
        res,
        {
          transaction,
          newBalance: await WalletModel.getBalance(userId),
        },
        'Portefeuille rechargé avec succès'
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Récupérer l'historique des transactions
   */
  static async getTransactions(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = parseInt(req.query.offset as string) || 0;

      const transactions = await WalletModel.getTransactions(userId, limit, offset);

      sendSuccess(res, { transactions }, 'Transactions récupérées avec succès');
    } catch (error) {
      next(error);
    }
  }
}

