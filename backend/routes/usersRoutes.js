import {Router} from 'express';
import {
    getUsers,
    getUser,
    createUser,
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
userRouter.delete('/api/user/:id', deleteUser);
userRouter.put('/api/user/:id', updateUser);
userRouter.post('/api/activateWorker/:id', activateWorker);
userRouter.post('/api/login', login);
userRouter.post('/api/resetPassword', resetPassword);

export default userRouter;
