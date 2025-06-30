#!/bin/bash

# GCP Wiv Onboarding Script
# This script creates a service account for Wiv and stores its key in Secret Manager
# Usage: ./GCPWivOnBoarding.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Set to disable all interactive prompts
gcloud config set disable_prompts true

# Configuration variables
SERVICE_ACCOUNT_NAME="wiv-sa"
SERVICE_ACCOUNT_DISPLAY_NAME="Wiv Service Account"
SECRET_NAME="wiv-service-account-key"
TEMP_KEY_FILE="temp_key.json"

# Function to print colored output
print_status() {
  local color=$1
  local message=$2
  case $color in
    "green") echo -e "\033[32m✓ $message\033[0m" ;;
    "red") echo -e "\033[31m✗ $message\033[0m" ;;
    "yellow") echo -e "\033[33m⚠ $message\033[0m" ;;
    "blue") echo -e "\033[34mℹ $message\033[0m" ;;
  esac
}

# Function to validate project ID format
validate_project_id() {
  local project_id="$1"
  if [[ ! "$project_id" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
    print_status "red" "Invalid project ID format. Project ID must be 6-30 characters long, contain only lowercase letters, numbers, and hyphens, and start with a letter."
    return 1
  fi
  return 0
}

# Function to check if a command executed successfully
check_error() {
  local exit_code="$1"
  local error_message="$2"

  if [ "$exit_code" -ne 0 ]; then
    print_status "red" "$error_message"
    exit "$exit_code"
  fi
}

# Function to login to gcloud
gcloud_login() {
  print_status "blue" "Authenticating with Google Cloud..."
  gcloud auth login --quiet
  check_error $? "Failed to authenticate with Google Cloud."
}

# Function to enable a service API on a project
enable_service_api() {
  local project_id="$1"
  local api_name="$2"

  print_status "blue" "Enabling $api_name on project $project_id..."
  
  # Check if the API is enabled, and enable it if not
  if ! gcloud services list --project="$project_id" --filter="name:$api_name" --format="value(name)" | grep -q "$api_name"; then
    gcloud services enable "$api_name" --project="$project_id" --quiet
    check_error $? "Failed to enable $api_name on project $project_id."
    print_status "green" "$api_name enabled successfully."
  else
    print_status "yellow" "$api_name is already enabled on project $project_id."
  fi
}

# Function to create a service account
create_service_account() {
  local service_account_name="$1"
  local display_name="$2"
  local project_id="$3"

  print_status "blue" "Creating service account $service_account_name in project $project_id..."
  
  # Check if service account already exists
  if gcloud iam service-accounts describe "$service_account_name@$project_id.iam.gserviceaccount.com" --project="$project_id" &>/dev/null; then
    print_status "yellow" "Service account $service_account_name already exists in project $project_id."
    return 0
  fi

  gcloud iam service-accounts create "$service_account_name" --project="$project_id" --display-name="$display_name" --quiet
  check_error $? "Failed to create service account $service_account_name in project $project_id."
  print_status "green" "Service account $service_account_name created successfully."
}

# Function to add IAM policy binding
add_iam_binding() {
  local target="$1"
  local member="$2"
  local role="$3"
  local level="$4"

  print_status "blue" "Adding IAM binding: $role for $member at $level level..."

  if [ "$level" == "organization" ]; then
    gcloud organizations add-iam-policy-binding "$target" --member="$member" --role="$role" --condition=None --quiet
  elif [ "$level" == "project" ]; then
    gcloud projects add-iam-policy-binding "$target" --member="$member" --role="$role" --condition=None --quiet
  fi

  check_error $? "Failed to add IAM policy binding for $member with role $role at $level level $target."
  print_status "green" "IAM binding added successfully: $role"
}

# Function to generate a service account key and store it in Secret Manager
generate_and_store_service_account_key() {
  local service_account_email="$1"
  local project_id="$2"
  local secret_name="$3"
  local temp_key_file="$4"

  print_status "blue" "Generating service account key for $service_account_email..."
  
  # Generate the key to a temporary file
  gcloud iam service-accounts keys create "$temp_key_file" --iam-account="$service_account_email" --quiet
  check_error $? "Failed to generate service account key for $service_account_email."

  print_status "blue" "Storing service account key in Secret Manager..."
  
  # Create the secret in Secret Manager
  if ! gcloud secrets describe "$secret_name" --project="$project_id" &>/dev/null; then
    gcloud secrets create "$secret_name" --project="$project_id" --quiet
    check_error $? "Failed to create secret $secret_name in project $project_id."
  fi

  # Store the key content in the secret
  gcloud secrets versions add "$secret_name" --data-file="$temp_key_file" --project="$project_id" --quiet
  check_error $? "Failed to store service account key in Secret Manager."

  # Clean up the temporary key file
  rm -f "$temp_key_file"
  print_status "green" "Service account key stored securely in Secret Manager as '$secret_name'."
}

# Function to grant Secret Manager access to the service account
grant_secret_access() {
  local project_id="$1"
  local service_account_email="$2"
  local secret_name="$3"

  print_status "blue" "Granting Secret Manager access to service account..."
  
  # Grant the service account access to read the secret
  gcloud secrets add-iam-policy-binding "$secret_name" \
    --project="$project_id" \
    --member="serviceAccount:$service_account_email" \
    --role="roles/secretmanager.secretAccessor" \
    --quiet
  
  check_error $? "Failed to grant Secret Manager access to service account."
  print_status "green" "Secret Manager access granted to service account."
}

# Main script
print_status "blue" "Starting GCP Wiv Onboarding..."

# Login to gcloud
gcloud_login

# Prompt user for standalone or organization configuration
echo -e "\nIs this for a standalone project or an entire organization?"
select choice in "Standalone Project" "Entire Organization"; do
  case $choice in
    "Standalone Project")
      ORG_LEVEL="project"
      break
      ;;
    "Entire Organization")
      # Check if the user has organization-level permissions
      ORGANIZATIONS=$(gcloud organizations list --format="value(displayName,name)" 2>/dev/null)
      ORG_PERMISSIONS=$?

      if [ "$ORG_PERMISSIONS" -ne 0 ] || [ -z "$ORGANIZATIONS" ]; then
        print_status "yellow" "No organizations found or insufficient permissions to list organizations."
        print_status "yellow" "Defaulting to standalone project."
        ORG_LEVEL="project"
      else
        ORG_LEVEL="organization"
        IFS=$'\n' read -r -d '' -a org_array <<< "$ORGANIZATIONS"
        if [ ${#org_array[@]} -gt 1 ]; then
          echo "Multiple organizations found. Please choose one:"
          select org in "${org_array[@]}"; do
            ORGANIZATION_ID=$(echo "$org" | awk '{print $NF}')
            ORGANIZATION_NAME=$(echo "$org" | sed "s/ $ORGANIZATION_ID$//")
            break
          done
        else
          ORGANIZATION_NAME=$(echo "$ORGANIZATIONS" | awk '{print $1}')
          ORGANIZATION_ID=$(echo "$ORGANIZATIONS" | awk '{print $2}')
        fi
      fi

      if [ -z "$ORGANIZATION_ID" ]; then
        print_status "red" "Error: No organization ID found."
        exit 1
      fi
      break
      ;;
    *)
      echo "Invalid choice. Please choose either 'Standalone Project' or 'Entire Organization'."
      ;;
  esac
done

# Get and validate project ID
echo -e "\nEnter the project ID to create the service account (usually project that contains the billing dataset):"
read -r PROJECT_ID

if ! validate_project_id "$PROJECT_ID"; then
  exit 1
fi

# Verify project exists and user has access
print_status "blue" "Verifying project access..."
if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
  print_status "red" "Project $PROJECT_ID not found or you don't have access to it."
  exit 1
fi

# Enable necessary APIs on the specified project
print_status "blue" "Enabling required APIs..."
enable_service_api "$PROJECT_ID" "recommender.googleapis.com"
enable_service_api "$PROJECT_ID" "cloudresourcemanager.googleapis.com"
enable_service_api "$PROJECT_ID" "compute.googleapis.com"
enable_service_api "$PROJECT_ID" "secretmanager.googleapis.com"

# Create service account
create_service_account "$SERVICE_ACCOUNT_NAME" "$SERVICE_ACCOUNT_DISPLAY_NAME" "$PROJECT_ID"

# Wait for the service account to be fully available
SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
print_status "blue" "Waiting for service account to be available..."
for i in {1..10}; do
  if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    break
  fi
  sleep 2
done

# Generate and store service account key in Secret Manager
generate_and_store_service_account_key "$SERVICE_ACCOUNT_EMAIL" "$PROJECT_ID" "$SECRET_NAME" "$TEMP_KEY_FILE"

# Grant Secret Manager access to the service account
grant_secret_access "$PROJECT_ID" "$SERVICE_ACCOUNT_EMAIL" "$SECRET_NAME"

# Add IAM policy bindings
if [ "$ORG_LEVEL" == "organization" ]; then
  TARGET_ID="$ORGANIZATION_ID"
else
  TARGET_ID="$PROJECT_ID"
fi

print_status "blue" "Adding IAM policy bindings at $ORG_LEVEL level..."

# List of IAM roles to assign
declare -a IAM_ROLES=(
  "roles/recommender.computeViewer"
  "roles/recommender.viewer"
  "roles/monitoring.viewer"
  "roles/compute.viewer"
  "roles/bigquery.jobUser"
  "roles/recommender.bigQueryCapacityCommitmentsViewer"
  "roles/container.viewer"
  "roles/storage.objectViewer"
  "roles/bigquery.dataViewer"
  "roles/cloudsql.viewer"
  "roles/run.viewer"
  "roles/cloudfunctions.viewer"
  "roles/pubsub.viewer"
  "roles/spanner.viewer"
  "roles/logging.viewer"
  "roles/iam.securityReviewer"
  "roles/compute.networkViewer"
  "roles/cloudbuild.builds.viewer"
  "roles/dataflow.viewer"
  "roles/redis.viewer"
  "roles/securitycenter.viewer"
  "roles/cloudkms.viewer"
  "roles/artifactregistry.reader"
  "roles/gkebackup.viewer"
  "roles/cloudasset.viewer"
  "roles/bigquery.resourceViewer"
)

# Add each IAM binding
for role in "${IAM_ROLES[@]}"; do
  add_iam_binding "$TARGET_ID" "serviceAccount:$SERVICE_ACCOUNT_EMAIL" "$role" "$ORG_LEVEL"
done

print_status "green" "IAM policy bindings added successfully at $ORG_LEVEL level ($TARGET_ID)."

# Final summary
echo -e "\n=== Onboarding Complete ==="
print_status "green" "Service account $SERVICE_ACCOUNT_EMAIL has been created and configured."
print_status "green" "All necessary permissions have been granted at $ORG_LEVEL level for $TARGET_ID."
print_status "green" "Service account key has been stored securely in Secret Manager."

echo -e "\n=== Configuration Summary ==="
echo "Service Account Project: $PROJECT_ID"
echo "Service Account Email: $SERVICE_ACCOUNT_EMAIL"
echo "Secret Manager Secret Name: $SECRET_NAME"
echo "Target Level: $ORG_LEVEL"
echo "Target ID: $TARGET_ID"

echo -e "\n=== Next Steps ==="
echo "1. The service account key is now stored in Secret Manager as '$SECRET_NAME'"
echo "2. Applications can access the key using the Secret Manager API"
echo "3. The service account has been granted Secret Manager access"
echo "4. All required IAM permissions have been configured"

print_status "green" "Onboarding completed successfully!"