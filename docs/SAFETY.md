# Safety and Recovery Notes

- Run only from an elevated Windows PowerShell 5.1 session.
- Create a Windows System Restore Point before broad changes.
- The toolkit's JSON baseline is not a full system image.
- Do not disable Windows Defender, Windows Update, RPC, DHCP, DNS, Plug and Play, Task Scheduler, or driver services.
- Do not disable the pagefile on systems with 4 GB RAM.
- The custom pagefile feature is restricted to C:. It checks Get-Disk.MediaType, Get-PhysicalDisk.MediaType, and Win32_DiskDrive model information. Any explicit HDD indication is rejected. If Windows reports Unspecified/unavailable (common with some SATA/AHCI drivers), the user must inspect the displayed model and physically confirm SSD by typing `CONFIRM SSD`; SATA bus type alone is not proof of SSD. This manual confirmation is the user's responsibility.
- Custom pagefile size is fixed (Initial Size = Maximum Size), limited to 1,000-24,000 MB, and requires at least the requested size plus 2,048 MB free on C:. Only configure it after reviewing the current pagefile settings and confirming the change. Restart is required.
- A pagefile extends the commit limit; it does not add physical RAM or match RAM performance. Pagefile sizing depends on peak commit and crash dump requirements; System Managed remains the default recommendation.
- Do not use RAM cleaner utilities or registry cleaners.
- UWP background permission controls do not stop all desktop applications.
- Microsoft Edge removal is an advanced, optional operation. It is not a recommended RAM optimization, is not supported on every Windows build/configuration, and is not covered by toolkit restore. Keep Edge WebView2 installed.
- Do not force-remove protected Windows Appx packages. Packages marked `NonRemovable=True`, such as `Microsoft.XboxGameCallableUI` on systems where it is marked protected, are intentionally excluded from the removal catalog.
- The system health report checks a limited list of critical services; an OK result is not a full security audit.
- RAM savings are estimated from immediate before/after physical-memory readings. Background activity and cache changes can affect the result; the percentage of successful actions is not a performance-improvement percentage.
- Remove-AppxPackage logs package identity only; it does not save installers.
- Reboot after service, pagefile, or policy changes and measure again after idle settling.
