# Generate Pull Request

Create a pull request from a head and base bookmark with an AI-generated description based on commits and diffs.

## Usage

```
/genpr <base_change_id> <head_change_id>
```

## Instructions

### 1. Argument Check

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: /createpr <base_change_id> <head_change_id>"
  exit 1
fi

BASE_CHANGE_ID=$1
HEAD_CHANGE_ID=$2

### 2. Get branch/bookmark names

Run `jj log -r '$base_id::$head_id & bookmarks()' -T '"change_id: " ++ change_id.short() ++ "\t" ++ "bookmark name: " ++ bookmarks ++ " " ++ "description: " ++ description.first_line() ++ "\n"' --no-graph --no-pager -n2`

The first line is the HEAD branch. The second line is the parent/base branch. If there is no second line, you should assume the parent/base branch is `main`.

### 3. Study changes

- Get the list of files changes with `jj diff --from $BASE_CHANGE_ID --to $HEAD_CHANGE_ID --name-only`
- In parallel tasks for each file:
    - Study the diff of each file with `jj diff --from $BASE_CHANGE_ID --to $HEAD_CHANGE_ID [filename]`
    - Read the file in entirety

### 4. Generate PR description

Create a PR description for the changes between the two branches. The PR description should conform to @.github/pull_request_template.md if it exists.

If the pull request template has a tophat emoji or mentions tophatting, you should describe the steps that a reviewer would take in their local development environment or in production to test the changes. If it does not look straightforward skip this section, but do not erase it.

**CRITICAL**: The PR description should be as terse as possible. Keep it it to a very simple and first-principles description of the changes being made. When in doubt, prioritize a terse description.

### 5. Create the PR using `gh` cli

Use the GH cli to create the PR, but pass the --web flag to open the PR in the web browser once created. In JJ, the analagous concept for a branch is a bookmark. So you should use the bookmark names as the branch names when calling the GH cli.

To be explicit, the GH cli accepts a \`--head {branch_name}\` and \`--base {branch_name}\` flags. You should use the head and base bookmark names as the branch names in the GH cli PR create call."
