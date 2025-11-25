# Changelog

All notable changes to EverQuest Log Recycler will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-11-25

### Fixed
- Fixed `Add_Click` event handler in time cycle dialog that was causing a "Cannot find an overload for 'Add_Click' and the argument count: '2'" error when changing the recycle time

## [1.0] - Initial Release

### Added
- Automatic log rotation at user-specified daily time
- Multi-character support for monitoring multiple log files
- Archive management with timestamped backups
- System tray application with custom parchment scroll icon
- Easy GUI configuration
- Persistent settings stored in Windows Registry
- Three operating modes: system tray, silent, and command-line
- Smart validation for folder permissions and file accessibility
- Error recovery and graceful edge case handling
