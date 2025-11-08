import { Router } from 'express';
import { RouteController } from '../controllers/routeController';
import { authenticate, requireClient } from '../middleware/auth';
import { validate, routeCreateSchema } from '../middleware/validation';

const router = Router();

// Toutes les routes nécessitent une authentification
router.use(authenticate);
router.use(requireClient);

router.post('/', validate(routeCreateSchema), RouteController.create);
router.get('/', RouteController.getMyRoutes);
router.get('/available-drivers', RouteController.findAvailableDrivers);
router.get('/:id', RouteController.getRoute);
router.post('/:id/cancel', RouteController.cancel);
router.post('/:id/pay-wallet', RouteController.payWithWallet);

export default router;

