# GCP Wiv Onboarding Tutorial

## Welcome to the GCP Wiv Onboarding Tutorial

This interactive tutorial will guide you through setting up a Google Cloud service account for the Wiv platform. You'll learn how to securely configure the necessary permissions and store credentials in Secret Manager.

**Time to complete**: About 10-15 minutes

**Prerequisites**: 
- A Google Cloud account with billing enabled
- Access to a Google Cloud project
- Basic familiarity with Google Cloud Console

**What you'll accomplish**:
- Create a secure service account for Wiv
- Enable required Google Cloud APIs
- Configure IAM permissions at project or organization level
- Store service account credentials securely in Secret Manager

Click **Continue** to get started!

## What is the Wiv Platform?

Before we begin, let's understand what we're setting up.

The Wiv platform is a cloud cost optimization and management solution that helps organizations:
- Analyze and optimize Google Cloud spending
- Monitor resource usage and performance
- Provide recommendations for cost savings
- Generate comprehensive billing reports

To function properly, Wiv needs a service account with specific permissions to access your Google Cloud resources and billing data. This tutorial will help you set up this service account securely.

**Security Note**: We'll store the service account credentials in Google Secret Manager instead of local files, following security best practices.

Continue to the next step to start the setup process.

## Prerequisites Check

Let's first verify that you have the necessary access and tools to complete this setup.

### Check Google Cloud CLI

First, let's verify that the Google Cloud CLI is available and you're authenticated:

```bash
gcloud --version
```

### Check Authentication Status

Now let's check if you're already authenticated with Google Cloud:

```bash
gcloud auth list
```

If you see "No credentialed accounts" or need to authenticate, run:

```bash
gcloud auth login
```

**Tip**: Follow the browser prompts to complete the authentication process.

### Verify Project Access

Let's check what projects you have access to:

```bash
gcloud projects list --format="table[box,title=Your Projects](name,projectId,projectNumber)"
```

**Note**: You'll need access to at least one project to proceed. If you don't see any projects, contact your Google Cloud administrator.

Continue to the next step once you're authenticated and can see your projects.

## Choose Your Configuration Level

Now we need to determine whether you want to set up the Wiv service account for a single project or for your entire organization.

### Understanding the Options

**Standalone Project**: 
- Service account permissions apply only to one specific project
- Good for testing or single-project deployments
- Faster to set up

**Entire Organization**:
- Service account permissions apply to all projects in your organization
- Better for production deployments
- Requires organization-level permissions

### Check Organization Access

Let's see if you have access to organizations:

```bash
gcloud organizations list --format="table[box,title=Your Organizations](displayName,name)"
```

**Note**: If you see "No organizations found" or get a permission error, you'll need to use the standalone project option.

### Make Your Choice

Based on your needs and the results above, decide whether you want to:
1. Set up for a **Standalone Project** (recommended for first-time users)
2. Set up for **Entire Organization** (if you have org-level permissions and want org-wide access)

**Tip**: If you're unsure, start with a standalone project. You can always expand the permissions later.

Continue to the next step to proceed with your chosen configuration.

## Select Your Project

Now let's identify the project where you'll create the Wiv service account.

### View Available Projects

Let's see all the projects you have access to:

```bash
gcloud projects list --format="table[box,title=Available Projects](name,projectId,projectNumber)"
```

### Choose Your Project

Look at the list above and identify the project where you want to create the Wiv service account. 

**Important**: This should typically be the project that contains your billing dataset or the project where you want to manage your cloud costs.

### Set Your Project ID

Replace `YOUR_PROJECT_ID` with the actual project ID you chose:

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
```

### Verify Project Access

Let's verify that you have the necessary permissions on this project:

```bash
gcloud projects describe $PROJECT_ID
```

**Note**: If you get a permission error, you'll need to either:
- Choose a different project where you have access
- Contact your Google Cloud administrator to grant you the necessary permissions

Continue to the next step once you've successfully set and verified your project.

## Download and Prepare the Script

Now let's get the onboarding script ready to run.

### Download the Script

Let's download the GCP Wiv Onboarding script:

```bash
curl -O https://raw.githubusercontent.com/commitgcp/Wiv-GCPOnBoarding/main/GCPWivOnBoarding.sh
```

### Make the Script Executable

Now let's make the script executable:

```bash
chmod +x GCPWivOnBoarding.sh
```

### Verify the Script

Let's take a quick look at what the script will do:

```bash
head -20 GCPWivOnBoarding.sh
```

**Tip**: The script includes comprehensive error handling and will guide you through each step with colored status messages.

Continue to the next step to start the automated setup process.

## Run the Onboarding Script

Now it's time to execute the script and let it handle the setup automatically.

### Start the Script

Run the onboarding script:

```bash
./GCPWivOnBoarding.sh
```

### Follow the Interactive Prompts

The script will now guide you through several prompts:

1. **Authentication**: If needed, the script will open a browser for you to authenticate
2. **Configuration Level**: Choose between "Standalone Project" or "Entire Organization"
3. **Organization Selection**: If you chose organization-level, select your organization
4. **Project ID**: Enter the project ID (you can use the one we set earlier: `$PROJECT_ID`)

### What the Script Will Do

The script will automatically:
- Enable required APIs (Recommender, Cloud Resource Manager, Compute, Secret Manager)
- Create the `wiv-sa` service account
- Generate a service account key and store it securely in Secret Manager
- Grant the service account access to its own key
- Configure all necessary IAM permissions

**Tip**: The script includes progress indicators and will show you exactly what's happening at each step.

Continue to the next step once the script has completed successfully.

## Verify the Setup

Let's verify that everything was set up correctly.

### Check Service Account Creation

Verify that the service account was created:

```bash
gcloud iam service-accounts list --project=$PROJECT_ID --filter="email:wiv-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

