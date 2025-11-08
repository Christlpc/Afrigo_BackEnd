import app from './app';
import { config } from './config/env';
import { testConnection } from './config/database';
import logger from './utils/logger';

const PORT = config.port;

// Démarrer le serveur
const startServer = async () => {
  try {
    // Tester la connexion à la base de données
    const dbConnected = await testConnection();
    if (!dbConnected) {
      logger.error('Impossible de se connecter à la base de données');
      process.exit(1);
    }

    // Démarrer le serveur Express
    app.listen(PORT, () => {
      logger.info(`🚀 Serveur démarré sur le port ${PORT}`);
      logger.info(`📱 Environnement: ${config.nodeEnv}`);
      logger.info(`🌐 API disponible sur http://localhost:${PORT}/api`);
    });
  } catch (error) {
    logger.error('Erreur lors du démarrage du serveur:', error);
    process.exit(1);
  }
};

startServer();

// Gestion des erreurs non capturées
process.on('unhandledRejection', (reason: Error, promise: Promise<any>) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Gestion de l'arrêt propre
process.on('SIGTERM', () => {
  logger.info('SIGTERM reçu, arrêt du serveur...');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT reçu, arrêt du serveur...');
  process.exit(0);
});

