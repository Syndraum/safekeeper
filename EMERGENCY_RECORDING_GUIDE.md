# Emergency Recording Feature - Quick Guide

## 🚨 What is the Emergency Recording Feature?

A floating red button that appears on **every screen** of the SafeKeeper app, allowing you to instantly record audio in emergency situations. Recordings are automatically encrypted and stored securely.

## 🎯 Key Benefits

- ✅ **Instant Access**: Available on all screens, even before login
- ✅ **No Prompts**: Press once to start, press again to stop
- ✅ **Automatic Naming**: Files named with timestamp automatically
- ✅ **Secure Storage**: Encrypted with military-grade encryption
- ✅ **Always Visible**: Red floating button in bottom-right corner

## 📱 How to Use

### Starting a Recording

1. Look for the **red floating button** with microphone icon in the bottom-right corner
2. **Tap once** to start recording immediately
3. The button will start pulsing and show a timer
4. A "RECORDING" label appears above the button

### During Recording

- The timer shows elapsed time (MM:SS format)
- You can navigate to other screens while recording
- The recording continues in the background
- The button remains visible and pulsing

### Stopping a Recording

1. **Tap the button again** (now showing a stop icon)
2. Recording stops immediately
3. A "Processing..." overlay appears briefly
4. You'll see a success message with the filename
5. The recording is now saved and encrypted

### Accessing Your Recordings

1. Go to **"Voir mes documents"** (View my documents)
2. Look for files named `emergency_record_YYYY-MM-DD_HH-MM-SS.m4a`
3. Tap to play or manage like any other document

## 🔒 Security

All emergency recordings are:
- Encrypted with **RSA-2048 + AES-256**
- Protected with **HMAC-SHA256** integrity verification
- Stored in secure app directory
- Accessible only after authentication

## 📋 File Naming Convention

Files are automatically named with the format:
```
emergency_record_2024-01-15_14-30-45.m4a
                 YYYY-MM-DD_HH-MM-SS
```

Example: A recording made on January 15, 2024 at 2:30:45 PM will be named:
`emergency_record_2024-01-15_14-30-45.m4a`

## 🎤 Audio Quality

- **Format**: M4A (MPEG-4 Audio)
- **Codec**: AAC-LC
- **Bitrate**: 128 kbps
- **Sample Rate**: 44.1 kHz
- **Quality**: High quality for voice and ambient sound

## ⚠️ Important Notes

### First Use
- On first use, you'll be asked to grant microphone permission
- This is required for the feature to work
- You can manage permissions in device settings

### Best Practices
- Test the feature before relying on it in emergencies
- Ensure your device has sufficient storage space
- Keep the app updated for best performance

### Limitations
- Recording may pause if app is force-closed by system
- Very long recordings consume more storage
- Feature requires microphone permission

## 🔧 Troubleshooting

### Button Not Visible
- The button should always be visible in the bottom-right corner
- If not visible, try restarting the app
- Check if the app is up to date

### Recording Not Starting
- **Check Permissions**: Go to device Settings → Apps → SafeKeeper → Permissions → Microphone
- **Grant Permission**: Enable microphone access
- **Restart App**: Close and reopen the app

### No Sound in Recording
- Check if device microphone is working (test with other apps)
- Ensure microphone is not muted or blocked
- Verify microphone permission is granted

### Recording Not Appearing in List
- Wait a few seconds for encryption to complete
- Pull down to refresh the document list
- Check if you're logged in to the correct account

## 💡 Tips

1. **Test First**: Make a test recording to familiarize yourself with the feature
2. **Quick Access**: The button is always accessible, even from the lock screen (after initial setup)
3. **Background Recording**: You can use other features while recording
4. **Automatic Save**: No need to manually save - it's automatic
5. **Secure by Default**: All recordings are encrypted immediately

## 📞 Support

If you encounter issues:
1. Check this guide for troubleshooting steps
2. Verify microphone permissions in device settings
3. Ensure the app is updated to the latest version
4. Test on a physical device (not emulator)

## 🎯 Use Cases

Perfect for:
- Emergency situations requiring audio documentation
- Quick voice notes that need to be secure
- Recording important conversations
- Capturing audio evidence
- Voice memos in sensitive situations

---

**Remember**: This feature is designed for emergency use. All recordings are encrypted and secure, but use responsibly and in accordance with local laws regarding audio recording.
