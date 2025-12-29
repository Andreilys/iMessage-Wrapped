---
description: Build the iMessage AI app to releases folder
---

# Build iMessage AI

// turbo-all

1. Build the app:
```bash
cd "/Users/andreilyskov/Downloads/iMessage AI" && xcodebuild -scheme iMessageWrapped -configuration Debug -destination 'platform=macOS' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

2. Copy only the .app to releases:
```bash
/bin/rm -rf "/Users/andreilyskov/Downloads/iMessage AI/releases/iMessage AI.app" && cp -R ~/Library/Developer/Xcode/DerivedData/iMessageWrapped-*/Build/Products/Debug/"iMessage AI.app" "/Users/andreilyskov/Downloads/iMessage AI/releases/"
```

3. Verify:
```bash
ls -la "/Users/andreilyskov/Downloads/iMessage AI/releases/"
```

4. Run the app:
```bash
open "/Users/andreilyskov/Downloads/iMessage AI/releases/iMessage AI.app"
```
