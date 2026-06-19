-- =============================================================================
-- OMILIA WORKSHOP DAY 2 — TEARDOWN (Net-Zero Cleanup)
-- =============================================================================
-- Run as ACCOUNTADMIN after the workshop to destroy ALL objects.
-- This returns the account to the state before the workshop.
-- =============================================================================

-- Drop the database (includes all participant schemas, tables, stages)
DROP DATABASE IF EXISTS OMILIA_WORKSHOP_DAY2;

-- Drop the shared warehouse
DROP WAREHOUSE IF EXISTS WORKSHOP_WH;

-- Drop the workshop role
DROP ROLE IF EXISTS WORKSHOP_PARTICIPANT_2026;

-- =============================================================================
-- Verification: confirm nothing remains
-- =============================================================================
-- SHOW DATABASES LIKE 'OMILIA_WORKSHOP_DAY2';   -- should return 0 rows
-- SHOW WAREHOUSES LIKE 'WORKSHOP_WH';            -- should return 0 rows
-- SHOW ROLES LIKE 'WORKSHOP_PARTICIPANT_2026';   -- should return 0 rows
-- =============================================================================
