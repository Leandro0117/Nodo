import {Router} from 'express';
import {
    getGeneralCategories,
    getGeneralCategory,
    createGeneralCategory,
    getSpecificCategories,
    getSpecificCategory,
    createSpecificCategory,
    getWorkerCategories,
    createWorkerCategory
} from '../controllers/categoryController.js';

const categoryRouter = Router ();

categoryRouter.get('/api/generalCategories', getGeneralCategories);
categoryRouter.get('/api/generalCategory/:id', getGeneralCategory);
categoryRouter.post('/api/generalCategory', createGeneralCategory);

categoryRouter.get('/api/specificCategories', getSpecificCategories);
categoryRouter.get('/api/specificCategory/:id', getSpecificCategory);
categoryRouter.post('/api/specificCategory', createSpecificCategory);

categoryRouter.get('/api/workerCategories', getWorkerCategories);
categoryRouter.post('/api/workerCategory', createWorkerCategory);

export default categoryRouter;
