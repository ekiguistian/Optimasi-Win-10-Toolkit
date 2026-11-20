# Safety and Recovery Notes

- Run only from an elevated Windows PowerShell 5.1 session.
- Create a Windows System Restore Point before broad changes.
- The toolkit's JSON baseline is not a full system image.
- Do not disable Windows Defender, Windows Update, RPC, DHCP, DNS, Plug and Play, Task Scheduler, or driver services.
- Do not disable the pagefile on systems with 4 GB RAM.
- Do not use RAM cleaner utilities or registry cleaners.
- UWP background permission controls do not stop all desktop applications.
- Microsoft Edge removal is not a recommended RAM optimization and is not covered by toolkit restore.
- Remove-AppxPackage logs package identity only; it does not save installers.
- Reboot after service, pagefile, or policy changes and measure again after idle settling.
