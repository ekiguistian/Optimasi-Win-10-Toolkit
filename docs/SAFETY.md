# Safety and Recovery Notes

- Run only from an elevated Windows PowerShell 5.1 session.
- Create a Windows System Restore Point before broad changes.
- The toolkit's JSON baseline is not a full system image.
- Do not disable Windows Defender, Windows Update, RPC, DHCP, DNS, Plug and Play, Task Scheduler, or driver services.
- Do not disable the pagefile on systems with 4 GB RAM.
- Do not use RAM cleaner utilities or registry cleaners.
- UWP background permission controls do not stop all desktop applications.
- Microsoft Edge removal is an advanced, optional operation. It is not a recommended RAM optimization, is not supported on every Windows build/configuration, and is not covered by toolkit restore. Keep Edge WebView2 installed.
- Do not force-remove protected Windows Appx packages. Packages marked `NonRemovable=True`, such as `Microsoft.XboxGameCallableUI` on systems where it is marked protected, are intentionally excluded from the removal catalog.
- The system health report checks a limited list of critical services; an OK result is not a full security audit.
- RAM savings are estimated from immediate before/after physical-memory readings. Background activity and cache changes can affect the result; the percentage of successful actions is not a performance-improvement percentage.
- Remove-AppxPackage logs package identity only; it does not save installers.
- Reboot after service, pagefile, or policy changes and measure again after idle settling.
