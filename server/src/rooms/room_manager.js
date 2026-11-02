'use strict';

const { randomInt, randomUUID } = require('node:crypto');

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class RoomError extends Error {
  constructor(code, message) { super(message); this.name = 'RoomError'; this.code = code; }
}

class RoomManager {
  constructor({ maxMembers = 10, codeLength = 6, reconnectGraceMs = 60000, now = Date.now } = {}) {
    this.maxMembers = maxMembers;
    this.codeLength = codeLength;
    this.reconnectGraceMs = reconnectGraceMs;
    this.now = now;
    this.rooms = new Map();
    this.codeToRoomId = new Map();
    this.socketToRoom = new Map();
  }

  _newCode() {
    for (let attempt = 0; attempt < 100; attempt += 1) {
      let code = '';
      for (let i = 0; i < this.codeLength; i += 1) code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
      if (!this.codeToRoomId.has(code)) return code;
    }
    throw new RoomError('ROOM_CAPACITY', 'Could not allocate a room code. Try again.');
  }

  create({ playerId, displayName, gameId, maxMembers = this.maxMembers }) {
    this._validatePlayer(playerId, displayName);
    if (typeof gameId !== 'string' || !/^[a-z0-9_]{2,48}$/.test(gameId)) {
      throw new RoomError('INVALID_GAME', 'Choose a valid game.');
    }
    if (!Number.isInteger(maxMembers) || maxMembers < 2 || maxMembers > this.maxMembers) {
      throw new RoomError('INVALID_CAPACITY', 'Room capacity must be between 2 and 10.');
    }
    const roomId = randomUUID();
    const code = this._newCode();
    const member = this._member({ playerId, displayName, isHost: true });
    const room = {
      id: roomId, code, gameId, maxMembers, hostId: playerId,
      status: 'waiting', version: 1, createdAt: this.now(),
      members: new Map([[playerId, member]]), commands: new Set()
    };
    this.rooms.set(roomId, room);
    this.codeToRoomId.set(code, roomId);
    return this.snapshot(room);
  }

  join({ code, playerId, displayName, socketId }) {
    this._validatePlayer(playerId, displayName);
    const normalizedCode = String(code || '').trim().toUpperCase();
    const roomId = this.codeToRoomId.get(normalizedCode);
    const room = roomId && this.rooms.get(roomId);
    if (!room) throw new RoomError('ROOM_NOT_FOUND', 'That room code was not found.');
    if (room.status !== 'waiting') throw new RoomError('ROOM_STARTED', 'This match has already started.');
    if (!room.members.has(playerId) && room.members.size >= room.maxMembers) {
      throw new RoomError('ROOM_FULL', 'This room is full.');
    }
    const existing = room.members.get(playerId);
    const member = existing || this._member({ playerId, displayName, isHost: false });
    member.displayName = displayName.trim();
    member.connected = true;
    member.socketId = socketId || null;
    member.disconnectedAt = null;
    room.members.set(playerId, member);
    if (socketId) this.socketToRoom.set(socketId, room.id);
    room.version += 1;
    return this.snapshot(room);
  }

  attachSocket(roomId, playerId, socketId) {
    const room = this._getRoom(roomId);
    const member = room.members.get(playerId);
    if (!member) throw new RoomError('NOT_A_MEMBER', 'Join this room before connecting.');
    if (member.socketId) this.socketToRoom.delete(member.socketId);
    member.socketId = socketId;
    member.connected = true;
    member.disconnectedAt = null;
    this.socketToRoom.set(socketId, room.id);
    room.version += 1;
    return this.snapshot(room);
  }

  setReady(roomId, playerId, ready) {
    const room = this._getRoom(roomId);
    const member = this._getMember(room, playerId);
    if (room.status !== 'waiting') throw new RoomError('MATCH_STARTED', 'The match has already started.');
    if (typeof ready !== 'boolean') throw new RoomError('INVALID_READY', 'Ready must be true or false.');
    member.ready = ready;
    room.version += 1;
    return this.snapshot(room);
  }

