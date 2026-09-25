import {Router} from 'express';
import {
    getUsers,
    getUser,
    createUser,
    checkAvailability,
    deleteUser,
    updateUser,
    activateWorker,
    login,
    resetPassword,
} from '../controllers/userController.js';

const userRouter = Router ();

userRouter.get('/api/users', getUsers);
userRouter.get('/api/user/:id', getUser);
userRouter.post('/api/user', createUser);
// Antes de enviar el SMS del registro. POST para no poner datos personales en la URL.
userRouter.post('/api/user/availability', checkAvailability);
userRouter.delete('/api/user/:id', deleteUser);
userRouter.put('/api/user/:id', updateUser);
userRouter.post('/api/activateWorker/:id', activateWorker);
userRouter.post('/api/login', login);
userRouter.post('/api/resetPassword', resetPassword);

export default userRouter;
