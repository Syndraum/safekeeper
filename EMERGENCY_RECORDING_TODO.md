# Emergency Recording Feature - Implementation Checklist

## Plan Overview
Add a global floating emergency recording button that:
- Appears on ALL screens (even before login)
- Starts recording instantly on press
- Auto-saves with timestamp filename
- Encrypts and stores automatically
- Shows recording status with timer

## Implementation Steps

### 1. Dependencies
- [x] Add `record: ^5.1.2` to pubspec.yaml
- [x] Add `permission_handler: ^11.3.1` to pubspec.yaml
- [x] Run `flutter pub get`

### 2. Create Recording Service
- [x] Create `lib/services/recording_service.dart`
- [x] Implement singleton pattern
- [x] Add startRecording() method
- [x] Add stopRecording() method
- [x] Add recording state management
- [x] Add duration tracking
- [x] Handle permissions

### 3. Create UI Components
- [x] Create `lib/widgets/emergency_recording_button.dart`
- [x] Implement floating button UI
- [x] Add recording/idle states
- [x] Add pulsing animation for recording state
- [x] Add timer display
- [x] Integrate with recording service

### 4. Create Global Wrapper
- [x] Create `lib/widgets/emergency_recording_wrapper.dart`
- [x] Wrap all screens with recording functionality
- [x] Manage global recording state
- [x] Handle encryption and storage after recording

### 5. Update Main App
- [x] Update `lib/main.dart` to use wrapper
- [x] Initialize recording service at startup

### 6. Update File Type Detector
- [x] Verify M4A/AAC detection in `lib/services/file_type_detector.dart` (Already supports audio files)

### 7. Update Permissions
- [x] Add microphone permission to Android manifest
- [x] Add microphone permission to iOS Info.plist

### 8. Testing
- [ ] Test recording on all screens
- [ ] Test encryption and storage
- [ ] Test playback of recordings
- [ ] Verify permissions handling

## Files Created
- lib/services/recording_service.dart
- lib/widgets/emergency_recording_button.dart
- lib/widgets/emergency_recording_wrapper.dart

## Files Modified
- pubspec.yaml
- lib/main.dart
- lib/services/file_type_detector.dart (if needed)
- android/app/src/main/AndroidManifest.xml
- ios/Runner/Info.plist
