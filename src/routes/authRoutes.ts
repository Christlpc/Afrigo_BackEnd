import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { validate, userRegisterSchema, userLoginSchema } from '../middleware/validation';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/register', validate(userRegisterSchema), AuthController.register);
router.post('/login', validate(userLoginSchema), AuthController.login);
router.get('/profile', authenticate, AuthController.getProfile);

export default router;

