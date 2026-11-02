ALTER TABLE leaderboard_entries DROP CONSTRAINT IF EXISTS leaderboard_entries_match_id_key;
CREATE UNIQUE INDEX IF NOT EXISTS leaderboard_match_player_unique
  ON leaderboard_entries (match_id, player_id);
