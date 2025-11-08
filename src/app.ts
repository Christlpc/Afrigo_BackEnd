import express, { Application, RequestHandler } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { config } from './config/env';
import routes from './routes';
import { errorHandler } from './utils/errors';

const app: Application = express();

// Middleware de sécurité
app.use(helmet());
app.use(cors());
app.use(compression());

// Middleware de logging
if (config.nodeEnv !== 'production') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Routes avec rate limiting
app.use('/api', limiter, routes);

// Route par défaut
app.get('/', (_req, res) => {
  res.json({
    name: config.app.name,
    version: config.app.version,
    status: 'running',
    environment: config.nodeEnv,
  });
});

// Gestion des erreurs
app.use(errorHandler);

// Gestion des routes non trouvées
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route non trouvée',
  });
});

export default app;

