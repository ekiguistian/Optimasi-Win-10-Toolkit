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
- Improved menu 19 Edge cleanup: inspect Edge Update services and scheduled tasks, stop/disable updater services, disable Edge Update tasks, run the Edge uninstaller, and verify remaining browser/updater components. WebView2 and shared updater files are preserved; WebView2 update impact is documented.
- Added custom fixed-size pagefile configuration restricted to SSD-backed C:, with 1,000-24,000 MB validation, free-space check, baseline capture, confirmation, and rollback attempt.
- Improved SSD detection using Get-Disk, Get-PhysicalDisk, and Win32_DiskDrive model information. Explicit HDD evidence is rejected; Unspecified media can proceed only after an explicit user physical SSD confirmation.
- Added a read-only svchost.exe RAM diagnostic under Tools Tambahan, including per-PID Working Set, mapped Windows services, executable path, and command line.
- Shortened the main menu labels and added a force-restart option with an explicit confirmation and unsaved-data warning.
- Added menu 23 to temporarily disable Windows automatic updates through policy and Windows Update/Update Orchestrator service settings, with a saved configuration snapshot and restore option.
