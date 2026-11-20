# Changelog

## Unreleased

- Initial public project structure.
- Added Indonesian README, MIT license, safety notes, contribution guide, and issue template.
- Added Windows PowerShell parse validation and PSScriptAnalyzer CI workflow.
- Packaged the interactive toolkit recovered from the latest intact project artifact.
- Fixed menu exit handling so option 0 exits the loop.
- Added a system health report for selected core services, Defender status when available, and top RAM-consuming process groups.
- Added optimization action success percentage and immediate before/after RAM usage estimate.
- Excluded protected/non-removable Appx packages such as XboxGameCallableUI from the uninstall catalog.
- Added an explicit-confirmation advanced Edge uninstaller that preserves WebView2 and documents restore limitations.
- Added custom fixed-size pagefile configuration restricted to SSD-backed C:, with 1,000-24,000 MB validation, free-space check, baseline capture, confirmation, and rollback attempt.
- Improved SSD detection using Get-Disk, Get-PhysicalDisk, and Win32_DiskDrive model information. Explicit HDD evidence is rejected; Unspecified media can proceed only after an explicit user physical SSD confirmation.
