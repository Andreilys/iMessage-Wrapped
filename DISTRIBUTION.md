# Distribution Guide for iMessage Wrapped

This guide explains how to build, package, and distribute iMessage Wrapped so others can download and run it.

## Quick Start (Build on Your Mac)

### 1. Build the App

```bash
# Navigate to project folder
cd iMessageWrapped

# Build with Xcode command line tools
xcodebuild -project iMessageWrapped.xcodeproj \
           -scheme iMessageWrapped \
           -configuration Release \
           -derivedDataPath build \
           build

# Your app is now at:
# build/Build/Products/Release/iMessageWrapped.app
```

### 2. Create Distribution Package

```bash
# Create a zip for distribution
cd build/Build/Products/Release
zip -r iMessageWrapped.zip iMessageWrapped.app

# Or create a DMG (prettier)
hdiutil create -volname "iMessage Wrapped" \
               -srcfolder iMessageWrapped.app \
               -ov -format UDZO \
               iMessageWrapped.dmg
```

---

## Distribution Options

### Option A: GitHub Releases (Recommended - Free)

1. **Create a GitHub repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   gh repo create iMessageWrapped --public --source=. --push
   ```

2. **Create a Release**
   - Go to your repo → Releases → "Create a new release"
   - Tag: `v1.0.0`
   - Title: `iMessage Wrapped v1.0.0`
   - Upload your `iMessageWrapped.zip` or `.dmg`
   - Publish!

3. **Enable GitHub Pages** (for the landing page)
   - Go to Settings → Pages
   - Source: Deploy from branch `main`, folder `/docs`
   - Your site will be at: `https://yourusername.github.io/iMessageWrapped`

4. **Update the landing page**
   - Edit `docs/index.html`
   - Replace `YOUR_USERNAME` with your actual GitHub username

### Option B: Signed & Notarized (Best UX - $99/year)

If you have an Apple Developer account, you can sign and notarize the app so users don't see scary warnings.

1. **Sign the app**
   ```bash
   codesign --deep --force --verify --verbose \
            --sign "Developer ID Application: Your Name (TEAMID)" \
            --options runtime \
            iMessageWrapped.app
   ```

2. **Create a zip for notarization**
   ```bash
   ditto -c -k --keepParent iMessageWrapped.app iMessageWrapped.zip
   ```

3. **Submit for notarization**
   ```bash
   xcrun notarytool submit iMessageWrapped.zip \
                    --apple-id "your@email.com" \
                    --password "app-specific-password" \
                    --team-id "TEAMID" \
                    --wait
   ```

4. **Staple the ticket**
   ```bash
   xcrun stapler staple iMessageWrapped.app
   ```

5. **Create final distribution package**
   ```bash
   # Create DMG
   hdiutil create -volname "iMessage Wrapped" \
                  -srcfolder iMessageWrapped.app \
                  -ov -format UDZO \
                  iMessageWrapped.dmg
   
   # Sign the DMG too
   codesign --sign "Developer ID Application: Your Name (TEAMID)" \
            iMessageWrapped.dmg
   ```

### Option C: Homebrew Cask

Once you have a stable release on GitHub, you can submit to Homebrew:

1. **Create a Cask formula** at `homebrew-cask/Casks/imessage-wrapped.rb`:
   ```ruby
   cask "imessage-wrapped" do
     version "1.0.0"
     sha256 "YOUR_SHA256_HASH"
   
     url "https://github.com/YOUR_USERNAME/iMessageWrapped/releases/download/v#{version}/iMessageWrapped.dmg"
     name "iMessage Wrapped"
     desc "Spotify Wrapped-style analytics for your iMessages"
     homepage "https://github.com/YOUR_USERNAME/iMessageWrapped"
   
     app "iMessageWrapped.app"
   end
   ```

2. **Submit a PR** to homebrew-cask repository

---

## For Users: Installing Unsigned Apps

Include these instructions on your download page:

### First-Time Launch

Since iMessage Wrapped isn't from the App Store, macOS will block it by default. Here's how to open it:

**Method 1: Right-Click Open (Easiest)**
1. Right-click (or Control-click) on `iMessageWrapped.app`
2. Select "Open" from the menu
3. Click "Open" in the dialog that appears
4. You only need to do this once

**Method 2: System Settings**
1. Try to open the app normally (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down to find the message about iMessageWrapped
4. Click "Open Anyway"

**Method 3: Terminal (Power Users)**
```bash
xattr -cr /Applications/iMessageWrapped.app
```

### Grant Full Disk Access

The app needs permission to read your iMessage database:

1. Open **System Settings**
2. Go to **Privacy & Security → Full Disk Access**
3. Click the **+** button
4. Navigate to and select `iMessageWrapped.app`
5. Restart the app

---

## Automated Build Script

Create a `release.sh` script for easy releases:

```bash
#!/bin/bash
set -e

VERSION=${1:-"1.0.0"}
echo "Building iMessage Wrapped v$VERSION..."

# Clean build
rm -rf build

# Build
xcodebuild -project iMessageWrapped.xcodeproj \
           -scheme iMessageWrapped \
           -configuration Release \
           -derivedDataPath build \
           build

# Package
cd build/Build/Products/Release

# Create ZIP
zip -r "iMessageWrapped-v$VERSION.zip" iMessageWrapped.app
echo "Created: iMessageWrapped-v$VERSION.zip"

# Create DMG
hdiutil create -volname "iMessage Wrapped" \
               -srcfolder iMessageWrapped.app \
               -ov -format UDZO \
               "iMessageWrapped-v$VERSION.dmg"
echo "Created: iMessageWrapped-v$VERSION.dmg"

echo ""
echo "✅ Build complete!"
echo "Files ready for upload:"
ls -la iMessageWrapped-v$VERSION.*
```

---

## Hosting Options

| Option | Cost | Pros | Cons |
|--------|------|------|------|
| **GitHub Releases** | Free | Easy, trusted, handles bandwidth | Users see security warning |
| **GitHub Pages** | Free | Custom landing page, free SSL | Limited to static sites |
| **Netlify/Vercel** | Free | Fast CDN, easy deploys | Can't host large binaries |
| **Your own website** | Varies | Full control | You handle hosting/bandwidth |
| **Mac App Store** | $99/year | Best UX, trusted | Apple review process, sandboxing issues |

---

## Complete Workflow Example

```bash
# 1. Make your changes to the code

# 2. Update version number in Xcode project

# 3. Build release
./release.sh 1.0.0

# 4. Create GitHub release
gh release create v1.0.0 \
   build/Build/Products/Release/iMessageWrapped-v1.0.0.zip \
   build/Build/Products/Release/iMessageWrapped-v1.0.0.dmg \
   --title "iMessage Wrapped v1.0.0" \
   --notes "Initial release!"

# 5. Your download links are now:
# https://github.com/USERNAME/iMessageWrapped/releases/latest/download/iMessageWrapped-v1.0.0.zip
# https://github.com/USERNAME/iMessageWrapped/releases/latest/download/iMessageWrapped-v1.0.0.dmg
```

---

## Summary

**Fastest path to distribution:**

1. Build on your Mac with `xcodebuild`
2. Zip the `.app` file
3. Create a GitHub repo and upload to Releases
4. Share the download link!

Users will need to right-click → Open the first time, but that's standard for open-source Mac apps.
