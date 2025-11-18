import 'dart:typed_data';
import 'package:mime/mime.dart';

/// Enum for file type categories
enum FileTypeCategory {
  pdf,
  image,
  text,
  document,
  archive,
  video,
  audio,
  unknown,
}

/// Service for detecting file types based on content (magic numbers) and MIME types
class FileTypeDetector {
  /// Detect file type from file bytes
  static FileTypeInfo detectFromBytes(Uint8List bytes, {String? fileName}) {
    // First try magic number detection (most reliable)
    final magicNumberType = _detectByMagicNumber(bytes);
    
    // Try MIME type detection as fallback or for ambiguous cases
    String? mimeType;
    if (fileName != null && fileName.isNotEmpty) {
      mimeType = lookupMimeType(fileName, headerBytes: bytes);
    } else {
      // Even without filename, try to detect from header bytes alone
      mimeType = lookupMimeType('', headerBytes: bytes);
    }
    
    // Determine category based on magic number or MIME type
    FileTypeCategory category;
    if (magicNumberType != null) {
      // Magic number detection succeeded
      category = magicNumberType;
      // If we detected by magic number, try to get more specific MIME type
      if (mimeType == null) {
        mimeType = _getMimeTypeForCategory(category);
      }
      // Special case: if magic number says video but MIME type indicates audio (e.g., .m4a files)
      // trust the MIME type for ftyp-based files
      if (category == FileTypeCategory.video && mimeType != null) {
        final mimeCategory = _categoryFromMimeType(mimeType);
        if (mimeCategory == FileTypeCategory.audio) {
          category = FileTypeCategory.audio;
        }
      }
    } else if (mimeType != null) {
      // Magic number detection returned null (ambiguous case like mp42/isom)
      // or failed - use MIME type detection
      category = _categoryFromMimeType(mimeType);
      // If MIME type detection also fails, try one more time with just the filename
      if (category == FileTypeCategory.unknown && fileName != null && fileName.isNotEmpty) {
        // Check if filename suggests it's an audio file
        final lowerFileName = fileName.toLowerCase();
        if (lowerFileName.endsWith('.m4a') || 
            lowerFileName.endsWith('.aac') || 
            lowerFileName.endsWith('.mp3') ||
            lowerFileName.endsWith('.wav') ||
            lowerFileName.endsWith('.ogg') ||
            lowerFileName.endsWith('.flac')) {
          category = FileTypeCategory.audio;
          if (mimeType == 'application/octet-stream') {
            mimeType = 'audio/mp4'; // Default for M4A
          }
        }
      }
    } else {
      // Both detection methods failed
      category = FileTypeCategory.unknown;
      mimeType = 'application/octet-stream';
    }
    
    return FileTypeInfo(
      category: category,
      mimeType: mimeType,
    );
  }
  
  /// Detect file type by checking magic numbers (file signatures)
  static FileTypeCategory? _detectByMagicNumber(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    
    // PDF: %PDF (0x25 0x50 0x44 0x46)
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return FileTypeCategory.pdf;
    }
    
