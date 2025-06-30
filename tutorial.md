# GCP Wiv Onboarding Tutorial

## Page 1: Welcome

Welcome to the GCP Wiv Onboarding Tutorial! 🚀

This tutorial will guide you through setting up a Google Cloud service account for the Wiv platform in just a few simple steps.

**What you'll accomplish:**
- Create a secure service account for Wiv
- Store credentials safely in Secret Manager
- Configure necessary permissions
- Test the setup

**Time to complete:** 5-10 minutes

**Prerequisites:** 
- Google Cloud account with billing enabled
- Access to a Google Cloud project

Click **Continue** to get started!

## Page 2: Setup Required Environment Variables

Let's set up the environment variables needed for the script. We'll do this step by step.

### Step 1: Set Your Project ID

First, let's identify your project ID. This is where the service account will be created.

```bash
# List your available projects
gcloud projects list --format="table[box,title=Your Projects](name,projectId,projectNumber)"
```

Now set your project ID:
```bash
export PROJECT_ID="YOUR_PROJECT_ID_HERE"
```

**What this does:** Tells the script which Google Cloud project to use for creating the service account.

### Step 2: Choose Configuration Level

Decide whether you want project-level or organization-level access:

```bash
# For project-level access (recommended for first-time users)
export CONFIG_LEVEL="project"

# OR for organization-level access (if you have org permissions)
export CONFIG_LEVEL="organization"
```

**What this does:** Determines the scope of permissions for the service account.

### Step 3: Set Organization ID (if needed)

If you chose organization-level access, set your organization ID:

```bash
# List your organizations
gcloud organizations list --format="table[box,title=Your Organizations](displayName,name)"

# Set organization ID (only if using organization-level)
export ORGANIZATION_ID="YOUR_ORG_ID_HERE"
```

**What this does:** Specifies which organization to grant permissions to.

### Step 4: Verify Your Setup

Let's verify everything is set correctly:

```bash
echo "Project ID: $PROJECT_ID"
echo "Config Level: $CONFIG_LEVEL"
if [ "$CONFIG_LEVEL" == "organization" ]; then
  echo "Organization ID: $ORGANIZATION_ID"
fi
```

Continue to the next step once your environment variables are set.

## Page 3: Authentication

Before running the script, let's ensure you're properly authenticated with Google Cloud.

### Check Current Authentication Status

```bash
# Check if you're already authenticated
gcloud auth list
```

### Login to Google Cloud (if needed)

If you see "No credentialed accounts" or need to authenticate:

```bash
# Login to Google Cloud
gcloud auth login
```

**What this does:** Opens a browser window where you can sign in to your Google Cloud account.

### Verify Project Access

Let's verify you have access to the project you specified:

```bash
# Test access to your project
gcloud projects describe "$PROJECT_ID"
```

**Expected Result:** You should see project details without any permission errors.

### Verify Organization Access (if using organization-level)

If you're using organization-level configuration:

```bash
# Test access to your organization
gcloud organizations describe "$ORGANIZATION_ID"
```

**Expected Result:** You should see organization details without any permission errors.

**Note:** If you get permission errors, contact your Google Cloud administrator to grant the necessary permissions.

Continue to the next step once you're authenticated and have verified access.

## Page 4: Script Execution

Now let's run the onboarding script with your configured settings.

### Download and Execute the Script

```bash
# Download the script
curl -O https://raw.githubusercontent.com/commitgcp/Wiv-GCPOnBoarding/onboarding-improvements/GCPWivOnBoarding.sh

# Make it executable
chmod +x GCPWivOnBoarding.sh

# Run the script with your settings
./GCPWivOnBoarding.sh -p "$PROJECT_ID" -l "$CONFIG_LEVEL" -n
```

**What the script will do:**
1. ✅ Enable required APIs (Recommender, Secret Manager, etc.)
2. ✅ Create service account `wiv-sa`
3. ✅ Generate and store key in Secret Manager
4. ✅ Grant necessary IAM permissions
5. ✅ Configure Secret Manager access

**Note:** The `-n` flag skips authentication if you're already logged in.

### Alternative: Interactive Mode

If you prefer to be prompted for each setting:

```bash
./GCPWivOnBoarding.sh
```

Continue to the next step once the script completes successfully.

## Page 5: Test Results

Let's verify that everything was set up correctly.

### Check Service Account Creation

```bash
# Verify service account exists
gcloud iam service-accounts list --project="$PROJECT_ID" --filter="email:wiv-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

### Check Secret Manager

```bash
# Verify secret was created
gcloud secrets list --project="$PROJECT_ID" --filter="name:wiv-service-account-key"
```

### Test Secret Access

```bash
# Test that you can access the secret
gcloud secrets versions access latest --secret="wiv-service-account-key" --project="$PROJECT_ID" --format="value(payload.data)" | base64 --decode | head -5
```

**Expected Results:**
- ✅ Service account should be listed
- ✅ Secret should be listed
- ✅ Secret content should show JSON key data

If all tests pass, your setup is working correctly!

## Page 6: Grant Access to Wiv Team

Now let's grant the Wiv team access to the service account key.

### Option A: Grant Secret Manager Access (Recommended)

Grant the Wiv team access to read the secret:

```bash
# Grant access to the Wiv team
gcloud secrets add-iam-policy-binding "wiv-service-account-key" \
  --project="$PROJECT_ID" \
  --member="user:gcp-finops@comm-it.cloud" \
  --role="roles/secretmanager.secretAccessor"
```

**What this does:** Allows the Wiv team to access the service account key through Secret Manager.

### Option B: Download Key Locally (Alternative)

If you need to provide the key file directly:

```bash
# Download the key to a local file
gcloud secrets versions access latest --secret="wiv-service-account-key" --project="$PROJECT_ID" --format="value(payload.data)" | base64 --decode > wiv-service-account-key.json

# Verify the file was created
ls -la wiv-service-account-key.json
```

**Security Note:** If you download the key locally, remember to delete it after sharing:
```bash
rm wiv-service-account-key.json
```

Choose the option that works best for your workflow.

## Page 7: Summary

🎉 **Congratulations!** You've successfully completed the GCP Wiv Onboarding setup.

### What Was Created

✅ **Service Account**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
✅ **Secret Manager Secret**: `wiv-service-account-key`
✅ **IAM Permissions**: Comprehensive set of viewer and access roles
✅ **API Access**: All required Google Cloud APIs enabled

### Key Information for Wiv Configuration

**Service Account Email**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
**Secret Name**: `wiv-service-account-key`
**Project ID**: `$PROJECT_ID`

### Next Steps

1. **Configure Wiv Platform**: Use the service account email and project ID in your Wiv platform configuration
2. **Access Credentials**: The Wiv team can now access the service account key through Secret Manager
3. **Monitor Usage**: The service account will start collecting data once Wiv is configured

### Cleanup (Optional)

If you created any temporary files during this tutorial:

```bash
rm -f wiv-service-account-key.json GCPWivOnBoarding.sh
```

**Note**: The service account and Secret Manager secret will remain in your Google Cloud project for ongoing use.

### Additional Resources

- [Google Cloud IAM Documentation](https://cloud.google.com/iam/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Wiv Platform Documentation](https://docs.wiv.ai)

Thank you for completing this tutorial! Your Google Cloud environment is now ready for Wiv platform integration. 🚀 