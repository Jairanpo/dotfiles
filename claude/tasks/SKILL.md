# Task Creation Skill for ClickUp

name: tasks
description: Analyzes tasks from user and asks questions to correctly create those tasks in ClickUp. Tasks can be of type Story, Task, or Chore. Chores live inside Stories and Tasks as checklist items. Chores behave as reminders. Only Tasks and Stories generate new entries in lists.
compatibility: curl, jq, yq, ClickUp account with API access

## Prerequisites

- `~/.global.yml` must exist with the following structure:
```yaml
clickup:
  api_token: "pk_YOUR_TOKEN_HERE"
  list_id: "YOUR_LIST_ID"
```
- `yq` must be installed for YAML parsing (`pip install yq` or `snap install yq`)
- `jq` must be installed for JSON parsing

### Reading config

Always read credentials at the start of any operation:

```bash
CLICKUP_API_TOKEN=$(yq -r '.clickup.api_token' ~/.global.yml)
CLICKUP_LIST_ID=$(yq -r '.clickup.list_id' ~/.global.yml)
```

If either value is null or empty, stop and tell the user to configure `~/.global.yml`.

## Task Types

| Type  | What it does | ClickUp result |
|-------|-------------|----------------|
| Story | Outcome-based work item | New task in list with tag `story` |
| Task  | Technical work item | New task in list with tag `task` |
| Chore | Small reminder/subtask | Checklist item inside an existing Story or Task |

## Instructions

### Step 1: Gather task description from user

Ask the user to describe the work. Guide them based on type:

- **Story**: Must describe an **outcome** (what is achieved when done). Ask: "What is the desired outcome?"
- **Task**: Must include **what** is being done, **why**, and **how**. Format is flexible.
- **Chore**: Same format as Task, but must specify **which parent Story or Task** it belongs to. Ask: "Which Story or Task should this chore live under?"

If the user gives a vague description, ask clarifying questions before proceeding.

### Step 2: Validate required fields

Before creating anything, confirm these fields with the user:

| Field | Required | Format | Notes |
|-------|----------|--------|-------|
| **Title** | Yes | Short, descriptive string | e.g. "Set up CI/CD pipeline for staging" |
| **Description** | Yes | Markdown string | Include what/why/how for Tasks; outcome for Stories |
| **Due date** | Yes | `YYYY-MM-DD` | Needed for calendar sync |
| **Priority** | Yes | 1=Urgent, 2=High, 3=Normal, 4=Low | Default to 3 if user doesn't specify |
| **Type** | Yes | `story`, `task`, or `chore` | Determines creation behavior |
| **Parent Task ID** | Only for Chores | ClickUp task ID | Required to know where to add checklist item |

Present a summary to the user and ask for confirmation before creating:

```
Title: Set up CI/CD pipeline for staging
Type: Task
Description: Configure GitHub Actions to deploy to staging on merge to develop...
Due date: 2026-04-10
Priority: 3 (Normal)

Confirm? (yes/no)
```

### Step 3: Create the item in ClickUp

#### For Stories and Tasks — Create a new task

Convert the due date to Unix milliseconds:

```bash
DUE_DATE_MS=$(date -d "YYYY-MM-DD" +%s)000
```

Create the task:

```bash
CLICKUP_API_TOKEN=$(yq -r '.clickup.api_token' ~/.global.yml)
CLICKUP_LIST_ID=$(yq -r '.clickup.list_id' ~/.global.yml)

RESPONSE=$(curl -s -X POST \
  "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "TITLE_HERE",
    "markdown_description": "DESCRIPTION_HERE",
    "due_date": '"${DUE_DATE_MS}"',
    "due_date_time": false,
    "priority": PRIORITY_NUMBER,
    "tags": ["TYPE_HERE"]
  }')

echo "$RESPONSE" | jq '{id: .id, name: .name, url: .url, status: .status.status}'
```

Save the returned `id` — needed if chores will be added to this task later.

#### For Chores — Add checklist item to parent task

**Step 3a**: Find the parent task if user gave a name instead of ID:

```bash
CLICKUP_API_TOKEN=$(yq -r '.clickup.api_token' ~/.global.yml)
CLICKUP_LIST_ID=$(yq -r '.clickup.list_id' ~/.global.yml)

curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  | jq -r '.tasks[] | select(.name | test("SEARCH_TERM"; "i")) | "\(.id) | \(.name)"'
```

**Step 3b**: Check if parent task already has a "Chores" checklist, reuse it if so:

```bash
EXISTING_CHECKLIST=$(curl -s "https://api.clickup.com/api/v2/task/${PARENT_TASK_ID}" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  | jq -r '.checklists[] | select(.name == "Chores") | .id')

if [ -n "$EXISTING_CHECKLIST" ]; then
  CHECKLIST_ID="$EXISTING_CHECKLIST"
else
  CHECKLIST_ID=$(curl -s -X POST \
    "https://api.clickup.com/api/v2/task/${PARENT_TASK_ID}/checklist" \
    -H "Authorization: ${CLICKUP_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"name": "Chores"}' \
    | jq -r '.checklist.id')
fi
```

**Step 3c**: Add the chore as a checklist item:

```bash
curl -s -X POST \
  "https://api.clickup.com/api/v2/checklist/${CHECKLIST_ID}/checklist_item" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CHORE_TITLE_HERE",
    "assignee": null
  }' | jq '{checklist_item: .checklist_item.name}'
```

### Step 4: Confirm result to user

After creation, display:

- For Tasks/Stories: task name, ID, URL, and due date
- For Chores: parent task name, checklist item name, confirmation it was added

Example output:
```
✅ Task created successfully
   Name: Set up CI/CD pipeline for staging
   ID: abc123
   URL: https://app.clickup.com/t/abc123
   Due: 2026-04-10
   Priority: Normal
   Type: task
```

## Error Handling

| Error | Cause | Action |
|-------|-------|--------|
| `401 Unauthorized` | Bad API token | Tell user to check `clickup.api_token` in `~/.global.yml` |
| `404 Not Found` | Bad list ID or task ID | Tell user to check `clickup.list_id` in `~/.global.yml` |
| `429 Rate Limited` | Too many requests | Wait 60 seconds and retry |
| Empty/null config values | Missing `~/.global.yml` entries | Tell user to populate the config file |
| Parent task not found | Chore references nonexistent task | Ask user to clarify the parent task name or provide the ID |

## Useful Reference Commands

List all tasks in the configured list:
```bash
CLICKUP_API_TOKEN=$(yq -r '.clickup.api_token' ~/.global.yml)
CLICKUP_LIST_ID=$(yq -r '.clickup.list_id' ~/.global.yml)

curl -s "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  | jq -r '.tasks[] | "\(.id) | \(.name) | \(.status.status) | Priority: \(.priority.priority // "none")"'
```

Get details of a specific task:
```bash
CLICKUP_API_TOKEN=$(yq -r '.clickup.api_token' ~/.global.yml)

curl -s "https://api.clickup.com/api/v2/task/TASK_ID" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  | jq '{id, name, description, status: .status.status, priority: .priority.priority, due_date, url}'
```