    // PNG: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return FileTypeCategory.image;
    }
    
    // JPEG: 0xFF 0xD8 0xFF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return FileTypeCategory.image;
    }
    
    // GIF: GIF87a or GIF89a
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return FileTypeCategory.image;
    }
    
    // BMP: BM (0x42 0x4D)
    if (bytes.length >= 2 &&
        bytes[0] == 0x42 &&
        bytes[1] == 0x4D) {
      return FileTypeCategory.image;
    }
    
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return FileTypeCategory.image;
    }
    
    // ZIP: PK (0x50 0x4B)
    if (bytes.length >= 2 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B) {
      return FileTypeCategory.archive;
    }
    
    // RAR: Rar! (0x52 0x61 0x72 0x21)
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x61 &&
        bytes[2] == 0x72 &&
        bytes[3] == 0x21) {
      return FileTypeCategory.archive;
    }
    
    // 7z: 0x37 0x7A 0xBC 0xAF 0x27 0x1C
    if (bytes.length >= 6 &&
        bytes[0] == 0x37 &&
        bytes[1] == 0x7A &&
        bytes[2] == 0xBC &&
        bytes[3] == 0xAF &&
        bytes[4] == 0x27 &&
        bytes[5] == 0x1C) {
      return FileTypeCategory.archive;
    }
    
    // MP4/MOV/M4A: ftyp
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      // Check if it's M4A (audio) or MP4 (video)
      // M4A files can have various brand identifiers in the ftyp box
      if (bytes.length >= 12) {
        // Check for M4A signature (0x4D 0x34 0x41 0x20 = "M4A ")
        if (bytes[8] == 0x4D && bytes[9] == 0x34 && bytes[10] == 0x41 && bytes[11] == 0x20) {
          return FileTypeCategory.audio;
        }
        // Check for M4B signature (0x4D 0x34 0x42 0x20 = "M4B ") - audiobook format
        if (bytes[8] == 0x4D && bytes[9] == 0x34 && bytes[10] == 0x42 && bytes[11] == 0x20) {
          return FileTypeCategory.audio;
        }
        // Check for M4P signature (0x4D 0x34 0x50 0x20 = "M4P ") - protected audio
        if (bytes[8] == 0x4D && bytes[9] == 0x34 && bytes[10] == 0x50 && bytes[11] == 0x20) {
          return FileTypeCategory.audio;
        }
        // Check for mp42 signature (0x6D 0x70 0x34 0x32 = "mp42")
        // This is commonly used by audio recorders but can also be video
        // We'll return null to let MIME type detection decide
        if (bytes[8] == 0x6D && bytes[9] == 0x70 && bytes[10] == 0x34 && bytes[11] == 0x32) {
          return null; // Let MIME type detection decide
        }
        // Check for isom signature (0x69 0x73 0x6F 0x6D = "isom")
        // ISO Base Media file format - can be audio or video
        // We'll return null to let MIME type detection decide
        if (bytes[8] == 0x69 && bytes[9] == 0x73 && bytes[10] == 0x6F && bytes[11] == 0x6D) {
          return null; // Let MIME type detection decide
        }
        // Check for iso2 signature (0x69 0x73 0x6F 0x32 = "iso2")
        // ISO Base Media file format version 2 - can be audio or video
        if (bytes[8] == 0x69 && bytes[9] == 0x73 && bytes[10] == 0x6F && bytes[11] == 0x32) {
          return null; // Let MIME type detection decide
        }
      }
      // For other ftyp-based files, default to video
      // MIME type detection can still override this
      return FileTypeCategory.video;
    }
    
    // AVI: RIFF....AVI
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x41 &&
        bytes[9] == 0x56 &&
        bytes[10] == 0x49 &&
        bytes[11] == 0x20) {
      return FileTypeCategory.video;
    }
    
    // MP3: ID3 or 0xFF 0xFB
    if (bytes.length >= 3) {
      if ((bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
          (bytes[0] == 0xFF && bytes[1] == 0xFB)) {
        return FileTypeCategory.audio;
      }
    }
    
    // WAV: RIFF....WAVE
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45) {
      return FileTypeCategory.audio;
    }
    
    // Check if it's likely a text file (all printable ASCII or common UTF-8)
    if (_isLikelyTextFile(bytes)) {
      return FileTypeCategory.text;
    }
    
    return null;
  }
  
  /// Check if bytes represent a text file
  static bool _isLikelyTextFile(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    
    // Check first 512 bytes or entire file if smaller
    final checkLength = bytes.length < 512 ? bytes.length : 512;
    int printableCount = 0;
    
    for (int i = 0; i < checkLength; i++) {
      final byte = bytes[i];
      // Printable ASCII, newline, carriage return, tab
      if ((byte >= 0x20 && byte <= 0x7E) ||
          byte == 0x09 ||
          byte == 0x0A ||
          byte == 0x0D) {
        printableCount++;
      }
    }
    
    // If more than 95% are printable characters, consider it text
    return (printableCount / checkLength) > 0.95;
  }
  
  /// Get category from MIME type
  static FileTypeCategory _categoryFromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    
    if (lower.startsWith('image/')) {
      return FileTypeCategory.image;
    } else if (lower == 'application/pdf') {
      return FileTypeCategory.pdf;
    } else if (lower.startsWith('text/')) {
      return FileTypeCategory.text;
    } else if (lower.startsWith('application/msword') ||
        lower.startsWith('application/vnd.openxmlformats-officedocument') ||
        lower.startsWith('application/vnd.ms-') ||
        lower.startsWith('application/vnd.oasis.opendocument')) {
      return FileTypeCategory.document;
    } else if (lower.startsWith('application/zip') ||
        lower.startsWith('application/x-rar') ||
        lower.startsWith('application/x-7z') ||
        lower.startsWith('application/x-tar') ||
        lower.startsWith('application/gzip')) {
      return FileTypeCategory.archive;
    } else if (lower.startsWith('video/')) {
      return FileTypeCategory.video;
    } else if (lower.startsWith('audio/') ||
        lower == 'application/x-m4a' ||
        lower == 'audio/x-m4a' ||
        lower == 'audio/mp4') {
      return FileTypeCategory.audio;
    }
    
    return FileTypeCategory.unknown;
  }
  
  /// Get default MIME type for a category
  static String _getMimeTypeForCategory(FileTypeCategory category) {
    switch (category) {
      case FileTypeCategory.pdf:
        return 'application/pdf';
      case FileTypeCategory.image:
        return 'image/jpeg';
      case FileTypeCategory.text:
        return 'text/plain';
      case FileTypeCategory.document:
        return 'application/octet-stream';
      case FileTypeCategory.archive:
        return 'application/zip';
      case FileTypeCategory.video:
        return 'video/mp4';
      case FileTypeCategory.audio:
        return 'audio/mp4'; // Default to M4A format
      case FileTypeCategory.unknown:
        return 'application/octet-stream';
    }
  }
}

/// Information about detected file type
class FileTypeInfo {
  final FileTypeCategory category;
  final String mimeType;
  
  FileTypeInfo({
    required this.category,
    required this.mimeType,
  });
  
  @override
  String toString() {
    return 'FileTypeInfo(category: $category, mimeType: $mimeType)';
  }
}
