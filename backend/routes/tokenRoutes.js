import {Router} from 'express';
import {
    saveToken,
    deleteToken,
} from '../controllers/tokenController.js';

const tokenRouter = Router ();

tokenRouter.post('/api/token', saveToken);
tokenRouter.delete('/api/token', deleteToken);


export default tokenRouter;
