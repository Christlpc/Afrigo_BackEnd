export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  errors?: any[];

  constructor(message: string, errors?: any[]) {
    super(message, 400);
    this.errors = errors;
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Ressource non trouvée') {
    super(message, 404);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Non autorisé') {
    super(message, 401);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Accès interdit') {
    super(message, 403);
  }
}

export const errorHandler = (
  error: Error,
  req: any,
  res: any,
  next: any
) => {
  if (error instanceof AppError) {
    const response: any = {
      success: false,
      message: error.message,
    };
    
    if (error instanceof ValidationError && error.errors) {
      response.errors = error.errors;
    }
    
    return res.status(error.statusCode).json(response);
  }

  // Erreur inconnue
  console.error('Erreur non gérée:', error);
  return res.status(500).json({
    success: false,
    message: 'Une erreur interne est survenue',
  });
};

