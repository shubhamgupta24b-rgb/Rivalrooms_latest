'use strict';

const WIN_LINES = [
  [0,1,2],[3,4,5],[6,7,8],
  [0,3,6],[1,4,7],[2,5,8],
  [0,4,8],[2,4,6]
];
class GameActionError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
class TicTacToeService {
  constructor() { this.games = new Map(); }
  start(room) {
    if (room.status !== 'playing') throw new GameActionError('MATCH_NOT_STARTED', 'Start the room before playing.');
    if (room.gameId !== 'tic_tac_toe') throw new GameActionError('WRONG_GAME', 'This room is not a Tic Tac Toe match.');
    if (room.members.length !== 2) throw new GameActionError('INVALID_PLAYERS', 'Tic Tac Toe requires exactly two players.');
    const state = { roomId: room.id, board: Array(9).fill(null), players: room.members.map((m) => m.playerId),
      turn: room.members[0].playerId, status: 'playing', winner: null, version: 1 };
    this.games.set(room.id, state);
    return this.snapshot(state);
  }
  move(room, playerId, index, expectedVersion) {
    const state = this.games.get(room.id);
    if (!state) throw new GameActionError('GAME_NOT_INITIALIZED', 'The game has not been initialized.');
    if (room.status !== 'playing') throw new GameActionError('MATCH_NOT_ACTIVE', 'This match is not active.');
    if (state.status !== 'playing') throw new GameActionError('GAME_OVER', 'This game has already finished.');
    if (!state.players.includes(playerId)) throw new GameActionError('NOT_A_PLAYER', 'You are not playing this match.');
    if (playerId !== state.turn) throw new GameActionError('NOT_YOUR_TURN', 'Wait for your turn.');
    if (!Number.isInteger(index) || index < 0 || index > 8) throw new GameActionError('INVALID_MOVE', 'Select a board cell from 0 to 8.');
    if (expectedVersion !== state.version) throw new GameActionError('STALE_STATE', 'The board changed. Refresh before moving.');
    if (state.board[index] !== null) throw new GameActionError('CELL_TAKEN', 'That cell is already occupied.');
    const mark = state.players[0] === playerId ? 'X' : 'O';
    state.board[index] = mark;
    state.version += 1;
    const line = WIN_LINES.find(([a,b,c]) => state.board[a] && state.board[a] === state.board[b] && state.board[b] === state.board[c]);
    if (line) { state.status = 'finished'; state.winner = playerId; }
    else if (state.board.every(Boolean)) state.status = 'draw';
    else state.turn = state.players.find((id) => id !== playerId);
    return this.snapshot(state);
  }
  snapshot(state) { return { roomId: state.roomId, board: [...state.board], players: [...state.players],
    turn: state.turn, status: state.status, winner: state.winner, version: state.version }; }
}
module.exports = { TicTacToeService, GameActionError };
