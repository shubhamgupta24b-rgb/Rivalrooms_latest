'use strict';

const express = require('express');
const http = require('node:http');
const { Server } = require('socket.io');

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));

app.get('/health', (_req, res) => {
  res.status(200).json({ ok: true, service: 'rivalrooms-latest-api', version: '0.1.0' });
});

const server = http.createServer(app);
const origins = (process.env.CLIENT_ORIGINS || 'http://localhost:3000')
  .split(',').map((value) => value.trim()).filter(Boolean);

const io = new Server(server, {
  cors: { origin: origins, methods: ['GET', 'POST'] },
  maxHttpBufferSize: 64 * 1024,
  transports: ['websocket', 'polling']
});

// Phase-0 transport placeholder. Game actions are intentionally not accepted until
// authentication, room membership and authoritative reducers are implemented.
io.on('connection', (socket) => {
  socket.emit('server:hello', { service: 'rivalrooms-latest', protocolVersion: 1 });
});

const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  server.listen(port, '0.0.0.0', () => {
    console.log(JSON.stringify({ level: 'info', event: 'server_listening', port }));
  });
}

module.exports = { app, server, io };
