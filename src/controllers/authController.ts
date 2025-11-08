import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/User';
import { config } from '../config/env';
import { sendSuccess } from '../utils/response';
import { UnauthorizedError, ValidationError } from '../utils/errors';

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, phone, password, firstName, lastName, userType } = req.body;

      // Vérifier si l'email existe déjà
      const existingUser = await UserModel.findByEmail(email);
      if (existingUser) {
        throw new ValidationError('Cet email est déjà utilisé');
      }

      // Vérifier si le téléphone existe déjà
      const existingPhone = await UserModel.findByPhone(phone);
      if (existingPhone) {
        throw new ValidationError('Ce numéro de téléphone est déjà utilisé');
      }

      // Créer l'utilisateur
      const user = await UserModel.create(
        email,
        phone,
        password,
        userType,
        firstName,
        lastName
      );

      // Créer le profil client si nécessaire
      if (userType === 'client') {
        await UserModel.createClientProfile(user.id);
        await UserModel.createWallet(user.id);
      }

      // Générer le token JWT
      const token = jwt.sign(
        {
          userId: user.id,
          email: user.email,
          userType: user.user_type,
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn } as jwt.SignOptions
      );

      sendSuccess(
        res,
        {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            firstName: user.first_name,
            lastName: user.last_name,
            userType: user.user_type,
            status: user.status,
          },
          token,
        },
        'Inscription réussie',
        201
      );
    } catch (error) {
      next(error);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password } = req.body;

      // Trouver l'utilisateur
      const user = await UserModel.findByEmail(email);
      if (!user) {
        throw new UnauthorizedError('Email ou mot de passe incorrect');
      }

      // Vérifier le mot de passe
      const isPasswordValid = await UserModel.verifyPassword(user, password);
      if (!isPasswordValid) {
        throw new UnauthorizedError('Email ou mot de passe incorrect');
      }

      // Vérifier le statut
      if (user.status !== 'active') {
        throw new UnauthorizedError('Votre compte n\'est pas actif');
      }

      // Générer le token JWT
      const token = jwt.sign(
        {
          userId: user.id,
          email: user.email,
          userType: user.user_type,
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn } as jwt.SignOptions
      );

      sendSuccess(
        res,
        {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            firstName: user.first_name,
            lastName: user.last_name,
            userType: user.user_type,
            status: user.status,
          },
          token,
        },
        'Connexion réussie'
      );
    } catch (error) {
      next(error);
    }
  }

  static async getProfile(req: any, res: Response, next: NextFunction) {
    try {
      const user = await UserModel.findById(req.user.id);
      if (!user) {
        throw new UnauthorizedError('Utilisateur non trouvé');
      }

      sendSuccess(
        res,
        {
          id: user.id,
          email: user.email,
          phone: user.phone,
          firstName: user.first_name,
          lastName: user.last_name,
          userType: user.user_type,
          status: user.status,
          kycStatus: user.kyc_status,
        },
        'Profil récupéré avec succès'
      );
    } catch (error) {
      next(error);
    }
  }
}

