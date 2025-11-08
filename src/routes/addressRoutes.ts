import { Router } from 'express';
import { AddressController } from '../controllers/addressController';
import { authenticate } from '../middleware/auth';
import { validate, addressCreateSchema } from '../middleware/validation';

const router = Router();

// Toutes les routes nécessitent une authentification
router.use(authenticate);

router.post('/', validate(addressCreateSchema), AddressController.create);
router.get('/', AddressController.getMyAddresses);
router.patch('/:id/favorite', AddressController.updateFavorite);

export default router;

