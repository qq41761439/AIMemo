import { createServer } from './server.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const app = await createServer({ config });

await app.listen({ port: config.port, host: config.host });
