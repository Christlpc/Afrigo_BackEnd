import { Router } from 'express';
import authRoutes from './authRoutes';
import routeRoutes from './routeRoutes';
import walletRoutes from './walletRoutes';
import addressRoutes from './addressRoutes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/routes', routeRoutes);
router.use('/wallet', walletRoutes);
router.use('/addresses', addressRoutes);

// Route de santé
router.get('/health', (_req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

export default router;

