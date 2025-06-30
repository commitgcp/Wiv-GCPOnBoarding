# GCP Onboarding Script to Wiv Platform

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/your-org/wiv-onboarding&cloudshell_tutorial=tutorial.md)

This script automates the secure setup of a Google Cloud service account and the enabling of necessary APIs. The script performs the following tasks:
1. Authenticates with Google Cloud.
2. Enables required service APIs for a specified project (including Secret Manager).
3. Creates a service account.
4. Generates a key for the service account and stores it securely in Secret Manager.
5. Adds IAM policy bindings for the service account at the organization or project level.
6. Grants the service account access to its own key in Secret Manager.

## Quick Start

**For non-technical users**: 
- Click the "Open in Cloud Shell" button above to launch an interactive tutorial that will guide you through the entire setup process step-by-step.
- Or run `./launch-tutorial.sh` from your local terminal to open the tutorial in your browser.

**For technical users**: Follow the manual steps below or run the script directly.

## Prerequisites

- Google Cloud SDK installed on your machine.
- Access to a Google Cloud account with appropriate permissions to perform the actions in the script.
- The ability to log in to Google Cloud and select an organization (if applicable).

## Security Features

- **Secure Key Storage**: Service account keys are stored in Google Secret Manager instead of local files
- **Automatic Cleanup**: Temporary key files are automatically deleted after secure storage
- **Access Control**: Service account is granted specific Secret Manager access permissions
- **Input Validation**: Project ID format and access permissions are validated before proceeding

## Steps to Run the Script

1. **Open a Terminal**: Open your terminal or command prompt.

2. **Save the Script**: Save the provided script as a `.sh` file, for example, `GCPWivOnBoarding.sh`.

3. **Make the Script Executable**:
   ```bash
   chmod +x GCPWivOnBoarding.sh
   ```

4. **Run the Script**:
   ```bash
   ./GCPWivOnBoarding.sh
   ```

5. **Login to Google Cloud**:
   The script will prompt you to log in to your Google Cloud account:
   ```bash
   gcloud auth login
   ```
   Follow the on-screen instructions to complete the login process.

6. **Choose Configuration Level**:
   The script will ask whether you want to configure for a standalone project or an entire organization:
   ```bash
   Is this for a standalone project or an entire organization?
   1) Standalone Project
   2) Entire Organization
   ```
   Select the appropriate option based on your needs.

7. **Select an Organization** (if applicable):
   If you chose "Entire Organization" and have multiple organizations, the script will list them and ask you to select one:
   ```bash
   Multiple organizations found. Please choose one:
   1) Organization 1
   2) Organization 2
   ```
   Enter the number corresponding to your desired organization.

8. **Enter the Project ID**:
   The script will prompt you to enter the project ID where you want to create the service account:
   ```bash
   Enter the project ID to create the service account (usually project that contains the billing dataset):
   ```
   Enter the project ID and press Enter. The script will validate the format and verify your access.

9. **Script Execution**:
   The script will perform the following actions:
    - Enable the necessary APIs (`recommender.googleapis.com`, `cloudresourcemanager.googleapis.com`, `compute.googleapis.com`, `secretmanager.googleapis.com`) on the specified project.
    - Create a service account named `wiv-sa` with the display name "Wiv Service Account".
    - Generate a key for the service account and store it securely in Secret Manager as `wiv-service-account-key`.
    - Grant the service account access to its own key in Secret Manager.
    - Add IAM policy bindings for the service account at the organization or project level with comprehensive roles including:
      - `roles/recommender.computeViewer`
      - `roles/recommender.viewer`
      - `roles/monitoring.viewer`
      - `roles/compute.viewer`
      - `roles/bigquery.jobUser`
      - `roles/container.viewer`
      - `roles/storage.objectViewer`
      - `roles/bigquery.dataViewer`
      - `roles/cloudsql.viewer`
      - `roles/run.viewer`
      - `roles/cloudfunctions.viewer`
      - `roles/pubsub.viewer`
      - `roles/spanner.viewer`
      - `roles/logging.viewer`
      - `roles/iam.securityReviewer`
      - `roles/compute.networkViewer`
      - `roles/cloudbuild.builds.viewer`
      - `roles/dataflow.viewer`
      - `roles/redis.viewer`
      - `roles/securitycenter.viewer`
      - `roles/cloudkms.viewer`
      - `roles/artifactregistry.reader`
      - `roles/gkebackup.viewer`
      - `roles/cloudasset.viewer`
      - `roles/bigquery.resourceViewer`
      - And more...

10. **Completion**:
    Upon successful completion, the script will output:
    ```bash
    === Onboarding Complete ===
    ✓ Service account wiv-sa@PROJECT_ID.iam.gserviceaccount.com has been created and configured.
    ✓ All necessary permissions have been granted at organization/project level for TARGET_ID.
    ✓ Service account key has been stored securely in Secret Manager.

    === Configuration Summary ===
    Service Account Project: PROJECT_ID
    Service Account Email: wiv-sa@PROJECT_ID.iam.gserviceaccount.com
    Secret Manager Secret Name: wiv-service-account-key
    Target Level: organization/project
    Target ID: TARGET_ID

    === Next Steps ===
    1. The service account key is now stored in Secret Manager as 'wiv-service-account-key'
    2. Applications can access the key using the Secret Manager API
    3. The service account has been granted Secret Manager access
    4. All required IAM permissions have been configured
    ```

## Accessing the Service Account Key

Applications can access the stored service account key using the Secret Manager API:

```bash
# Access the secret value
gcloud secrets versions access latest --secret="wiv-service-account-key" --project="YOUR_PROJECT_ID"
```

Or programmatically using the Secret Manager client libraries.

## Permissions Needed

The user running this script must have the following permissions in Google Cloud:

- **Project Level**:
    - `resourcemanager.projects.setIamPolicy`
    - `iam.serviceAccounts.create`
    - `iam.serviceAccounts.getIamPolicy`
    - `iam.serviceAccounts.setIamPolicy`
    - `iam.serviceAccountKeys.create`
    - `serviceusage.services.enable`
    - `secretmanager.secrets.create`
    - `secretmanager.secrets.addVersion`
    - `secretmanager.secrets.setIamPolicy`

- **Organization Level** (if configuring at organization level):
    - `resourcemanager.organizations.setIamPolicy`

These permissions are typically associated with roles such as `Project Owner`, `Organization Admin`, or custom roles that include the necessary permissions.

## Configuration Options

The script uses the following default configuration values, which can be modified in the script:

- **Service Account Name**: `wiv-sa`
- **Service Account Display Name**: `Wiv Service Account`
- **Secret Manager Secret Name**: `wiv-service-account-key`
- **Temporary Key File**: `temp_key.json`

## Error Handling

The script includes comprehensive error handling:
- Validates project ID format
- Verifies project access permissions
- Checks for existing service accounts and secrets
- Provides colored status messages for better visibility
- Exits gracefully on errors with helpful messages

## Security Best Practices

- Service account keys are never stored locally
- Temporary files are automatically cleaned up
- Access to secrets is granted with minimal required permissions
- Input validation prevents common configuration errors
- All operations are logged with clear status messages

By following these steps and ensuring you have the required permissions, you can successfully run the script to set up the necessary Google Cloud resources and configurations securely.
```
