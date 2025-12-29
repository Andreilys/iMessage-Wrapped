#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version>"
    exit 1
fi

PROJECT_NAME="iMessageWrapped"  # Xcode project file name
APP_NAME="iMessageAI"  # Output app name for DMG
SCHEME="iMessageWrapped"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
RELEASE_DIR="releases"
APP_PATH="$BUILD_DIR/Build/Products/Release/iMessage AI.app"  # Built app uses project name

echo "🚀 Starting Release Verification Build v$VERSION..."

# 1. Clean and Build
echo "🧹 Cleaning..."
xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" -configuration Release -quiet

echo "🔨 Building..."
xcodebuild build -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" -configuration Release -derivedDataPath "$BUILD_DIR" -quiet

# 2. Validation
echo "🔍 Verifying binary..."
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App bundle not found at $APP_PATH"
    exit 1
fi

BINARY_PATH="$APP_PATH/Contents/MacOS/iMessage AI"
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Binary executable missing inside bundle at $BINARY_PATH"
    exit 1
fi

SIZE=$(du -k "$BINARY_PATH" | cut -f1)
echo "📦 Binary Size: ${SIZE}KB"
if [ "$SIZE" -lt 100 ]; then
    echo "❌ Error: Binary is too small ($SIZE KB). Likely corruption or link failure."
    exit 1
fi

# 3. Ad-Hoc Code Signing (Fixes 'Damaged' Error)
echo "✍️  Signing Application (Ad-Hoc)..."
codesign --force --deep --sign - --entitlements "iMessageWrapped/iMessageWrapped.entitlements" "$APP_PATH"
echo "✅ Signed."

# 4. Packaging
mkdir -p "$RELEASE_DIR"

# Create ZIP
echo "📦 Zipping..."
ZIP_NAME="$APP_NAME-v$VERSION.zip"
ditto -c -k --keepParent "$APP_PATH" "$RELEASE_DIR/$ZIP_NAME"

# Create DMG with Applications folder drag-and-drop
echo "💿 Creating DMG with install experience..."
DMG_NAME="$APP_NAME-v$VERSION.dmg"
VOL_NAME="$APP_NAME v$VERSION"
TMP_DMG="tmp_$DMG_NAME"
DMG_STAGING="dmg_staging"

# Remove existing
rm -f "$RELEASE_DIR/$DMG_NAME"
rm -f "$TMP_DMG"
rm -rf "$DMG_STAGING"

# Create staging directory with app and Applications alias
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create README for installation
cat > "$DMG_STAGING/README.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                      iMessage AI                              ║
║              AI-Powered Message Insights                      ║
╠══════════════════════════════════════════════════════════════╣
║                                                               ║
║  INSTALLATION:                                                ║
║  ─────────────                                                ║
║  1. Drag "iMessage AI" to the "Applications" folder          ║
║                                                               ║
║  FIRST TIME SETUP:                                           ║
║  ─────────────────                                            ║
║  1. Open System Settings → Privacy & Security                ║
║  2. Go to Full Disk Access                                   ║
║  3. Click + and add iMessage AI                              ║
║  4. Relaunch the app                                         ║
║                                                               ║
║  This permission is required to read your message database.  ║
║                                                               ║
╚══════════════════════════════════════════════════════════════╝
EOF

# Create DMG from staging folder
hdiutil create -size 100m -volname "$VOL_NAME" -srcfolder "$DMG_STAGING" -ov -format UDRW "$TMP_DMG" -quiet

# Mount, customize, and unmount
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$TMP_DMG" | awk '/Volumes/ {print $3}')

# Set icon positions using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 600, 400}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set position of item "iMessage AI.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

# Unmount
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$TMP_DMG" -format UDZO -o "$RELEASE_DIR/$DMG_NAME" -quiet

# Cleanup
rm -f "$TMP_DMG"
rm -rf "$DMG_STAGING"

# Checksums
echo "🔐 Generating Checksums..."
cd "$RELEASE_DIR"
shasum -a 256 "$ZIP_NAME"
shasum -a 256 "$DMG_NAME"
cd ..

echo "========================================"
echo "✅ Release v$VERSION ready and signed!"
echo "   DMG: $RELEASE_DIR/$DMG_NAME"
echo "========================================"
