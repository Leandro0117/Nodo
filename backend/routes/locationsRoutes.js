import { Router } from 'express';
import { getLocations } from '../controllers/locationController.js';

const locationRouter = Router();

locationRouter.get('/api/locations', getLocations);

export default locationRouter;
