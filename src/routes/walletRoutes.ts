import { Router } from 'express';
import { WalletController } from '../controllers/walletController';
import { authenticate } from '../middleware/auth';
import { validate, walletRechargeSchema } from '../middleware/validation';

const router = Router();

// Toutes les routes nécessitent une authentification
router.use(authenticate);

router.get('/balance', WalletController.getBalance);
router.post('/recharge', validate(walletRechargeSchema), WalletController.recharge);
router.get('/transactions', WalletController.getTransactions);

export default router;

