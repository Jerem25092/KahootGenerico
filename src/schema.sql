-- =========================================================
--  TeamKahoot Python — Schema v2
--  Run once:
--  psql "postgresql://..." -f schema.sql
-- =========================================================

DROP TABLE IF EXISTS player_answers   CASCADE;
DROP TABLE IF EXISTS session_players  CASCADE;
DROP TABLE IF EXISTS game_sessions    CASCADE;
DROP TABLE IF EXISTS questions        CASCADE;
DROP TABLE IF EXISTS topics           CASCADE;
DROP TABLE IF EXISTS users            CASCADE;

-- ---------------------------------------------------------
--  USERS
--  avatar: entero 1-8 (cada número = un emoji distinto en el frontend)
-- ---------------------------------------------------------
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  username      VARCHAR(50)  UNIQUE NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar        SMALLINT     DEFAULT 1 CHECK (avatar BETWEEN 1 AND 8),
  games_played  INTEGER      DEFAULT 0,
  games_won     INTEGER      DEFAULT 0,
  total_score   BIGINT       DEFAULT 0,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  last_seen     TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX idx_users_email    ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- ---------------------------------------------------------
--  TOPICS  (3 salas)
--  icon_code: entero que el frontend convierte a emoji
--    1=🌍  2=🔬  3=🎬
--  color_code: entero
--    1=#2196F3  2=#4CAF50  3=#FF5722
-- ---------------------------------------------------------
CREATE TABLE topics (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  icon_code   SMALLINT     DEFAULT 1,
  color_code  SMALLINT     DEFAULT 1,
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

-- ---------------------------------------------------------
--  QUESTIONS
--  options: JSONB array de 4 strings ["A","B","C","D"]
--  correct_answer: índice 0-3
--  difficulty_level: 1=fácil  2=medio  3=difícil
-- ---------------------------------------------------------
CREATE TABLE questions (
  id              SERIAL PRIMARY KEY,
  topic_id        INTEGER    REFERENCES topics(id) ON DELETE CASCADE,
  question_text   TEXT       NOT NULL,
  options         JSONB      NOT NULL,
  correct_answer  SMALLINT   NOT NULL CHECK (correct_answer BETWEEN 0 AND 3),
  time_limit      SMALLINT   DEFAULT 20,
  points          INTEGER    DEFAULT 1000,
  difficulty_level SMALLINT  DEFAULT 2 CHECK (difficulty_level BETWEEN 1 AND 3),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_questions_topic ON questions(topic_id);

-- ---------------------------------------------------------
--  GAME SESSIONS
--  winner_team: 0=empate  1=Equipo A  2=Equipo B
-- ---------------------------------------------------------
CREATE TABLE game_sessions (
  id              SERIAL PRIMARY KEY,
  room_code       VARCHAR(10)  NOT NULL,
  topic_id        INTEGER      REFERENCES topics(id),
  host_user_id    INTEGER      REFERENCES users(id),
  host_name       VARCHAR(50),
  total_questions SMALLINT,
  team_a_score    INTEGER      DEFAULT 0,
  team_b_score    INTEGER      DEFAULT 0,
  winner_team     SMALLINT     DEFAULT 0,
  player_count    SMALLINT     DEFAULT 0,
  started_at      TIMESTAMPTZ  DEFAULT NOW(),
  ended_at        TIMESTAMPTZ
);

-- ---------------------------------------------------------
--  SESSION PLAYERS
-- ---------------------------------------------------------
CREATE TABLE session_players (
  id              SERIAL PRIMARY KEY,
  session_id      INTEGER  REFERENCES game_sessions(id) ON DELETE CASCADE,
  user_id         INTEGER  REFERENCES users(id),
  guest_name      VARCHAR(50),
  team            SMALLINT NOT NULL CHECK (team IN (1,2)),  -- 1=A 2=B
  final_score     INTEGER  DEFAULT 0,
  correct_answers SMALLINT DEFAULT 0,
  is_host         BOOLEAN  DEFAULT FALSE,
  played_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------
--  PLAYER ANSWERS
-- ---------------------------------------------------------
CREATE TABLE player_answers (
  id            SERIAL PRIMARY KEY,
  session_id    INTEGER   REFERENCES game_sessions(id) ON DELETE CASCADE,
  user_id       INTEGER   REFERENCES users(id),
  question_id   INTEGER   REFERENCES questions(id),
  answer_index  SMALLINT,          -- -1 = sin respuesta
  is_correct    BOOLEAN   DEFAULT FALSE,
  points_earned INTEGER   DEFAULT 0,
  response_ms   INTEGER,           -- milisegundos en responder
  answered_at   TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================
--  DATOS INICIALES — TEMAS
-- =========================================================
INSERT INTO topics (name, description, icon_code, color_code) VALUES
('Geografía Mundial',      'Países, capitales, ríos y montañas del mundo',        1, 1),
('Ciencia y Tecnología',   'Física, química, biología e informática',              2, 2),
('Cine y Entretenimiento', 'Películas, música, series y cultura popular',          3, 3);

-- =========================================================
--  PREGUNTAS — TEMA 1: GEOGRAFÍA
-- =========================================================
INSERT INTO questions (topic_id,question_text,options,correct_answer,time_limit,difficulty_level) VALUES
(1,'¿Cuál es el río más largo del mundo?',
 '["Amazonas","Nilo","Misisipi","Yangtsé"]',1,20,2),
(1,'¿Cuál es el país más grande del mundo por superficie terrestre?',
 '["Canadá","China","Rusia","Estados Unidos"]',2,20,1),
(1,'¿Cuál es la capital de Australia?',
 '["Sydney","Melbourne","Brisbane","Canberra"]',3,20,2),
(1,'¿Cuál es el océano más grande del mundo?',
 '["Atlántico","Índico","Pacífico","Ártico"]',2,20,1),
(1,'¿Cuántos países tiene el continente africano?',
 '["48","54","60","42"]',1,25,3),
(1,'¿Cuál es la montaña más alta del mundo?',
 '["K2","Mont Blanc","Aconcagua","Monte Everest"]',3,20,1),
(1,'¿Cuál es el país más pequeño del mundo?',
 '["Mónaco","San Marino","Ciudad del Vaticano","Liechtenstein"]',2,20,2),
(1,'¿En qué continente está el desierto del Sahara?',
 '["Asia","África","América del Sur","Australia"]',1,20,1),
(1,'¿Cuál es el lago más grande del mundo por superficie?',
 '["Lago Superior","Lago Victoria","Mar Caspio","Lago Hurón"]',2,25,3),
(1,'¿Cuál es la ciudad más poblada del mundo?',
 '["Delhi","Ciudad de México","Tokio","Shanghai"]',2,20,2),
(1,'¿Qué país tiene más fronteras terrestres con otros países?',
 '["China","Rusia","Brasil","Alemania"]',1,25,3),
(1,'¿Cuál es la cascada más alta del mundo?',
 '["Cataratas del Niágara","Salto del Ángel","Cataratas Victoria","Cataratas Iguazú"]',1,20,2);

-- =========================================================
--  PREGUNTAS — TEMA 2: CIENCIA Y TECNOLOGÍA
-- =========================================================
INSERT INTO questions (topic_id,question_text,options,correct_answer,time_limit,difficulty_level) VALUES
(2,'¿A qué velocidad aproximada viaja la luz en el vacío?',
 '["150 000 km/s","300 000 km/s","500 000 km/s","250 000 km/s"]',1,20,2),
(2,'¿Cuántos elementos tiene la tabla periódica actualmente?',
 '["112","115","118","120"]',2,20,2),
(2,'¿Cuál es el planeta más grande del sistema solar?',
 '["Saturno","Júpiter","Neptuno","Urano"]',1,20,1),
(2,'¿Cuánto tarda la luz del Sol en llegar a la Tierra?',
 '["4 minutos","8 minutos","12 minutos","1 minuto"]',1,20,2),
(2,'¿Qué partícula subatómica tiene carga positiva?',
 '["Electrón","Neutrón","Fotón","Protón"]',3,20,1),
(2,'¿En qué año fue lanzado el primer iPhone?',
 '["2005","2006","2007","2008"]',2,20,2),
(2,'¿Qué significa la sigla ADN?',
 '["Ácido Desoxirribonucleico","Ácido Deoxyribonico Natural","Aminoácido Desoxirribonucleico","Ácido Dinucleico Natural"]',0,25,2),
(2,'¿Quién formuló la Teoría General de la Relatividad?',
 '["Isaac Newton","Stephen Hawking","Albert Einstein","Nikola Tesla"]',2,20,1),
(2,'¿Cuántos huesos tiene el cuerpo humano adulto?',
 '["186","206","226","196"]',1,20,2),
(2,'¿Cuál es el elemento más abundante en el universo?',
 '["Oxígeno","Helio","Hidrógeno","Carbono"]',2,20,2),
(2,'¿Qué empresa desarrolló Android?',
 '["Apple","Microsoft","Google","Samsung"]',2,20,1),
(2,'¿En qué año se fundó SpaceX?',
 '["2000","2002","2004","2006"]',1,25,3);

-- =========================================================
--  PREGUNTAS — TEMA 3: CINE Y ENTRETENIMIENTO
-- =========================================================
INSERT INTO questions (topic_id,question_text,options,correct_answer,time_limit,difficulty_level) VALUES
(3,'¿Quién dirigió la película Titanic (1997)?',
 '["Steven Spielberg","Christopher Nolan","James Cameron","Martin Scorsese"]',2,20,1),
(3,'¿En qué año se estrenó la primera película de Star Wars?',
 '["1975","1977","1979","1981"]',1,20,2),
(3,'¿Qué actor interpretó a Jack Sparrow en Piratas del Caribe?',
 '["Brad Pitt","Tom Hanks","Will Smith","Johnny Depp"]',3,20,1),
(3,'¿Cuántas películas tiene la saga principal de Harry Potter?',
 '["6","7","8","9"]',2,20,1),
(3,'¿Qué banda compuso Bohemian Rhapsody?',
 '["The Beatles","Led Zeppelin","Queen","Rolling Stones"]',2,20,1),
(3,'¿En qué año se fundó Netflix?',
 '["1995","1997","2000","2003"]',1,20,2),
(3,'¿Quién creó a los personajes de Los Simpsons?',
 '["Seth MacFarlane","Matt Groening","Trey Parker","Mike Judge"]',1,20,2),
(3,'¿En qué país se produce principalmente el anime?',
 '["China","Corea del Sur","Japón","Estados Unidos"]',2,20,1),
(3,'¿Quién es el protagonista de El Señor de los Anillos?',
 '["Gandalf","Aragorn","Frodo Bolsón","Legolas"]',2,20,1),
(3,'¿En qué año se lanzó YouTube?',
 '["2003","2004","2005","2006"]',2,20,2),
(3,'¿Cuántas temporadas tiene Breaking Bad?',
 '["4","5","6","7"]',1,20,2),
(3,'¿Qué película de Pixar presenta a WALL-E?',
 '["Ratatouille","Cars","WALL-E","Up"]',2,20,1);

-- =========================================================
--  VISTA ÚTIL: leaderboard
-- =========================================================
CREATE OR REPLACE VIEW leaderboard AS
SELECT username, total_score, games_played, games_won,
  ROUND(games_won::NUMERIC / NULLIF(games_played,0)*100,1) AS win_pct
FROM users ORDER BY total_score DESC;
