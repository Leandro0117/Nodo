import {Router} from 'express';
import {
    saveToken,
    deleteToken,
} from '../controllers/tokenController.js';
import { requireActiveUser } from '../utils/requireActiveUser.js';

const tokenRouter = Router ();

tokenRouter.post('/api/token', requireActiveUser((req) => req.body?.userId), saveToken);
tokenRouter.delete('/api/token', deleteToken);


export default tokenRouter;
