#!/bin/bash

# GCP Wiv Onboarding Tutorial Launcher
# This script helps users launch the interactive tutorial in Cloud Shell

echo "🚀 GCP Wiv Onboarding Tutorial Launcher"
echo "========================================"
echo ""
echo "This will open the interactive tutorial in Google Cloud Shell."
echo "The tutorial will guide you through setting up the Wiv service account step-by-step."
echo ""

# Check if we're in a browser environment
if command -v xdg-open >/dev/null 2>&1; then
    # Linux
    BROWSER_CMD="xdg-open"
elif command -v open >/dev/null 2>&1; then
    # macOS
    BROWSER_CMD="open"
elif command -v start >/dev/null 2>&1; then
    # Windows
    BROWSER_CMD="start"
else
    echo "❌ Could not detect browser command. Please manually open the URL below:"
    echo ""
    echo "https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/your-org/wiv-onboarding&cloudshell_tutorial=tutorial.md"
    echo ""
    exit 1
fi

# Cloud Shell tutorial URL
TUTORIAL_URL="https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/your-org/wiv-onboarding&cloudshell_tutorial=tutorial.md"

echo "📋 Tutorial URL:"
echo "$TUTORIAL_URL"
echo ""
echo "🌐 Opening tutorial in your default browser..."
echo ""

# Open the tutorial URL
$BROWSER_CMD "$TUTORIAL_URL"

echo "✅ Tutorial should now be opening in your browser!"
echo ""
echo "📝 What happens next:"
echo "1. Cloud Shell will open in your browser"
echo "2. The tutorial will automatically start"
echo "3. Follow the step-by-step instructions"
echo "4. Complete the GCP Wiv onboarding setup"
echo ""
echo "💡 Tip: Make sure you're logged into your Google Cloud account in the browser"
echo ""
echo "🔗 If the tutorial doesn't open automatically, copy and paste this URL:"
echo "$TUTORIAL_URL" 