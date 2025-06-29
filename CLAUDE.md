# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS AppleScript application that converts PNG images to PDF format using ImageMagick. The application provides a GUI dialog interface for batch converting PNG files from a designated screenshot folder into PDFs with configurable quality and page size settings. **The current version includes advanced 200MB auto-split functionality for efficient file management.**

## Core Architecture

### Main Application (Version 2.0)
- **`versions/v2.0_split_feature/main.scpt`** - Current production version with 200MB split feature
- **`versions/v2.0_split_feature/main.applescript`** - Source code for split feature version
- Written in AppleScript with Japanese comments and dialog text
- Requires ImageMagick for image processing operations
- **New**: Advanced file size monitoring and automatic splitting algorithm

### Configuration (Hardcoded in main.scpt)
- **Source Folder**: `/Users/gantaku/本/_screenshot/` - Location of PNG files to convert
- **Save Folder**: `/Users/gantaku/本/` - PDF output destination
- **Image Quality**: 85% (1-100 scale)
- **Page Size**: A4 (supports A4, Letter, Legal)
- **Fit to Page**: Enabled - scales images to fit page dimensions
- **Max File Size**: 200MB - Auto-split threshold (configurable)

### Key Components
1. **ImageMagick Detection** - Searches for convert binary in:
   - `/opt/homebrew/bin/convert` (Apple Silicon Homebrew)
   - `/usr/local/bin/convert` (Intel Homebrew)
   - System PATH via `which convert`

2. **Advanced File Processing** - Enhanced batch processing with intelligent splitting:
   - Scans for PNG files, sorts them naturally
   - **Batch Processing**: Processes 10 files at a time initially
   - **Size Monitoring**: Automatically checks PDF file size after creation
   - **Dynamic Split**: Reduces batch size when 200MB threshold is exceeded
   - **Recursive Processing**: Continues until optimal file sizes achieved

3. **User Interface** - Enhanced macOS native dialogs:
   - Filename input with automatic extension handling
   - Progress display for large batches
   - Comprehensive result reporting with file size information
   - Split file naming with part numbers

4. **Error Handling** - Comprehensive error handling with cleanup:
   - User-friendly error messages
   - Automatic temporary file cleanup
   - Memory-efficient processing

5. **File Management** - Enhanced file operations:
   - Optional cleanup (move processed PNGs to trash)
   - Automatic split file naming (`filename_part1.pdf`, `filename_part2.pdf`, etc.)

### New Functions (v2.0)
- **`splitConvertProcess()`** - Main batch processing with size monitoring
- **`getFileSizeMB()`** - File size calculation in MB
- **`createSmallerBatches()`** - Recursive splitting algorithm

## Development Commands

### Running the Application
```bash
# Execute the current version (v2.0 with split feature)
osascript versions/v2.0_split_feature/main.scpt

# Execute basic version (v1.0)
osascript versions/v1.0_basic/main.scpt

# Decompile for editing (if needed)
osadecompile versions/v2.0_split_feature/main.scpt
```

### Prerequisites
- macOS with AppleScript support
- ImageMagick installed via Homebrew:
  ```bash
  brew install imagemagick
  ```

## Dependencies
- **ImageMagick** - Required for PNG to PDF conversion
- **macOS Finder** - Used for file operations (moving files to trash)
- **macOS System Dialogs** - For user interaction

## File Structure
```
PNG_to_PDF/
├── .claude/
│   └── settings.local.json     # Claude Code permissions
├── docs/
│   ├── PNG_to_PDF_仕様書.md    # Detailed technical specifications
│   └── 200MB分割機能_説明書.md  # Split feature documentation
├── versions/
│   ├── v1.0_basic/
│   │   ├── VERSION_INFO.md     # Basic version info
│   │   ├── main.applescript    # Source code (basic)
│   │   └── main.scpt          # Compiled script (basic)
│   └── v2.0_split_feature/
│       ├── VERSION_INFO.md     # Split feature version info
│       ├── main.applescript    # Source code (with split feature)
│       └── main.scpt          # Compiled script (with split feature) - CURRENT VERSION
├── temp/                       # Temporary files directory
├── README.md                   # Project overview
└── CLAUDE.md                  # This file
```

## Application Workflow (v2.0)
1. User launches script and enters desired PDF filename
2. System checks for ImageMagick installation
3. Application scans source folder for PNG files
4. Displays conversion summary with split feature information
5. **Enhanced Processing**:
   - Processes files in batches of 10 (initially)
   - Creates PDF and checks file size
   - If > 200MB: deletes file, reduces batch size, and retries
   - Continues until all files processed with optimal sizes
6. **Progress Display**: Shows processing status for large operations
7. Optionally moves source PNG files to trash
8. **Enhanced Results**: Shows detailed information about all created files with sizes

## New Features (v2.0)
- **200MB Auto-Split**: Automatically splits large PDFs into manageable files
- **Intelligent Batching**: Dynamic batch size adjustment (10→5→2→1 files)
- **Progress Monitoring**: Real-time progress display for large conversions
- **Enhanced File Naming**: Automatic part numbering for split files
- **Memory Optimization**: Reduced memory usage through smaller batches
- **Error Recovery**: Improved error handling with automatic cleanup

## Limitations and Considerations
- **macOS Only** - AppleScript is platform-specific
- **Hardcoded Paths** - Source and destination folders are fixed in code
- **No Build System** - Single-file application with no compilation needed
- **No Testing Framework** - Manual testing only
- **Japanese UI** - Dialog text and comments are in Japanese
- **Single File Limit** - Cannot split if a single PNG creates >200MB PDF
- **Disk Space** - Split processing requires additional temporary disk space

## Version History
- **v1.0 (Basic)**: ~21KB - Basic PNG to PDF conversion
- **v2.0 (Split Feature)**: ~35KB - Added 200MB auto-split functionality