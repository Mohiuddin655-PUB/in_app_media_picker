# in_app_media_picker

### iOS Specific:

- Limited photo permissions are an iOS feature. Ensure you add proper keys to the Info.plist file
  for requesting photo library permissions:

```text
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to display your photos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to add photos to your library.</string>
```