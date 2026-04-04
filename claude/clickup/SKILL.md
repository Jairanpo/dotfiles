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

### Company field

The **Company** custom field must always be set on every Task and Story. It is a dropdown with the following options:

| Name | Option ID |
|------|-----------|
| Plink | `964c27a9-a26f-4e06-bd8f-b74c00c8ac6c` |
| Tamashii | `de8f0219-df3e-4f61-907e-246d459fd17e` |
| Capital One | `da0beb58-3b41-48a0-b3e4-809fff0c67c7` |
| Corvidae | `1331b397-e3ad-40ce-9e54-b293a66a85fb` |

**Always ask the user which company this task belongs to before creating.** Default to **Corvidae** if the user does not specify.

Field ID: `3d380522-777f-4849-b8e6-69ca2d4d68ac`

## Task Types

| Type  | What it does | ClickUp result | `custom_item_id` |
|-------|-------------|----------------|------------------|
| Story | Outcome-based work item | New task in list with type Story | `1002` |
| Task  | Technical work item | New task in list with type Task | `0` |
| Chore | Small reminder/subtask | Checklist item inside an existing Story or Task | `1012` (on parent) |

Never use tags to indicate type. Always set `custom_item_id` on creation.

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
| **Due date** | Yes | Hours estimate: `3h`, `6h`, `9h`, etc. | Max 2 weeks. System applies 50% padding and caps at 3h of work/day to calculate due date. |
| **Priority** | Yes | 1=Urgent, 2=High, 3=Normal, 4=Low | Default to 3 if user doesn't specify |
| **Type** | Yes | `story`, `task`, or `chore` | Determines creation behavior |
| **Parent Task ID** | Only for Chores | ClickUp task ID | Required to know where to add checklist item |

**Due date calculation:**
- Take the user's hour estimate (e.g. `6h`)
- Apply 50% padding: `padded = estimate * 1.5`
- Divide by 3 (max hours/day): `days = ceil(padded / 3)`
- Cap at 14 days (2 weeks); reject if it would exceed that
- Due date = today + days

Example: `6h` → 6 * 1.5 = 9h → 9 / 3 = 3 days → due in 3 days

Present a summary to the user and ask for confirmation before creating:

```
Title: Set up CI/CD pipeline for staging
Type: Task
Company: Corvidae
Description: Configure GitHub Actions to deploy to staging on merge to develop...
Estimate: 6h → 3 days with padding (due 2026-04-07)
Priority: 3 (Normal)

Confirm? (yes/no)
```

### Step 3: Create the item in ClickUp

#### For Stories and Tasks — Create a new task

Convert the hour estimate to a due date in Unix milliseconds:

```bash
# ESTIMATE_H = raw hours provided by user (e.g. 6)
ESTIMATE_H=6
PADDED=$(echo "$ESTIMATE_H * 1.5" | bc)
DAYS=$(python3 -c "import math; print(math.ceil($PADDED / 3))")

if [ "$DAYS" -gt 14 ]; then
  echo "Error: estimate exceeds 2-week maximum."
  exit 1
fi

DUE_DATE_MS=$(date -d "+${DAYS} days" +%s)000
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
    "custom_item_id": CUSTOM_ITEM_ID
  }')

echo "$RESPONSE" | jq '{id: .id, name: .name, url: .url, status: .status.status}'
```

Save the returned `id` — needed if chores will be added to this task later.

After creating the task, immediately set the Company field:

```bash
curl -s -X POST \
  "https://api.clickup.com/api/v2/task/${TASK_ID}/field/3d380522-777f-4849-b8e6-69ca2d4d68ac" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"value": "COMPANY_OPTION_ID_HERE"}'
```

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

Then ask the user: **"Should this task be set to IN PROGRESS?"**

If yes, update the task status:

```bash
curl -s -X PUT \
  "https://api.clickup.com/api/v2/task/TASK_ID" \
  -H "Authorization: ${CLICKUP_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status": "in progress"}' \
  | jq '{id: .id, name: .name, status: .status.status}'
```

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
