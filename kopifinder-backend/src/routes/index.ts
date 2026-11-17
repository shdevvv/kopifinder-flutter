import { Router } from 'express';
import healthRouter from './health.routes';
import syncRouter from './sync.routes';

const apiRouter = Router();

apiRouter.use('/health', healthRouter);
apiRouter.use('/sync', syncRouter);

export default apiRouter;
