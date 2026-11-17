import { createApp } from './app';
import { config } from './config/env';

const app = createApp();

const server = app.listen(config.port, () => {
  console.log(`[KopiFinder Backend] Server running on port ${config.port} (${config.env} mode)`);
  console.log(`[KopiFinder Backend] Health Check: http://localhost:${config.port}/api/v1/health`);
});

// Handle graceful shutdown
const gracefulShutdown = (signal: string) => {
  console.log(`[KopiFinder Backend] Received ${signal}. Shutting down gracefully...`);
  server.close(() => {
    console.log('[KopiFinder Backend] HTTP server closed.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
