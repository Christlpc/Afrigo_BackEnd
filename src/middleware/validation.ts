import { Request, Response, NextFunction } from 'express';
import { z, ZodSchema } from 'zod';
import { ValidationError } from '../utils/errors';

export const validate = (schema: ZodSchema) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        const errors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        next(new ValidationError('Données invalides', errors));
      } else {
        next(error);
      }
    }
  };
};

// Schémas de validation
export const routeCreateSchema = z.object({
  body: z.object({
    pickupAddressId: z.number().int().positive(),
    dropoffAddressId: z.number().int().positive(),
    pickupLatitude: z.number().min(-90).max(90),
    pickupLongitude: z.number().min(-180).max(180),
    dropoffLatitude: z.number().min(-90).max(90),
    dropoffLongitude: z.number().min(-180).max(180),
    routeType: z.enum(['taxi', 'moto', 'vip', 'carpool']),
    vipClass: z.enum(['business', 'luxe', 'xl']).optional(),
    scheduledAt: z.string().datetime().optional(),
    thirdPartyOrder: z.boolean().optional(),
    thirdPartyName: z.string().optional(),
    thirdPartyPhone: z.string().optional(),
    notes: z.string().optional(),
  }),
});

export const walletRechargeSchema = z.object({
  body: z.object({
    amount: z.number().positive().min(100),
  }),
});

export const addressCreateSchema = z.object({
  body: z.object({
    fullAddress: z.string().min(5),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    addressLabel: z.string().optional(),
    city: z.string().optional(),
    district: z.string().optional(),
    additionalInfo: z.string().optional(),
  }),
});

export const userRegisterSchema = z.object({
  body: z.object({
    email: z.string().email(),
    phone: z.string().min(9).max(20),
    password: z.string().min(6),
    firstName: z.string().optional(),
    lastName: z.string().optional(),
    userType: z.enum(['client', 'driver', 'merchant', 'livreur']),
  }),
});

export const userLoginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(1),
  }),
});

