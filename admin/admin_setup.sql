-- =============================================================================
-- OMILIA WORKSHOP DAY 2 — ADMIN SETUP
-- =============================================================================
-- Run as ACCOUNTADMIN before the workshop.
-- Creates: database, warehouse, role, shared stage, mock model UDF, grants.
-- After running: upload data/ contents to the shared stage.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Database & Shared Schema
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS OMILIA_WORKSHOP_DAY2;
USE DATABASE OMILIA_WORKSHOP_DAY2;

CREATE SCHEMA IF NOT EXISTS SHARED
  COMMENT = 'Read-only schema with pre-staged seed data and helper objects';

-- -----------------------------------------------------------------------------
-- 2. Warehouse — MEDIUM with multi-cluster for 20 concurrent participants
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH
  WAREHOUSE_SIZE = 'MEDIUM'
  MAX_CLUSTER_COUNT = 3
  MIN_CLUSTER_COUNT = 1
  SCALING_POLICY = 'STANDARD'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Shared warehouse for Omilia Day 2 workshop (~20 concurrent users)';

-- -----------------------------------------------------------------------------
-- 3. Internal Stage for seed data (CSV + MP3)
-- -----------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Pre-loaded seed data: calls_raw.csv, call_audio_metadata.csv, audiofile*.mp3';

