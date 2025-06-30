# Changelog

All notable changes to the GCP Wiv Onboarding project will be documented in this file.

## [2.0.0] - 2024-12-19

### 🚀 Major Features

#### Interactive Tutorial System
- **Added**: Complete interactive tutorial system with `tutorial.md`
- **Added**: Cloud Shell integration with automatic tutorial launch
- **Added**: `launch-tutorial.sh` script for easy tutorial access
- **Added**: Step-by-step guided setup process for non-technical users

#### Command-Line Interface Enhancement
- **Added**: Full command-line parameter support for automation
- **Added**: Interactive and non-interactive execution modes
- **Added**: Built-in help system with usage examples
- **Added**: Parameter validation and error handling
- **Added**: Pre-execution confirmation prompt with detailed action summary

#### Security Improvements
- **Changed**: Service account key storage from local files to Google Secret Manager
- **Added**: Automatic cleanup of temporary key files
- **Added**: Secure key access through Secret Manager API
- **Added**: Service account access to its own key in Secret Manager

### 🔧 Technical Improvements

#### Script Architecture
- **Added**: Modular function-based architecture
- **Added**: Comprehensive error handling with colored status messages
- **Added**: Configuration variables for easy customization
- **Added**: Progress indicators and detailed logging
- **Added**: External IAM roles configuration file (`iam-roles.txt`)

#### API and Service Management
- **Added**: Secret Manager API integration
- **Added**: Enhanced API enablement with status checking
- **Added**: Comprehensive IAM role management
- **Added**: Project and organization-level configuration support
- **Added**: Dynamic IAM role loading from external file

### 📚 Documentation Enhancements

#### README.md Improvements
- **Added**: Quick start section with Cloud Shell button
- **Added**: Security features documentation
- **Added**: Command-line usage examples
- **Added**: Interactive vs non-interactive mode documentation

#### Tutorial Documentation
- **Added**: Complete interactive tutorial (`tutorial.md`)
- **Added**: Step-by-step setup instructions
- **Added**: Prerequisites and verification steps
- **Added**: Configuration level selection guidance

### 🛠️ New Script Features

#### Command-Line Options
- `-p, --project-id PROJECT_ID`: Specify project ID directly
- `-l, --level LEVEL`: Set configuration level ('project' or 'organization')
- `-o, --organization-id ORG_ID`: Specify organization ID for org-level setup
- `-n, --no-login`: Skip authentication (useful when already logged in)
- `-h, --help`: Show detailed help and usage examples

#### Execution Modes
- **Interactive Mode**: `./GCPWivOnBoarding.sh` (prompts for all parameters)
- **Non-Interactive Mode**: `./GCPWivOnBoarding.sh -p my-project -l project -n`

### 🔒 Security Enhancements

#### Key Management
- **Changed**: Keys stored in Secret Manager instead of local files
- **Added**: Automatic temporary file cleanup
- **Added**: Secure key access through Secret Manager API
- **Added**: Service account access to its own key

#### Access Control
- **Added**: Enhanced IAM role assignments
- **Added**: Organization and project-level configuration
- **Added**: Comprehensive permission validation
- **Added**: Input sanitization and validation

### 📋 IAM Roles Added

The script now assigns a comprehensive set of IAM roles including:
- `roles/recommender.computeViewer`
- `roles/recommender.viewer`
- `roles/monitoring.viewer`
- `roles/compute.viewer`
- `roles/bigquery.jobUser`
- `roles/container.viewer`
- `roles/storage.objectViewer`
- `roles/cloudsql.viewer`
- `roles/run.viewer`
- `roles/cloudfunctions.viewer`
- `roles/pubsub.viewer`
- `roles/logging.viewer`
- `roles/iam.securityReviewer`
- `roles/securitycenter.viewer`
- And many more...

### 🔄 Backward Compatibility

- **Maintained**: All existing interactive functionality
- **Maintained**: Same service account naming convention (`wiv-sa`)
- **Maintained**: Same IAM role assignments
- **Maintained**: Same API enablement process
- **Enhanced**: Error handling and user feedback

### 🐛 Bug Fixes

- **Fixed**: Cloud Shell tutorial integration issues
- **Fixed**: Branch-specific file references
- **Fixed**: Missing Secret Manager API enablement
- **Fixed**: Inconsistent error handling
- **Fixed**: Missing project validation

### 📦 New Files Added

- `tutorial.md` - Interactive tutorial for Cloud Shell
- `launch-tutorial.sh` - Tutorial launcher script
- `CHANGELOG.md` - This changelog file
- `iam-roles.txt` - External IAM roles configuration file

### 🔧 Files Modified

- `GCPWivOnBoarding.sh` - Complete rewrite with new features
- `README.md` - Comprehensive documentation update
- Cloud Shell URLs updated to use `onboarding-improvements` branch

### 🚀 Usage Examples

#### Interactive Mode (Recommended for First-Time Users)
```bash
./GCPWivOnBoarding.sh
```

#### Non-Interactive Mode (For Automation)
```bash
# Project-level setup
./GCPWivOnBoarding.sh -p my-project-id -l project

# Organization-level setup
./GCPWivOnBoarding.sh -p my-project-id -l organization -o 123456789

# Skip authentication (already logged in)
./GCPWivOnBoarding.sh -p my-project-id -l project -n

# Show help
./GCPWivOnBoarding.sh --help
```

#### Tutorial Access
```bash
# Launch tutorial in browser
./launch-tutorial.sh

# Or click the "Open in Cloud Shell" button in README.md
```

#### User Experience
- **Added**: Colored output for better visibility
- **Added**: Progress indicators throughout the process
- **Added**: Clear success/failure status messages
- **Added**: Detailed configuration summaries
- **Added**: Next steps guidance
- **Added**: Pre-execution confirmation prompt with detailed action summary

---

## [1.0.0] - 2024-12-18

### Initial Release
- Basic GCP service account creation
- Simple IAM role assignments
- Local key file generation
- Basic interactive prompts
- Minimal documentation 