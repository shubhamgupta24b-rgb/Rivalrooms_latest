'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { TicTacToeService } = require('../src/games/tic_tac_toe');
const room = { id: 'room-1', gameId: 'tic_tac_toe', status: 'playing',
  members: [{ playerId: 'player_0001' }, { playerId: 'player_0002' }] };
test('enforces alternating turns and rejects stale or occupied moves', () => {
  const game = new TicTacToeService(); game.start(room);
  assert.throws(() => game.move(room, 'player_0002', 0, 1), (e) => e.code === 'NOT_YOUR_TURN');
  game.move(room, 'player_0001', 0, 1);
  assert.throws(() => game.move(room, 'player_0002', 0, 2), (e) => e.code === 'CELL_TAKEN');
  assert.throws(() => game.move(room, 'player_0002', 1, 1), (e) => e.code === 'STALE_STATE');
});
test('detects a winner and prevents moves after game over', () => {
  const game = new TicTacToeService(); game.start(room);
  let s = game.move(room, 'player_0001', 0, 1);
  s = game.move(room, 'player_0002', 3, 2);
  s = game.move(room, 'player_0001', 1, 3);
  s = game.move(room, 'player_0002', 4, 4);
  s = game.move(room, 'player_0001', 2, 5);
  assert.equal(s.status, 'finished'); assert.equal(s.winner, 'player_0001');
  assert.throws(() => game.move(room, 'player_0002', 5, 6), (e) => e.code === 'GAME_OVER');
});
test('detects a draw', () => {
  const game = new TicTacToeService(); game.start(room);
  const moves = [[0,0],[1,1],[2,0],[4,1],[3,0],[5,1],[7,0],[6,1],[8,0]];
  let s;
  for (const [cell, playerIndex] of moves) {
    const player = room.members[playerIndex].playerId;
    s = game.move(room, player, cell, s ? s.version : 1);
  }
  assert.equal(s.status, 'draw'); assert.equal(s.winner, null);
});
