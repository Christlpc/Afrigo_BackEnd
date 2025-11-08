import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: any[];
}

export const sendSuccess = <T>(
  res: Response,
  data: T,
  message: string = 'Opération réussie',
  statusCode: number = 200
): Response => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

export const sendError = (
  res: Response,
  message: string = 'Une erreur est survenue',
  statusCode: number = 500,
  errors?: any[]
): Response => {
  return res.status(statusCode).json({
    success: false,
    message,
    errors,
  });
};

