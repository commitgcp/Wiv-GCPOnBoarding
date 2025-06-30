#!/bin/bash

# GCP Wiv Onboarding Script
# This script creates a service account for Wiv and stores its key in Secret Manager
# Usage: ./GCPWivOnBoarding.sh [OPTIONS]
# 
# Options:
#   -p, --project-id PROJECT_ID    Project ID to create the service account in
#   -l, --level LEVEL              Configuration level: 'project' or 'organization'
#   -o, --organization-id ORG_ID   Organization ID (required if level is 'organization')
#   -n, --no-login                 Skip authentication (assumes already authenticated)
#   -h, --help                     Show this help message

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Set to disable all interactive prompts
gcloud config set disable_prompts true

# Configuration variables
SERVICE_ACCOUNT_NAME="wiv-sa"
SERVICE_ACCOUNT_DISPLAY_NAME="Wiv Service Account"
SECRET_NAME="wiv-service-account-key"
TEMP_KEY_FILE="temp_key.json"

# Initialize variables
PROJECT_ID=""
ORG_LEVEL=""
ORGANIZATION_ID=""
SKIP_LOGIN=false

# Function to show usage
show_usage() {
  cat << EOF
GCP Wiv Onboarding Script

This script creates a service account for Wiv and stores its key in Secret Manager.

Usage: $0 [OPTIONS]

Options:
  -p, --project-id PROJECT_ID    Project ID to create the service account in
  -l, --level LEVEL              Configuration level: 'project' or 'organization'
  -o, --organization-id ORG_ID   Organization ID (required if level is 'organization')
  -n, --no-login                 Skip authentication (assumes already authenticated)
  -h, --help                     Show this help message

Examples:
  # Interactive mode (all prompts)
  $0

  # Non-interactive mode with all parameters
  $0 -p my-project-id -l project

  # Organization level setup
  $0 -p my-project-id -l organization -o 123456789

  # Skip authentication (already logged in)
  $0 -p my-project-id -l project -n

EOF
}

# Function to parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p|--project-id)
        PROJECT_ID="$2"
        shift 2
        ;;
      -l|--level)
        ORG_LEVEL="$2"
        shift 2
        ;;
      -o|--organization-id)
        ORGANIZATION_ID="$2"
        shift 2
        ;;
      -n|--no-login)
        SKIP_LOGIN=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        print_status "red" "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

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
  if ! gcloud services list --project="$project_id" --filter="name=$api_name" --format="value(name)" | grep -q "$api_name"; then
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

# Function to display confirmation prompt
show_confirmation() {
  local project_id="$1"
  local org_level="$2"
  local target_id="$3"
  local service_account_email="$4"
  local secret_name="$5"
  local iam_roles_count="$6"
  shift 6
  local iam_roles=("$@")

  echo -e "\n"$(printf '=%.0s' {1..60})
  echo "🚀 GCP Wiv Onboarding - Action Confirmation"
  echo $(printf '=%.0s' {1..60})
  echo ""
  echo "Please review the following actions that will be performed:"
  echo ""
  
  echo "📋 Configuration:"
  echo "   • Project ID: $project_id"
  echo "   • Target Level: $org_level"
  echo "   • Target ID: $target_id"
  echo ""
  
  echo "🔧 Actions to be performed:"
  echo "   1. Enable required APIs on project '$project_id':"
  echo "      - recommender.googleapis.com"
  echo "      - cloudresourcemanager.googleapis.com"
  echo "      - compute.googleapis.com"
  echo "      - secretmanager.googleapis.com"
  echo ""
  echo "   2. Create service account:"
  echo "      - Name: wiv-sa"
  echo "      - Email: $service_account_email"
  echo "      - Display Name: Wiv Service Account"
  echo ""
  echo "   3. Generate and store service account key:"
  echo "      - Store in Secret Manager as '$secret_name'"
  echo "      - Grant service account access to its own key"
  echo ""
  echo "   4. Grant IAM permissions:"
  echo "      - Assign $iam_roles_count IAM roles at $org_level level"
  echo "      - Target: $target_id"
  echo "      - Service Account: $service_account_email"
  echo "      - Roles to be granted:"
  for role in "${iam_roles[@]}"; do
    echo "        • $role"
  done
  echo ""
  
  echo "⚠️  Important Notes:"
  echo "   • This will create new resources in your Google Cloud project"
  echo "   • Service account keys will be stored securely in Secret Manager"
  echo "   • IAM permissions will be granted at the $org_level level"
  echo "   • Existing service accounts with the same name will be reused"
  echo ""
  
  echo "Do you want to proceed with these actions? (y/N)"
  read -r response
  
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "yellow" "Operation cancelled by user."
    exit 0
  fi
  
  echo ""
  print_status "blue" "Proceeding with GCP Wiv Onboarding..."
  echo ""
}

