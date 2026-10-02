import {Router} from 'express';
import {
    getPosts,
    getPostsForWorker,
    getPost,
    getPostsByUserId,
    createPost,
    deletePost,
    updatePost,
    addPostPhotos
} from '../controllers/postController.js';
import { requireActiveUser } from '../utils/requireActiveUser.js';

const postRouter = Router ();

postRouter.get('/api/posts', getPosts);
postRouter.get('/api/postsForWorker/:workerId', getPostsForWorker);
postRouter.get('/api/post/:id', getPost);
postRouter.get('/api/postsByUserId/:id', getPostsByUserId);
postRouter.post('/api/post', requireActiveUser((req) => req.body?.clientId), createPost);
postRouter.delete('/api/post/:id', deletePost);
postRouter.put('/api/post/:id', updatePost);
postRouter.post('/api/postPhotos/:id', addPostPhotos);

export default postRouter;
