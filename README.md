# Snowflake Omilia Workshop — Day 2

**From Omilia Calls to a Training-Ready Dataset in Snowflake**

A hands-on workshop that builds a complete data pipeline: ingest raw call-center data, anonymize PII, enrich with Cortex AI, score with an external model, transcribe audio, and generate an analytics dashboard.

## Quick Start

1. Open the [step-by-step guide](https://sfc-gh-aperezgonzalez.github.io/snowflake-omilia-workshop/)
2. Open Cortex Code in your Workspace and paste this prompt to create your notebook:

```
Create a Snowflake Notebook called "omilia_workshop" in database OMILIA_WORKSHOP_DAY2, using warehouse WORKSHOP_WH.
Use the notebook at https://github.com/sfc-gh-aperezgonzalez/snowflake-omilia-workshop/blob/main/notebook/omilia_workshop_day2.ipynb as reference and replicate its SQL and markdown cells exactly.
```

3. Follow the steps in both the HTML guide and the notebook

## What You'll Build

| Step | Table Created | What Happens |
|------|---------------|--------------|
| 1 | `CALLS_RAW` | Load 200 call records from shared stage |
| 2 | `CALLS_ANON` | Remove PII with AI_REDACT |
| 3 | `CALLS_ENRICHED` | Add summaries, sentiment, categories with Cortex AI |
| 4 | `CALLS_TRAINING_READY` | Score with simulated external model |
| 5* | `AUDIO_TRANSCRIPTIONS_RAW` | Transcribe MP3 files with AI_TRANSCRIBE |
| 6* | `CALLS_SEMANTIC_VIEW` + Agent | Create semantic view and Cortex Agent |
| 7 | Dashboard | Generate analytics UI with Cortex Code |

*Steps marked with * are bonus steps

## Prerequisites

- Snowflake account with role `WORKSHOP_PARTICIPANT_2026`
- Warehouse: `WORKSHOP_WH`
- Database: `OMILIA_WORKSHOP_DAY2`
- Your assigned schema name (first name + initial, e.g., `ALEJANDRO_P`)

## Repository Structure

```
├── index.html              # Step-by-step HTML guide (GitHub Pages)
├── notebook/
│   └── omilia_workshop_day2.ipynb   # Snowflake Notebook
├── data/
│   ├── calls_raw.csv               # 200-row synthetic dataset
│   ├── call_audio_metadata.csv     # Audio file metadata
│   ├── audiofile1.mp3              # Sample call recordings
│   ├── audiofile2.mp3
│   └── audiofile3.mp3
└── admin/                  # Admin-only (facilitator setup)
    ├── admin_setup.sql     # Run as ACCOUNTADMIN before workshop
    └── teardown.sql        # Cleanup after workshop
```

## For Facilitators

Before the workshop:

1. Run `admin/admin_setup.sql` as ACCOUNTADMIN
2. Upload `data/` contents to `@OMILIA_WORKSHOP_DAY2.SHARED.WORKSHOP_STAGE`
3. Grant `WORKSHOP_PARTICIPANT_2026` role to all participant users
4. Dry-run the notebook once from a clean schema

After the workshop:

1. Run `admin/teardown.sql` to destroy all objects (net-zero)

---

*Built for Omilia Open Doors Day 2 | Powered by Snowflake Cortex AI*