-- -----------------------------------------------------------------------------
-- 4. Mock External Model UDF
-- -----------------------------------------------------------------------------
-- Simulates Omilia's own model (hosted on AWS) scoring each call.
-- Participants call this like a black-box model endpoint.
-- In production this would be an external function or SPCS service.
CREATE OR REPLACE FUNCTION OMILIA_WORKSHOP_DAY2.SHARED.OMILIA_MODEL_SCORE(
    call_id VARCHAR,
    transcript TEXT
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
HANDLER = 'score'
COMMENT = 'Simulated Omilia external model — returns resolution probability, quality score, and escalation recommendation'
AS
$$
import hashlib

def score(call_id, transcript):
    text = (transcript or "").lower()
    h = hashlib.md5((call_id or "").encode()).hexdigest()
    
    # Deterministic but varied scores based on call_id hash
    hash_int = int(h[:8], 16)
    resolution_prob = round(0.40 + (hash_int % 55) / 100.0, 2)
    quality_score = round(0.50 + ((hash_int >> 8) % 45) / 100.0, 2)
    
    # Escalation based on keywords + hash for consistency
    escalation = (
        any(k in text for k in ['angry', 'unacceptable', 'manager', 'lawyer', 'complain']) or
        (hash_int % 10 < 2)
    )
    
    return {
        "resolution_probability": resolution_prob,
        "handling_quality_score": quality_score,
        "escalation_recommended": escalation,
        "model_version": "omilia-qm-v2.1",
        "model_provider": "omilia-aws"
    }
$$;

-- -----------------------------------------------------------------------------
-- 5. Workshop Participant Role
-- -----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS WORKSHOP_PARTICIPANT_2026
  COMMENT = 'Role for Omilia Day 2 workshop participants';

-- Grant role to SYSADMIN for clean hierarchy
GRANT ROLE WORKSHOP_PARTICIPANT_2026 TO ROLE SYSADMIN;

-- -----------------------------------------------------------------------------
-- 6. Grants
-- -----------------------------------------------------------------------------

-- Database access
GRANT USAGE ON DATABASE OMILIA_WORKSHOP_DAY2 TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Shared schema (read-only)
GRANT USAGE ON SCHEMA OMILIA_WORKSHOP_DAY2.SHARED TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Allow creating their own schemas
GRANT CREATE SCHEMA ON DATABASE OMILIA_WORKSHOP_DAY2 TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Warehouse
GRANT USAGE ON WAREHOUSE WORKSHOP_WH TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Stage read access
GRANT READ ON STAGE OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Mock model UDF access
GRANT USAGE ON FUNCTION OMILIA_WORKSHOP_DAY2.SHARED.OMILIA_MODEL_SCORE(VARCHAR, TEXT) TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Cortex AI functions (required for AI_COMPLETE, AI_REDACT, AI_TRANSCRIBE)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Semantic View and Agent creation (bonus steps)
-- These are granted implicitly via CREATE SCHEMA ownership, but adding explicitly:
GRANT CREATE AGENT ON SCHEMA OMILIA_WORKSHOP_DAY2.SHARED TO ROLE WORKSHOP_PARTICIPANT_2026;

-- Future grants: participants need full control of objects in schemas they create
GRANT ALL ON FUTURE SCHEMAS IN DATABASE OMILIA_WORKSHOP_DAY2 TO ROLE WORKSHOP_PARTICIPANT_2026;

-- -----------------------------------------------------------------------------
-- 7. Post-Setup Instructions
-- -----------------------------------------------------------------------------
-- Upload seed data to the shared stage:
--
-- PUT file:///path/to/omilia-workshop-day2/data/calls_raw.csv
--     @OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE
--     AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
--
-- PUT file:///path/to/omilia-workshop-day2/data/call_audio_metadata.csv
--     @OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE
--     AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
--
-- PUT file:///path/to/omilia-workshop-day2/data/audiofile*.mp3
--     @OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE
--     AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
--
-- Then refresh directory table:
-- ALTER STAGE OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE REFRESH;
--
-- Assign the role to each participant user:
-- GRANT ROLE WORKSHOP_PARTICIPANT_2026 TO USER <username>;
-- =============================================================================


-- =============================================================================
-- ADDITIONAL GRANTS FOR DAY 2 ML PIPELINE
-- =============================================================================
-- Run this section AFTER the initial setup above (can be run separately).
-- Adds: governance tags, ML dataset creation, model registry, Python UDFs.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 8. Governance Tags (pre-created in SHARED, participants reference them)
-- -----------------------------------------------------------------------------
CREATE TAG IF NOT EXISTS OMILIA_WORKSHOP_DAY2.SHARED.DATA_DOMAIN
  ALLOWED_VALUES 'call_center', 'customer', 'agent', 'model_output'
  COMMENT = 'Business domain classification for data discoverability';

CREATE TAG IF NOT EXISTS OMILIA_WORKSHOP_DAY2.SHARED.SENSITIVITY
  ALLOWED_VALUES 'public', 'internal', 'confidential', 'restricted'
  COMMENT = 'Data sensitivity level for policy enforcement';

-- Participants can apply these specific tags to their own tables
GRANT APPLY ON TAG OMILIA_WORKSHOP_DAY2.SHARED.DATA_DOMAIN TO ROLE WORKSHOP_PARTICIPANT_2026;
GRANT APPLY ON TAG OMILIA_WORKSHOP_DAY2.SHARED.SENSITIVITY TO ROLE WORKSHOP_PARTICIPANT_2026;

-- -----------------------------------------------------------------------------
-- 9. ML Dataset Creation
-- -----------------------------------------------------------------------------
GRANT CREATE DATASET ON FUTURE SCHEMAS IN DATABASE OMILIA_WORKSHOP_DAY2
  TO ROLE WORKSHOP_PARTICIPANT_2026;

-- -----------------------------------------------------------------------------
-- 10. Model Registry
-- -----------------------------------------------------------------------------
GRANT CREATE MODEL ON FUTURE SCHEMAS IN DATABASE OMILIA_WORKSHOP_DAY2
  TO ROLE WORKSHOP_PARTICIPANT_2026;

-- -----------------------------------------------------------------------------
-- 11. Python UDFs (needed for Snowpark ML model training internals)
-- -----------------------------------------------------------------------------
GRANT CREATE FUNCTION ON FUTURE SCHEMAS IN DATABASE OMILIA_WORKSHOP_DAY2
  TO ROLE WORKSHOP_PARTICIPANT_2026;

-- =============================================================================
