import express from 'express';
import {
    createNotification,
    getNotificationsByUserId,
    getNotifications
} from '../controllers/notificationController.js';

const notificationRouter = express.Router();

notificationRouter.post('/api/notification', createNotification);
notificationRouter.get('/api/notificationsByUserId/:userId', getNotificationsByUserId);
notificationRouter.get('/api/notifications', getNotifications);


export default notificationRouter;
