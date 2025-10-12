# Fix: Multiple commands produce Info.plist Error

## Problem
You're getting this error:
```
Multiple commands produce '/Users/.../SkinSync.app/Info.plist'
```

This happens when both the main app and widget extension have conflicting build settings.

## Solution

### Option 1: Remove "Copy Bundle Resources" Entries (Recommended)

1. **Open Xcode** and select your project
2. **Select the SkinSync main app target**
3. Go to **Build Phases** tab
4. Expand **"Copy Bundle Resources"**
5. Look for any `Info.plist` entries
6. **Remove** any `Info.plist` files from this list (select and press Delete)
7. **Select the SkinSyncWidgets target**
8. Go to **Build Phases** tab
9. Expand **"Copy Bundle Resources"**
10. **Remove** any `Info.plist` files from this list

### Option 2: Check Build Settings

1. **Select the SkinSync main app target**
2. Go to **Build Settings** tab
3. Search for: `INFOPLIST_FILE`
4. Make sure it's set to: `SkinSync/Info.plist`
5. **Select the SkinSyncWidgets target**
6. Go to **Build Settings** tab
7. Search for: `INFOPLIST_FILE`
8. Make sure it's set to: `SkinSyncWidgets/Info.plist`

### Option 3: Generate Info.plist Automatically (iOS 14+)

For the **widget target only**:

1. **Select the SkinSyncWidgets target**
2. Go to **Build Settings** tab
3. Search for: `Generate Info.plist File`
4. Set it to **YES**
5. Search for: `INFOPLIST_FILE`
6. **Delete** the value (leave it empty)
7. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
8. Rebuild

### Option 4: Use "New Build System" Settings

1. Go to **File → Project Settings** (or **Workspace Settings**)
2. Under **Build System**, select: **New Build System (Default)**
3. Click **Done**
4. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
5. Rebuild

## Quick Fix Steps

Try these in order:

1. **Clean Build Folder**
   - Press **⇧⌘K** (Shift + Command + K)
   
2. **Delete Derived Data**
   - Go to **Xcode → Settings → Locations**
   - Click the arrow next to **Derived Data** path
   - Delete the **SkinSync** folder
   - Restart Xcode

3. **Check Info.plist Files**
   ```bash
   # Run this in Terminal to verify Info.plist locations:
   find . -name "Info.plist" -type f | grep -v DerivedData
   ```
   
   Should show:
   ```
   ./SkinSync/Info.plist
   ./SkinSyncWidgets/Info.plist
   ```

4. **Remove from Copy Bundle Resources** (Most Common Fix)
   - Both targets: Remove Info.plist from "Copy Bundle Resources"
   - Info.plist should ONLY be in "Build Settings → INFOPLIST_FILE"

## Verify the Fix

After applying the fix:

1. **Clean Build Folder**: ⇧⌘K
2. **Build the Main App**: Select `SkinSync` scheme, press ⌘B
3. **Build the Widget**: Select `SkinSyncWidgets` scheme, press ⌘B
4. **Run the App**: Select `SkinSync` scheme, press ⌘R

Both should build successfully without errors.

## Why This Happens

The error occurs because:
- Both targets are trying to copy their Info.plist to the same location
- Info.plist is accidentally added to "Copy Bundle Resources"
- Info.plist should be referenced in build settings, not copied as a resource

## Prevention

**Info.plist should:**
- ✅ Be in the target's folder (`SkinSync/Info.plist`, `SkinSyncWidgets/Info.plist`)
- ✅ Be set in "Build Settings → INFOPLIST_FILE"
- ✅ Show up in Xcode's Project Navigator with the target membership

**Info.plist should NOT:**
- ❌ Be in "Copy Bundle Resources" build phase
- ❌ Be in "Compile Sources" build phase
- ❌ Have the same path for multiple targets

## Still Having Issues?

If you're still getting errors, check:

1. **Target Membership**
   - Select `SkinSync/Info.plist` in Project Navigator
   - Open File Inspector (right panel)
   - **Only** SkinSync should be checked
   - Select `SkinSyncWidgets/Info.plist`
   - **Only** SkinSyncWidgets should be checked

2. **Product Bundle Identifier**
   - Main app: `com.yourcompany.SkinSync`
   - Widget: `com.yourcompany.SkinSync.SkinSyncWidgets`
   - Widget identifier must start with app identifier

3. **Deployment Target**
   - Both targets should have the same iOS deployment target
   - Minimum iOS 17.0 for widget support

## After Fixing

Once the build succeeds:

1. Make sure **App Groups** are configured:
   - Both targets need `group.com.skinsync.app`
   - Go to **Signing & Capabilities** tab
   - Add "App Groups" capability if not present

2. Build and run the widget:
   - Select `SkinSyncWidgets` scheme
   - Run on simulator or device
   - Add widget to home screen

The widget will display UV data from the main app! 🎉