# Main script
print_status "blue" "Starting GCP Wiv Onboarding..."

# Parse command line arguments
parse_arguments "$@"

# Login to gcloud (unless skipped)
if [ "$SKIP_LOGIN" == false ]; then
  gcloud_login
else
  print_status "blue" "Skipping authentication (--no-login flag provided)"
fi

# Handle configuration level (project vs organization)
if [ -z "$ORG_LEVEL" ]; then
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
else
  # Validate provided level
  if [ "$ORG_LEVEL" != "project" ] && [ "$ORG_LEVEL" != "organization" ]; then
    print_status "red" "Invalid level: $ORG_LEVEL. Must be 'project' or 'organization'."
    exit 1
  fi
  
  # If organization level is specified but no organization ID provided, prompt for it
  if [ "$ORG_LEVEL" == "organization" ] && [ -z "$ORGANIZATION_ID" ]; then
    ORGANIZATIONS=$(gcloud organizations list --format="value(displayName,name)" 2>/dev/null)
    ORG_PERMISSIONS=$?

    if [ "$ORG_PERMISSIONS" -ne 0 ] || [ -z "$ORGANIZATIONS" ]; then
      print_status "red" "No organizations found or insufficient permissions to list organizations."
      print_status "red" "Cannot proceed with organization-level setup."
      exit 1
    else
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
  fi
fi

# Get and validate project ID
if [ -z "$PROJECT_ID" ]; then
  echo -e "\nEnter the project ID to create the service account (usually project that contains the billing dataset):"
  read -r PROJECT_ID
fi

if ! validate_project_id "$PROJECT_ID"; then
  exit 1
fi

# Verify project exists and user has access
print_status "blue" "Verifying project access..."
if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
  print_status "red" "Project $PROJECT_ID not found or you don't have access to it."
  exit 1
fi

# Read IAM roles to get count for confirmation
IAM_ROLES_FILE="iam-roles.txt"
if [ ! -f "$IAM_ROLES_FILE" ]; then
  print_status "red" "IAM roles file '$IAM_ROLES_FILE' not found."
  exit 1
fi

# Count IAM roles for confirmation
declare -a IAM_ROLES=()
while IFS= read -r line; do
  if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
    IAM_ROLES+=("$line")
  fi
done < "$IAM_ROLES_FILE"

if [ ${#IAM_ROLES[@]} -eq 0 ]; then
  print_status "red" "No IAM roles found in '$IAM_ROLES_FILE'."
  exit 1
fi

# Set target ID for confirmation
if [ "$ORG_LEVEL" == "organization" ]; then
  TARGET_ID="$ORGANIZATION_ID"
else
  TARGET_ID="$PROJECT_ID"
fi

# Set service account email for confirmation
SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Show confirmation prompt
show_confirmation "$PROJECT_ID" "$ORG_LEVEL" "$TARGET_ID" "$SERVICE_ACCOUNT_EMAIL" "$SECRET_NAME" "${#IAM_ROLES[@]}" "${IAM_ROLES[@]}"

# Enable necessary APIs on the specified project
print_status "blue" "Enabling required APIs..."
enable_service_api "$PROJECT_ID" "recommender.googleapis.com"
enable_service_api "$PROJECT_ID" "cloudresourcemanager.googleapis.com"
enable_service_api "$PROJECT_ID" "compute.googleapis.com"
enable_service_api "$PROJECT_ID" "secretmanager.googleapis.com"

# Create service account
create_service_account "$SERVICE_ACCOUNT_NAME" "$SERVICE_ACCOUNT_DISPLAY_NAME" "$PROJECT_ID"

# Wait for the service account to be fully available
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
print_status "blue" "Adding IAM policy bindings at $ORG_LEVEL level..."

# IAM roles are already loaded from the confirmation section
print_status "blue" "Found ${#IAM_ROLES[@]} IAM roles to assign..."

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