### Check Secret Manager

Verify that the service account key was stored in Secret Manager:

```bash
gcloud secrets list --project=$PROJECT_ID --filter="name:wiv-service-account-key"
```

### Check IAM Permissions

Let's see what permissions were granted to the service account:

```bash
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:serviceAccount:wiv-sa@$PROJECT_ID.iam.gserviceaccount.com" --format="table(bindings.role)"
```

### Test Secret Access

Let's verify that the service account can access its own key:

```bash
gcloud secrets versions access latest --secret="wiv-service-account-key" --project=$PROJECT_ID
```

**Note**: This command should return the service account key JSON content, confirming that the setup is working correctly.

Continue to the next step to learn how to use the service account.

## Access the Service Account Key

Now let's learn how to access the service account key for use with the Wiv platform.

### Retrieve the Key

To get the service account key for use in applications:

```bash
gcloud secrets versions access latest --secret="wiv-service-account-key" --project=$PROJECT_ID --format="value(payload.data)" | base64 --decode
```

### Save the Key to a File (if needed)

If you need to save the key to a file for application configuration:

```bash
gcloud secrets versions access latest --secret="wiv-service-account-key" --project=$PROJECT_ID --format="value(payload.data)" | base64 --decode > wiv-service-account-key.json
```

### Verify the Key File

Check that the key file was created correctly:

```bash
ls -la wiv-service-account-key.json
```

**Security Tip**: If you created a local key file, remember to delete it after configuring your application, as the key is securely stored in Secret Manager.

### Clean Up Local Files

If you created a local key file and no longer need it:

```bash
rm -f wiv-service-account-key.json
```

**Important**: The service account key is now securely stored in Secret Manager and can be accessed programmatically by applications that have the proper permissions.

Continue to the next step for the final summary.

## Configuration Summary

Let's review what we've accomplished and provide you with the key information you'll need.

### What Was Created

✅ **Service Account**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
✅ **Secret Manager Secret**: `wiv-service-account-key`
✅ **IAM Permissions**: Comprehensive set of viewer and access roles
✅ **API Access**: All required Google Cloud APIs enabled

### Key Information for Wiv Configuration

**Service Account Email**: `wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`
**Secret Name**: `wiv-service-account-key`
**Project ID**: `$PROJECT_ID`

### Available Permissions

The service account has been granted the following key permissions:
- Cloud Cost Management (Recommender, Billing)
- Resource Monitoring (Compute, Storage, BigQuery)
- Security and Compliance (IAM, Security Center)
- Application Services (Cloud Run, Functions, Pub/Sub)

### Next Steps for Wiv Integration

1. **Configure Wiv Platform**: Use the service account email and project ID in your Wiv platform configuration
2. **Access Credentials**: Applications can retrieve the service account key from Secret Manager
3. **Monitor Usage**: The service account will start collecting data once Wiv is configured

**Tip**: Keep the service account email and project ID handy for your Wiv platform setup.

Continue to the final step for cleanup instructions.

## Congratulations

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You've successfully completed the GCP Wiv Onboarding setup!

### What You've Accomplished

🎉 Created a secure service account for the Wiv platform
🎉 Enabled all necessary Google Cloud APIs
🎉 Configured comprehensive IAM permissions
🎉 Stored credentials securely in Secret Manager
🎉 Verified the setup is working correctly

### Key Takeaways

- **Security First**: Service account credentials are stored securely in Secret Manager, not locally
- **Comprehensive Access**: The service account has all necessary permissions for Wiv to function
- **Easy Management**: You can easily update permissions or regenerate keys through Google Cloud Console
- **Production Ready**: This setup follows Google Cloud security best practices

### Next Steps

1. **Configure Wiv Platform**: Use the service account email (`wiv-sa@$PROJECT_ID.iam.gserviceaccount.com`) in your Wiv platform configuration
2. **Test Integration**: Verify that Wiv can access your Google Cloud data
3. **Monitor Usage**: Check that cost optimization recommendations start appearing

### Cleanup (Optional)

If you created any temporary files during this tutorial, you can clean them up:

```bash
rm -f wiv-service-account-key.json GCPWivOnBoarding.sh
```

**Note**: The service account and Secret Manager secret will remain in your Google Cloud project for ongoing use.

### Additional Resources

- [Google Cloud IAM Documentation](https://cloud.google.com/iam/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Wiv Platform Documentation](https://docs.wiv.ai)

Thank you for completing this tutorial! Your Google Cloud environment is now ready for Wiv platform integration. 