import { createServer } from './server.js';

const app = await createServer();
const port = parseInt(process.env.PORT ?? '8787', 10);

await app.listen({ port, host: '0.0.0.0' });
