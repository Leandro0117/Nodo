import {Router} from 'express';
import {
    apply,
    getApplication,
    getApplications,
    getApplicationsByUserId,
    getApplicationsByPostId,
    updateApplication,
    deleteApplication
} from '../controllers/applicationController.js';
import { requireActiveUser } from '../utils/requireActiveUser.js';

const applicationRouter = Router ();

applicationRouter.post('/api/apply', requireActiveUser((req) => req.body?.workerId), apply);
applicationRouter.get('/api/application/:id', getApplication);
applicationRouter.get('/api/applications', getApplications);
applicationRouter.get('/api/applicationsByUserId/:id', getApplicationsByUserId);
applicationRouter.get('/api/applicationsByPostId/:id', getApplicationsByPostId);
applicationRouter.put('/api/application/:id', updateApplication);
applicationRouter.delete('/api/application/:id', deleteApplication);

export default applicationRouter;
