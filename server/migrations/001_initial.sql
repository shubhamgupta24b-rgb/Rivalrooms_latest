CREATE TABLE IF NOT EXISTS player_profiles (
  player_id VARCHAR(80) PRIMARY KEY,
  display_name VARCHAR(24) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS leaderboard_entries (
  id BIGSERIAL PRIMARY KEY,
  player_id VARCHAR(80) NOT NULL REFERENCES player_profiles(player_id) ON DELETE CASCADE,
  game_id VARCHAR(48) NOT NULL,
  score BIGINT NOT NULL,
  match_id UUID NOT NULL UNIQUE,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS leaderboard_game_score_idx
  ON leaderboard_entries (game_id, score DESC, created_at ASC);
CREATE INDEX IF NOT EXISTS leaderboard_player_game_idx
  ON leaderboard_entries (player_id, game_id, score DESC);
