# We use mapfile (or readarray) to correctly handle names with spaces
mapfile -t WORKFLOW_NAMES < <(gh workflow list --json name,state --jq '.[] | select(.state == "active") | .name')
# Check if the array is empty
if [ ${#WORKFLOW_NAMES[@]} -eq 0 ]; then
    echo "No active workflows found in this repository."
    exit 0
fi
echo "${#WORKFLOW_NAMES[@]} active workflows were found."
echo "------------------------------------------------"
# Iterate over each workflow present in the array
for WORKFLOW_NAME in "${WORKFLOW_NAMES[@]}"; do
    echo "Processing workflow: '$WORKFLOW_NAME'"
    # Retrieve the ID of the last run for the current workflow
    RUN_ID=$(gh run list --workflow="$WORKFLOW_NAME" --limit 1 --json databaseId --jq '.[0].databaseId')
    # If no runs exist or ID is null, skip to the next workflow
    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        echo "-> No recent run found for '$WORKFLOW_NAME'. Skipping."
        echo "------------------------------------------------"
        continue
    fi
    echo "-> Found last Run ID: $RUN_ID"
    echo "-> Downloading artifacts in progress..."
    # Download the artifacts into a dedicated folder for each workflow to avoid overwriting files
    gh run download "$RUN_ID" --dir "artifacts/${WORKFLOW_NAME// /_}"
    echo "-> Completed for '$WORKFLOW_NAME'."
    echo "------------------------------------------------"
done
echo "Procedure completed! All artifacts are in the 'artifacts/' directory."
