# Safety and Recovery Notes

- Run only from an elevated Windows PowerShell 5.1 session.
- Create a Windows System Restore Point before broad changes.
- The toolkit's JSON baseline is not a full system image.
- Do not disable Windows Defender, Windows Update, RPC, DHCP, DNS, Plug and Play, Task Scheduler, or driver services.
- Do not disable the pagefile on systems with 4 GB RAM.
- The custom pagefile feature is restricted to C: and requires Windows to report the OS disk as SSD. It rejects HDD and unknown media types; users of RAID/Storage controllers must verify the disk type separately.
- Custom pagefile size is fixed (Initial Size = Maximum Size), limited to 1,000-24,000 MB, and requires at least the requested size plus 2,048 MB free on C:. Only configure it after reviewing the current pagefile settings and confirming the change. Restart is required.
- A pagefile extends the commit limit; it does not add physical RAM or match RAM performance. Pagefile sizing depends on peak commit and crash dump requirements; System Managed remains the default recommendation.
- Do not use RAM cleaner utilities or registry cleaners.
- UWP background permission controls do not stop all desktop applications.
- Microsoft Edge removal is an advanced, optional operation and is not a guaranteed RAM optimization. Menu 19 invokes the bundled Edge uninstaller, then removes only residual version folders under known Edge Application paths when no `msedge.exe` remains. It writes an audit report covering standard install paths, uninstall registrations, running browser processes, and legacy Edge Appx presence. It does not scan every disk or guarantee that Windows Update/organization policy will not reinstall Edge. Keep WebView2 Runtime, Edge Update, user profile data, shortcuts/protocol registrations, and protected Windows components. The operation is not covered by toolkit restore.
- Do not force-remove protected Windows Appx packages. Packages marked `NonRemovable=True`, such as `Microsoft.XboxGameCallableUI` on systems where it is marked protected, are intentionally excluded from the removal catalog.
- The system health report checks a limited list of critical services; an OK result is not a full security audit.
- RAM savings are estimated from immediate before/after physical-memory readings. Background activity and cache changes can affect the result; the percentage of successful actions is not a performance-improvement percentage.
- Remove-AppxPackage logs package identity only; it does not save installers.
- Reboot after service, pagefile, or policy changes and measure again after idle settling.
