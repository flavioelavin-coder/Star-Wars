-- =====================================================================
-- PROYECTO: The Galaxy's Logistics & Operations Insight
-- Plataforma: Google Cloud Platform · BigQuery
-- =====================================================================
-- PASO 0 — Prerrequisito (hacer en la Consola de GCP, no en este script):
--   1. Crea un proyecto GCP (o usa uno existente).
--   2. Abre BigQuery Studio > crea un dataset llamado `swapi_bi`.
--   3. Sube los 3 archivos people.csv, planets.csv, starships.csv a un
--      bucket de Cloud Storage (gs://<tu-bucket>/swapi/) o directamente
--      con "Create Table > Upload" en la consola de BigQuery.
-- =====================================================================

-- 1. TABLAS RAW (carga directa de los CSV, autodetect de esquema)
--    Si subes por consola: "Create Table" -> Source: Upload ->
--    Schema: Auto detect -> Destination table: swapi_bi.raw_<tabla>
--    Si prefieres cargar por bq CLI:
--
--    bq load --autodetect --source_format=CSV \
--      swapi_bi.raw_people gs://<tu-bucket>/swapi/people.csv
--    bq load --autodetect --source_format=CSV \
--      swapi_bi.raw_planets gs://<tu-bucket>/swapi/planets.csv
--    bq load --autodetect --source_format=CSV \
--      swapi_bi.raw_starships gs://<tu-bucket>/swapi/starships.csv

-- 2. CAPA DE TRANSFORMACIÓN (staging limpio)
--    Normaliza texto (lower/trim) para evitar la anomalía de
--    fragmentación de categorías (ver Hallazgo #4 de la presentación).

CREATE OR REPLACE TABLE swapi_bi.stg_starships AS
SELECT
  id,
  name,
  model,
  manufacturer,
  LOWER(TRIM(starship_class)) AS starship_class,      -- normalizado
  SAFE_CAST(REGEXP_REPLACE(cost_in_credits, r'[^0-9.]', '') AS FLOAT64) AS cost_in_credits,
  SAFE_CAST(REGEXP_REPLACE(cargo_capacity, r'[^0-9.]', '')  AS FLOAT64) AS cargo_capacity,
  SAFE_CAST(REGEXP_REPLACE(passengers, r'[^0-9.]', '')      AS FLOAT64) AS passengers,
  crew,
  SAFE_CAST(REGEXP_REPLACE(length, r'[^0-9.]', '')          AS FLOAT64) AS length_m,
  SAFE_CAST(REGEXP_REPLACE(max_atmosphering_speed, r'[^0-9.]', '') AS FLOAT64) AS max_speed,
  SAFE_CAST(hyperdrive_rating AS FLOAT64) AS hyperdrive_rating,
  SAFE_CAST(MGLT AS FLOAT64) AS mglt,
  n_pilots
FROM swapi_bi.raw_starships;

CREATE OR REPLACE TABLE swapi_bi.stg_planets AS
SELECT
  id,
  name,
  LOWER(TRIM(climate)) AS climate,
  LOWER(TRIM(terrain)) AS terrain,
  SAFE_CAST(REGEXP_REPLACE(population, r'[^0-9.]', '') AS FLOAT64) AS population,
  SAFE_CAST(diameter AS FLOAT64) AS diameter,
  gravity,
  SAFE_CAST(orbital_period AS FLOAT64) AS orbital_period,
  SAFE_CAST(rotation_period AS FLOAT64) AS rotation_period,
  SAFE_CAST(surface_water AS FLOAT64) AS surface_water
FROM swapi_bi.raw_planets;

CREATE OR REPLACE TABLE swapi_bi.stg_people AS
SELECT
  id,
  name,
  LOWER(TRIM(gender)) AS gender,
  birth_year,
  SAFE_CAST(height AS FLOAT64) AS height,
  SAFE_CAST(mass AS FLOAT64) AS mass,
  homeworld_id,
  homeworld_name,
  species,
  is_pilot,
  n_starships_piloted
FROM swapi_bi.raw_people;

-- 3. VISTAS DE NEGOCIO (una por pregunta del reto)

-- Q1: Eficiencia costo/pasajero para planear evacuación
CREATE OR REPLACE VIEW swapi_bi.v_fleet_efficiency AS
SELECT
  name, model, starship_class, cost_in_credits, passengers,
  ROUND(cost_in_credits / NULLIF(passengers, 0), 2) AS cost_per_passenger
FROM swapi_bi.stg_starships
WHERE cost_in_credits IS NOT NULL AND passengers > 0
ORDER BY cost_per_passenger ASC;

-- Q2: Distribución de especie/género por planeta natal + tasa de pilotos
CREATE OR REPLACE VIEW swapi_bi.v_talent_by_homeworld AS
SELECT
  homeworld_name,
  COUNT(*) AS total_personas,
  COUNT(DISTINCT species) AS especies_distintas,
  SUM(is_pilot) AS pilotos,
  ROUND(SUM(is_pilot) / COUNT(*) * 100, 1) AS pct_pilotos
FROM swapi_bi.stg_people
GROUP BY homeworld_name
ORDER BY total_personas DESC;

-- Q3: Inversión por clúster de starship_class (ya normalizado)
CREATE OR REPLACE VIEW swapi_bi.v_investment_by_class AS
SELECT
  starship_class,
  COUNT(*) AS n_naves,
  ROUND(AVG(cost_in_credits), 0) AS costo_medio,
  SUM(n_pilots) AS pilotos_activos
FROM swapi_bi.stg_starships
GROUP BY starship_class
ORDER BY n_naves DESC;

-- Q4: Evidencia de la anomalía (comparar clase raw vs. normalizada)
CREATE OR REPLACE VIEW swapi_bi.v_data_quality_anomaly AS
SELECT
  LOWER(TRIM(starship_class)) AS class_normalizado,
  COUNT(DISTINCT starship_class) AS variantes_de_texto_encontradas,
  STRING_AGG(DISTINCT starship_class, ' | ') AS variantes
FROM swapi_bi.raw_starships
GROUP BY class_normalizado
HAVING COUNT(DISTINCT starship_class) > 1;

-- =====================================================================
-- Estas 4 vistas (v_fleet_efficiency, v_talent_by_homeworld,
-- v_investment_by_class, v_data_quality_anomaly) son las que se
-- conectan directamente como fuente de datos en Looker Studio.
-- =====================================================================
