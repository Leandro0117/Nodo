import {Router} from 'express';
import {
    getReports,
    getReport,
    getReportByPostId,
    createReport
} from '../controllers/reportController.js';

const reportRouter = Router ();

reportRouter.get('/api/reports', getReports);
reportRouter.get('/api/report/:id', getReport);
reportRouter.get('/api/reportByPostId/:id', getReportByPostId);
reportRouter.post('/api/report', createReport);

export default reportRouter;
