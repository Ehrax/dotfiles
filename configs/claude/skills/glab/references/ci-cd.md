# CI/CD Pipelines & Jobs — glab ci / glab job

Complete reference for managing GitLab CI/CD pipelines and jobs from the CLI.

## CI Subcommands

| Subcommand | Description |
|------------|-------------|
| `ci run` | Create a new pipeline |
| `ci list` | List pipelines |
| `ci view` | Interactive pipeline viewer (run, trace, cancel jobs) |
| `ci status` | View current pipeline status |
| `ci trace` | Trace (tail) a CI job's log in real time |
| `ci retry` | Retry a failed job |
| `ci trigger` | Trigger a manual job |
| `ci run-trig` | Run a pipeline via trigger token |
| `ci cancel` | Cancel a running pipeline |
| `ci delete` | Delete a pipeline |
| `ci lint` | Validate `.gitlab-ci.yml` syntax |
| `ci get` | Get CI/CD configuration variables |
| `ci artifact` | Download job artifacts |

## glab ci run

Create and run a new pipeline.

```bash
# Run pipeline on current branch
glab ci run

# Run pipeline on a specific branch
glab ci run -b main

# Run with CI variables
glab ci run -b main --variables key1:val1,key2:val2

# Run with variables specified separately
glab ci run -b main --variables key1:val1 --variables key2:val2
```

## glab ci list

List pipelines with filtering.

### Flags

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--status` | `-s` | string | Filter by status: `running`, `pending`, `success`, `failed`, `canceled`, `skipped`, `manual` |
| `--order-by` | `-o` | string | Order by: `id`, `status`, `ref`, `updated_at`, `user_id` |
| `--sort` | — | string | Sort: `asc` or `desc` |
| `--per-page` | `-P` | int | Items per page (default 30) |
| `--page` | `-p` | int | Page number |
| `--output` | `-F` | string | Output format: `text` or `json` |

### Examples

```bash
glab ci list                        # List recent pipelines
glab ci list -s failed              # Failed pipelines only
glab ci list -F json                # JSON output
```

## glab ci view

Interactive TUI for viewing and managing the current pipeline. Shows stages, jobs, and their statuses.

```bash
glab ci view                        # View current branch's pipeline
glab ci view 12345                  # View specific pipeline by ID
glab ci view -b main               # View pipeline for a branch
glab ci view -w                     # Open pipeline in web browser
```

### Interactive Controls

| Key | Action |
|-----|--------|
| Arrow keys / Tab | Navigate between jobs |
| Enter | Toggle job logs / show child pipelines |
| Ctrl+R / Ctrl+P | Run, retry, or play a job |
| Ctrl+D | Cancel a job |
| Esc / q | Close logs or exit |
| Ctrl+Q | Quit the viewer |

## glab ci status

Display the status of the current pipeline.

```bash
glab ci status                      # Current branch pipeline status
glab ci status -b main              # Status for a specific branch
glab ci status --live               # Live-updating status
```

## glab ci trace

Trace (tail) a job's log output in real time.

```bash
glab ci trace                       # Interactive — select a job
glab ci trace 224356863             # Trace specific job by ID
glab ci trace lint                  # Trace job by name
glab ci trace -b feature-branch    # Trace job on a specific branch
```

## glab ci retry

Retry a failed or canceled job.

```bash
glab ci retry                       # Interactive — select a job
glab ci retry 224356863             # Retry by job ID
glab ci retry lint                  # Retry by job name
glab ci retry lint -b main          # Retry on a specific branch
glab ci retry lint -p 12345         # Retry in a specific pipeline
```

## glab ci trigger

Trigger a manual job.

```bash
glab ci trigger                     # Interactive — select a manual job
glab ci trigger 224356863           # Trigger by job ID
glab ci trigger deploy-staging      # Trigger by job name
glab ci trigger deploy -b main     # Trigger on a specific branch
```

## glab ci run-trig

Run a pipeline using a trigger token. Useful for cross-project triggers and automation.

```bash
# Basic trigger
glab ci run-trig -t $CI_JOB_TOKEN

# Trigger on specific branch with variables
glab ci run-trig -t $CI_JOB_TOKEN -b main --variables key1:val1,key2:val2

# With typed pipeline inputs
glab ci run-trig -t $CI_JOB_TOKEN -b main \
  --input "replicas:int(3)" \
  --input "debug:bool(false)" \
  --input "regions:array(us-east,eu-west)"
```

## glab ci cancel

Cancel a running pipeline.

```bash
glab ci cancel                      # Cancel current branch's pipeline
glab ci cancel 12345                # Cancel by pipeline ID
```

## glab ci delete

Delete a pipeline.

```bash
glab ci delete 12345                # Delete by pipeline ID
```

## glab ci lint

Validate CI configuration.

```bash
glab ci lint                        # Lint .gitlab-ci.yml in current directory
glab ci lint path/to/.gitlab-ci.yml # Lint a specific file
```

## glab ci artifact

Download job artifacts.

```bash
glab ci artifact 224356863          # Download artifacts for a job
glab ci artifact lint               # Download by job name
```

## Pipeline Schedules — glab schedule

Manage scheduled pipelines.

| Subcommand | Description |
|------------|-------------|
| `schedule create` | Create a new schedule |
| `schedule list` | List all schedules |
| `schedule run` | Execute a schedule manually |
| `schedule delete` | Delete a schedule |

### Examples

```bash
# Create a nightly schedule
glab schedule create --cron "0 2 * * *" --description "Nightly build" --ref main

# List all schedules
glab schedule list

# Run a schedule immediately
glab schedule run 42

# Delete a schedule
glab schedule delete 42
```

## Jobs — glab job

Direct job management.

```bash
glab job list                       # List jobs
glab job list -p 12345             # List jobs in a pipeline
```

## Common Patterns for Agents

### Monitor Pipeline After Push

```bash
# Check current pipeline status
glab ci status --live

# If failed, view the pipeline and retry
glab ci view
glab ci retry failed-job-name
```

### Lint Before Pushing

```bash
glab ci lint
```

### Get Artifacts from a Pipeline

```bash
# List jobs, find the one with artifacts, download
glab job list -p 12345
glab ci artifact build-job
```

### Trigger Cross-Project Pipeline

```bash
glab ci run-trig -t $TRIGGER_TOKEN -b main -R other-group/other-project
```
