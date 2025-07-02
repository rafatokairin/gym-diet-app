-- SCHEMA
CREATE SCHEMA IF NOT EXISTS rafalift;
SET search_path TO rafalift;

-- ======================================
-- ENUM TYPES
-- ======================================
-- Tipo ENUM para grupo muscular
CREATE TYPE rafalift.muscle_group AS ENUM (
  'chest',         -- peito
  'back',          -- costas
  'legs',          -- pernas
  'shoulders',     -- ombros
  'arms',          -- braços
  'abs',           -- abdômen
  'glutes',        -- glúteos
  'calves',        -- panturrilhas
  'full_body',     -- corpo inteiro
  'cardio',        -- cardiovascular
  'mobility',      -- mobilidade
  'other'          -- outro
);

-- Tipo ENUM para tipo de refeição
CREATE TYPE rafalift.meal_type AS ENUM (
  'pre_workout',     -- pré-treino
  'post_workout',    -- pós-treino
  'breakfast',       -- café da manhã
  'morning_snack',   -- lanche da manhã
  'lunch',           -- almoço
  'afternoon_snack', -- lanche da tarde
  'dinner',          -- jantar
  'supper',          -- ceia
  'other'            -- outro
);

-- ======================================
-- TABELA: USERS
-- ======================================
CREATE TABLE rafalift.users (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  senha VARCHAR(255) NOT NULL,
  data_reg TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  data_att TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  role VARCHAR(20) NOT NULL
);

-- ======================================
-- TABELA: WORKOUT CATEGORIES (Treinos fixos A-E)
-- ======================================
CREATE TABLE rafalift.workout_categories (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(1) UNIQUE
);

-- Seed dos treinos fixos
INSERT INTO rafalift.workout_categories (nome) VALUES 
('A'), ('B'), ('C'), ('D'), ('E');

-- ======================================
-- TABELA: DAYS CATEGORIES (Dias da semana)
-- ======================================
CREATE TABLE rafalift.days_categories (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(20) UNIQUE
);

-- Seed dos dias da semana
INSERT INTO rafalift.days_categories (nome) VALUES 
('Mon'), ('Tue'), ('Wed'), ('Thu'), ('Fri'), ('Sat'), ('Sun');

-- ======================================
-- TABELA: USER WORKOUTS (Agenda semanal de treinos)
-- ======================================
CREATE TABLE rafalift.user_workouts (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES rafalift.users(id) ON DELETE CASCADE,
  workout_id INT REFERENCES rafalift.workout_categories(id),
  UNIQUE(user_id, workout_id)
);

-- ======================================
-- TABELA: WORKOUT DAYS (Dias associados ao treinos)
-- ======================================
CREATE TABLE rafalift.workout_days (
  user_workouts_id INT REFERENCES rafalift.user_workouts(id) ON DELETE CASCADE,
  day_id INT REFERENCES rafalift.days_categories(id),
  UNIQUE(user_workouts_id, day_id)
);

-- ======================================
-- TABELA: EXERCISES (Exercícios do usuário por treino)
-- ======================================
CREATE TABLE rafalift.exercises (
  id SERIAL PRIMARY KEY,
  workout_id INT REFERENCES rafalift.user_workouts(id) ON DELETE CASCADE,
  grupo_muscular rafalift.muscle_group NOT NULL,
  nome VARCHAR(255) NOT NULL,
  peso INT,
  series INT,
  repeticoes INT,
  tempo INT,
  anotacao VARCHAR(100) NOT NULL
);

-- ======================================
-- TABELA: USER DIETS (Dieta por dia por usuário)
-- ======================================
CREATE TABLE rafalift.user_diets (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES rafalift.users(id) ON DELETE CASCADE,
  day_id INT REFERENCES rafalift.days_categories(id),
  UNIQUE(user_id, day_id)
);

-- ======================================
-- TABELA: FOODS (Alimentos da dieta por usuário)
-- ======================================
CREATE TABLE rafalift.foods (
  id SERIAL PRIMARY KEY,
  diet_id INT REFERENCES rafalift.user_diets(id) ON DELETE CASCADE,
  tipo_alimento rafalift.meal_type NOT NULL,
  alimento VARCHAR(255) NOT NULL,
  peso INT,
  carboidratos INT,
  proteinas INT,
  fibras INT,
  gorduras INT,
  calorias INT,
  anotacao VARCHAR(100) NOT NULL,
  horario TIME NOT NULL
);

-- ======================================
-- TABELA: USER GCD (Gasto calórico diário e metas por usuário)
-- ======================================
CREATE TABLE rafalift.user_gcd (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES rafalift.users(id) ON DELETE CASCADE,
  carboidratos_gcd INT,
  proteinas_gcd INT,
  fibras_gcd INT,
  gorduras_gcd INT,
  gcd INT,
  UNIQUE(user_id)
);

-- ======================================
-- TRIGGERS E FUNÇÕES
-- ======================================
-- Função para criar dietas automaticamente ao criar usuário
CREATE OR REPLACE FUNCTION rafalift.create_user_diets()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO rafalift.user_diets (user_id, day_id)
  SELECT NEW.id, id FROM rafalift.days_categories;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para executar após a criação do usuário
CREATE TRIGGER trg_create_user_diets
AFTER INSERT ON rafalift.users
FOR EACH ROW
EXECUTE FUNCTION rafalift.create_user_diets();

-- Função para criar treinos automaticamente ao criar usuário
CREATE OR REPLACE FUNCTION rafalift.create_user_workouts()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO rafalift.user_workouts (user_id, workout_id)
  SELECT NEW.id, id FROM rafalift.workout_categories;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para executar após a criação do usuário
CREATE TRIGGER trg_create_user_workouts
AFTER INSERT ON rafalift.users
FOR EACH ROW
EXECUTE FUNCTION rafalift.create_user_workouts();