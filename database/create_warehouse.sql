-- =============================================================
-- DATA WAREHOUSE - OLAP CUBE SCHEMA
-- =============================================================

-- Drop existing database if it exists
DROP DATABASE IF EXISTS DataWarehouse;
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- =============================================================
-- DIMENSION TABLES
-- =============================================================

-- Dimension: Time
CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    graduation_date DATE NOT NULL,
    years_since_graduation INT NOT NULL,
    graduation_year INT,
    graduation_month INT,
    graduation_quarter INT
);

-- Dimension: Candidate
CREATE TABLE dim_candidate (
    candidate_id INT PRIMARY KEY,
    age INT NOT NULL,
    gender VARCHAR(50),
    country_of_origin VARCHAR(100)
);

-- Dimension: Skills
CREATE TABLE dim_skills (
    skills_id INT PRIMARY KEY,
    language_proficiency VARCHAR(50),
    internship_experience VARCHAR(10)
);

-- =============================================================
-- FACT TABLE (OLAP Cube)
-- =============================================================

CREATE TABLE fact_candidates (
    fact_id INT PRIMARY KEY AUTO_INCREMENT,
    candidate_id INT NOT NULL,
    time_id INT NOT NULL,
    skills_id INT NOT NULL,
    -- Measures
    count_candidates INT DEFAULT 1,
    avg_age DECIMAL(5,2),
    has_internship INT,
    FOREIGN KEY (candidate_id) REFERENCES dim_candidate(candidate_id),
    FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (skills_id) REFERENCES dim_skills(skills_id),
    INDEX idx_candidate (candidate_id),
    INDEX idx_time (time_id),
    INDEX idx_skills (skills_id)
);

-- =============================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================================

CREATE INDEX idx_dim_time_year ON dim_time(graduation_year);
CREATE INDEX idx_dim_time_quarter ON dim_time(graduation_quarter);
CREATE INDEX idx_dim_candidate_country ON dim_candidate(country_of_origin);
CREATE INDEX idx_dim_candidate_gender ON dim_candidate(gender);
CREATE INDEX idx_dim_skills_proficiency ON dim_skills(language_proficiency);

-- =============================================================
-- VIEWS FOR ANALYSIS
-- =============================================================

-- Vista: Análisis por país y proficiencia de idioma
CREATE VIEW vw_analysis_country_language AS
SELECT 
    c.country_of_origin,
    s.language_proficiency,
    COUNT(DISTINCT f.candidate_id) AS total_candidates,
    AVG(c.age) AS avg_age,
    SUM(CASE WHEN s.internship_experience = 'Yes' THEN 1 ELSE 0 END) AS with_internship
FROM fact_candidates f
JOIN dim_candidate c ON f.candidate_id = c.candidate_id
JOIN dim_skills s ON f.skills_id = s.skills_id
GROUP BY c.country_of_origin, s.language_proficiency;

-- Vista: Análisis por año de graduación
CREATE VIEW vw_analysis_by_year AS
SELECT 
    t.graduation_year,
    COUNT(DISTINCT f.candidate_id) AS total_candidates,
    AVG(c.age) AS avg_age,
    COUNT(DISTINCT c.gender) AS gender_types
FROM fact_candidates f
JOIN dim_time t ON f.time_id = t.time_id
JOIN dim_candidate c ON f.candidate_id = c.candidate_id
GROUP BY t.graduation_year
ORDER BY t.graduation_year;

-- Vista: Top países con más candidatos
CREATE VIEW vw_top_countries AS
SELECT 
    c.country_of_origin,
    COUNT(DISTINCT f.candidate_id) AS candidate_count,
    AVG(c.age) AS avg_age
FROM fact_candidates f
JOIN dim_candidate c ON f.candidate_id = c.candidate_id
GROUP BY c.country_of_origin
ORDER BY candidate_count DESC;

COMMIT;
