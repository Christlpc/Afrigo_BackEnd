import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/env';
import { UserModel } from '../models/User';
import { UnauthorizedError, ForbiddenError } from '../utils/errors';

export interface AuthRequest extends Request {
  user?: {
    id: number;
    email: string;
    userType: string;
  };
}

export const authenticate = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Token d\'authentification manquant');
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, config.jwt.secret) as {
      userId: number;
      email: string;
      userType: string;
    };

    // Vérifier que l'utilisateur existe toujours
    const user = await UserModel.findById(decoded.userId);
    if (!user || user.status !== 'active') {
      throw new UnauthorizedError('Utilisateur non trouvé ou inactif');
    }

    req.user = {
      id: user.id,
      email: user.email,
      userType: user.user_type,
    };

    next();
  } catch (error: any) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      next(new UnauthorizedError('Token invalide ou expiré'));
    } else {
      next(error);
    }
  }
};

export const requireUserType = (...allowedTypes: string[]) => {
  return (req: AuthRequest, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new UnauthorizedError('Authentification requise');
    }

    if (!allowedTypes.includes(req.user.userType)) {
      throw new ForbiddenError('Accès non autorisé pour ce type d\'utilisateur');
    }

    next();
  };
};

export const requireClient = requireUserType('client');
export const requireDriver = requireUserType('driver');
export const requireAdmin = requireUserType('admin');

