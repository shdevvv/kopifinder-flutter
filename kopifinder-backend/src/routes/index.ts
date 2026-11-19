import { Router } from 'express';
import healthRouter from './health.routes';
import syncRouter from './sync.routes';
import usersRouter from './users.routes';
import authRouter from './auth.routes';
import catalogRouter from './catalog.routes';
import engagementRouter from './engagement.routes';
import communityRouter from './community.routes';
import offersRouter from './offers.routes';
import aiRouter from './ai.routes';

const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/health', healthRouter);
apiRouter.use('/sync', syncRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/', catalogRouter);
apiRouter.use('/', engagementRouter);
apiRouter.use('/', communityRouter);
apiRouter.use('/offers', offersRouter);
apiRouter.use('/ai', aiRouter);

export default apiRouter;
