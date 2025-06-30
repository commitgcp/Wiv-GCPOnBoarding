# GCP Wiv Onboarding Tutorial

## Welcome

Welcome to the GCP Wiv Onboarding Tutorial! 🚀

This tutorial will guide you through setting up a Google Cloud service account for the Wiv platform in just a few simple steps.

**What you'll accomplish:**
- Create a secure service account for Wiv
- Store credentials safely in Secret Manager
- Configure necessary permissions
- Validate the setup

**Time to complete:** 5 minutes

**Prerequisites:** 
- Google Cloud account with billing enabled
- Access to a Google Cloud project
- Enough privileges to create a service account and grant it permissions in the relevant scope (project/organization)

Click **Start** to get started!

## Setup Required Environment Variables

Let's set up the environment variables needed for the script. We'll do this step by step.

### Step 1: Set Your Project ID

Set the project ID that will store the service account:
```bash
export PROJECT_ID="YOUR_PROJECT_ID_HERE"
```

### Step 2: Choose Configuration Level

Decide whether you want project-level or organization-level access to define the scope of permissions for the service account:

```bash
export CONFIG_LEVEL="project"
```

OR

```bash
export CONFIG_LEVEL="organization"
```

### Step 3: Set Organization ID (if needed)

If you chose organization-level access, set your organization ID:

```bash
export ORGANIZATION_ID="YOUR_ORG_ID_HERE"
```

### Step 4: Verify Your Setup

Let's verify everything is set correctly:

```bash
echo "Project ID: $PROJECT_ID"
echo "Config Level: $CONFIG_LEVEL"
```

If you're using organization-level access, also run:
```bash
echo "Organization ID: $ORGANIZATION_ID"
```

Continue to the next step once your environment variables are set.

## Authentication

Before running the script, let's ensure you're properly authenticated with Google Cloud.

### Login to Google Cloud

If you see "No credentialed accounts" or need to authenticate:

```bash
gcloud auth login --quiet
```

**What this does:** Opens a browser window where you can sign in to your Google Cloud account.

### Verify Project Access

Let's verify you have access to the project you specified:

```bash
gcloud projects describe "$PROJECT_ID"
```

**Expected Result:** You should see project details without any permission errors.

### Verify Organization Access (if using organization-level)

If you're using organization-level configuration:

```bash
gcloud organizations describe "$ORGANIZATION_ID"
```

**Expected Result:** You should see organization details without any permission errors.

**Note:** If you get permission errors, contact your Google Cloud administrator to grant the necessary permissions.

Continue to the next step once you're authenticated and have verified access.

## Script Execution

Now let's run the onboarding script with your configured settings.

### Execute the Script

```bash
./GCPWivOnBoarding.sh -p "$PROJECT_ID" -l "$CONFIG_LEVEL" -n
```

**Note:** The `-n` flag skips authentication if you're already logged in.

**What the script will do:**
1. ✅ Enable required APIs (Recommender, Secret Manager, etc.)
2. ✅ Create service account `wiv-sa`
3. ✅ Generate and store key in Secret Manager
4. ✅ Grant necessary IAM permissions (from iam-roles.txt)
5. ✅ Configure Secret Manager access

**Important:** The script will show a detailed confirmation prompt before performing any actions, allowing you to review what will be created and modified.

Continue to the next step once the script completes successfully.

## Test Results

Let's verify that everything was set up correctly.

### Check Service Account Creation

Verify service account exists:

```bash
gcloud iam service-accounts list --project="$PROJECT_ID" --filter="email=wiv-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

**Expected Results:**
- ✅ Service account should be listed

### Check Secret Manager

Verify secret was created:

```bash
gcloud secrets list --project="$PROJECT_ID" --filter="wiv-service-account-key"
```

**Expected Results:**
- ✅ Secret should be listed

### Test Secret Access

Test that you can access the secret:

```bash
gcloud secrets versions access latest --secret="wiv-service-account-key" --project="$PROJECT_ID" | head -5
```

**Expected Results:**
- ✅ Service account should be listed
- ✅ Secret should be listed
- ✅ Secret content should show JSON key data (first 5 lines)

If all tests pass, your setup is working correctly!

## Share the Service Account Key

Now let's grant access to the service account key to your Wiv administrator.

### Option A: Grant Secret Manager Access (Recommended)

First, let's set up the variables for the Wiv administrator:

```bash
export WIV_ADMIN_EMAIL="YOUR_EMAIL_HERE"
```

# Set the type (group or user):

```bash
export WIV_ADMIN_EMAIL_TYPE="group"
```

**Note:** 
- For groups, use `WIV_ADMIN_EMAIL_TYPE="group"`
- For individual users, use `WIV_ADMIN_EMAIL_TYPE="user"`
- For service accounts, use `WIV_ADMIN_EMAIL_TYPE="serviceAccount"`

Verify the variables are set correctly:

```bash
echo "Email: $WIV_ADMIN_EMAIL"
echo "Type: $WIV_ADMIN_EMAIL_TYPE"
```

Now grant access to the Wiv Administrator:

```bash
gcloud secrets add-iam-policy-binding "wiv-service-account-key" \
  --project="$PROJECT_ID" \
  --member="$WIV_ADMIN_EMAIL_TYPE:$WIV_ADMIN_EMAIL" \
  --role="roles/secretmanager.secretAccessor"
```

**What this does:** Allows the Wiv administrator to access the service account key through Secret Manager.


### Option B: Download Key Locally (Alternative)

If you need to provide the key file directly download the key to a local file using:

```bash
gcloud secrets versions access latest \
  --secret="wiv-service-account-key" \
  --project="$PROJECT_ID" > wiv-service-account-key.json
```

Verify the file was created:

```bash
ls -la wiv-service-account-key.json
```

**Security Note:** If you download the key locally, remember to delete it after sharing:
```bash
rm wiv-service-account-key.json
```

Choose the option that works best for your workflow.

## Summary

🎉 **Congratulations!** You've successfully completed the GCP Wiv Onboarding setup.

### What Was Created

- ✅ **Service Account**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
- ✅ **Secret Manager Secret**: `wiv-service-account-key`
- ✅ **IAM Permissions**: Comprehensive set of viewer and access roles
- ✅ **API Access**: All required Google Cloud APIs enabled

### Key Information for Wiv Configuration

**Service Account Email**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
**Secret Name**: `wiv-service-account-key`
**Project ID**: `$PROJECT_ID`

### Next Steps

1. **Configure Wiv Platform**: Use the service account key in your Wiv platform configuration
2. **Access Credentials**: The Wiv administrator can now access the service account key through Secret Manager
3. **Monitor Usage**: The service account will start collecting data once Wiv is configured

Thank you for completing this tutorial! Your Google Cloud environment is now ready for Wiv platform integration. 🚀

## 🎉 Congratulations!

You've successfully completed the GCP Wiv Onboarding setup.

---

### ✅ What Was Created

- **Service Account:** `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
- **Secret Manager Secret:** `wiv-service-account-key`
- **IAM Permissions:** Comprehensive set of viewer and access roles
- **API Access:** All required Google Cloud APIs enabled

---

### 🔑 Key Information for Wiv Configuration

- **Service Account Email:** `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
- **Secret Name:** `wiv-service-account-key`
- **Project ID:** `$PROJECT_ID`

---

Thank you for completing this tutorial!  

Your Google Cloud environment is now ready for Wiv platform integration. 🚀

---

**This tutorial was crafted with ❤️ by Commit** 