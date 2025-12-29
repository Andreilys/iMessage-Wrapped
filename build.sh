#!/bin/bash

# iMessage Wrapped Build Script
# Run this on a Mac with Xcode installed

set -e

echo "🔨 Building iMessage Wrapped..."
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode command line tools not found."
    echo "   Please install Xcode from the App Store."
    exit 1
fi

# Build the project
echo "📦 Compiling..."
xcodebuild -project iMessageWrapped.xcodeproj \
           -scheme iMessageWrapped \
           -configuration Release \
           -derivedDataPath build \
           build

# Find the built app
APP_PATH="build/Build/Products/Release/iMessageWrapped.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📍 App location: $APP_PATH"
    echo ""
    echo "To run the app:"
    echo "  open \"$APP_PATH\""
    echo ""
    echo "To copy to Applications:"
    echo "  cp -R \"$APP_PATH\" /Applications/"
    echo ""
    echo "⚠️  Remember to grant Full Disk Access in System Settings!"
else
    echo "❌ Build failed. Check the output above for errors."
    exit 1
fi