  start(roomId, playerId) {
    const room = this._getRoom(roomId);
    if (room.hostId !== playerId) throw new RoomError('HOST_ONLY', 'Only the room host can start the match.');
    if (room.status !== 'waiting') throw new RoomError('MATCH_STARTED', 'The match has already started.');
    if (room.members.size < 2) throw new RoomError('NEED_PLAYERS', 'At least two players are required.');
    if ([...room.members.values()].some((m) => !m.ready && m.playerId !== room.hostId)) {
      throw new RoomError('PLAYERS_NOT_READY', 'Wait for every player to be ready.');
    }
    room.status = 'playing';
    room.version += 1;
    return this.snapshot(room);
  }

  disconnect(socketId) {
    const roomId = this.socketToRoom.get(socketId);
    if (!roomId) return null;
    this.socketToRoom.delete(socketId);
    const room = this.rooms.get(roomId);
    if (!room) return null;
    const member = [...room.members.values()].find((m) => m.socketId === socketId);
    if (!member) return null;
    member.connected = false;
    member.socketId = null;
    member.disconnectedAt = this.now();
    room.version += 1;
    return this.snapshot(room);
  }

  leave(roomId, playerId) {
    const room = this._getRoom(roomId);
    const member = this._getMember(room, playerId);
    if (member.socketId) this.socketToRoom.delete(member.socketId);
    room.members.delete(playerId);
    if (room.members.size === 0) {
      this._deleteRoom(room);
      return null;
    }
    if (room.hostId === playerId) {
      const next = [...room.members.values()].sort((a, b) => a.joinedAt - b.joinedAt)[0];
      next.isHost = true;
      room.hostId = next.playerId;
    }
    room.version += 1;
    return this.snapshot(room);
  }

  sweepExpired() {
    const cutoff = this.now() - this.reconnectGraceMs;
    const removed = [];
    for (const room of this.rooms.values()) {
      for (const member of room.members.values()) {
        if (!member.connected && member.disconnectedAt !== null && member.disconnectedAt <= cutoff) {
          removed.push({ roomId: room.id, playerId: member.playerId });
          room.members.delete(member.playerId);
          if (room.hostId === member.playerId && room.members.size) {
            const next = [...room.members.values()].sort((a, b) => a.joinedAt - b.joinedAt)[0];
            next.isHost = true;
            room.hostId = next.playerId;
          }
        }
      }
      room.version += 1;
      if (room.members.size === 0) this._deleteRoom(room);
    }
    return removed;
  }

  getByCode(code) {
    const id = this.codeToRoomId.get(String(code || '').trim().toUpperCase());
    const room = id && this.rooms.get(id);
    return room ? this.snapshot(room) : null;
  }

  snapshot(room) {
    return {
      id: room.id, code: room.code, gameId: room.gameId, maxMembers: room.maxMembers,
      hostId: room.hostId, status: room.status, version: room.version,
      members: [...room.members.values()].map(({ playerId, displayName, isHost, ready, connected, joinedAt }) =>
        ({ playerId, displayName, isHost, ready, connected, joinedAt }))
    };
  }

  _member({ playerId, displayName, isHost }) {
    return { playerId, displayName: displayName.trim(), isHost, ready: Boolean(isHost),
      connected: true, socketId: null, disconnectedAt: null, joinedAt: this.now() };
  }
  _validatePlayer(playerId, displayName) {
    if (typeof playerId !== 'string' || !/^[a-zA-Z0-9_-]{8,80}$/.test(playerId)) {
      throw new RoomError('INVALID_PLAYER', 'A valid player session is required.');
    }
    if (typeof displayName !== 'string' || displayName.trim().length < 1 || displayName.trim().length > 24) {
      throw new RoomError('INVALID_NAME', 'Display name must be 1–24 characters.');
    }
  }
  _getRoom(roomId) {
    const room = this.rooms.get(roomId);
    if (!room) throw new RoomError('ROOM_NOT_FOUND', 'That room no longer exists.');
    return room;
  }
  _getMember(room, playerId) {
    const member = room.members.get(playerId);
    if (!member) throw new RoomError('NOT_A_MEMBER', 'You are not a member of this room.');
    return member;
  }
  _deleteRoom(room) {
    this.rooms.delete(room.id);
    this.codeToRoomId.delete(room.code);
    for (const member of room.members.values()) if (member.socketId) this.socketToRoom.delete(member.socketId);
  }
}

module.exports = { RoomManager, RoomError };
