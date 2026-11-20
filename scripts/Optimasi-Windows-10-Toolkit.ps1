#requires -Version 5.1
# Optimasi Windows 10 Toolkit
# Target: Windows 10 22H2 x64; hardware-independent baseline toolkit.
# Run from Windows PowerShell 5.1 as Administrator.

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$Root = Join-Path $env:ProgramData "Optimasi-Windows-10-Toolkit"
$BackupFile = Join-Path $Root "baseline.json"
$LogFile = Join-Path $Root "toolkit.log"

$OptionalServices = @(
    [pscustomobject]@{ Name="SysMain";            Description="SysMain / Superfetch. Test only if disk activity or memory pressure is high." },
    [pscustomobject]@{ Name="XblAuthManager";     Description="Xbox Live Auth Manager. Disable if Xbox features are not used." },
    [pscustomobject]@{ Name="XblGameSave";        Description="Xbox Live Game Save. Disable if Xbox features are not used." },
    [pscustomobject]@{ Name="XboxNetApiSvc";      Description="Xbox Live Networking. Disable if Xbox features are not used." },
    [pscustomobject]@{ Name="XboxGipSvc";          Description="Xbox Accessory Management. Disable if Xbox accessories are not used." },
    [pscustomobject]@{ Name="MapsBroker";          Description="Downloaded Maps Manager. Disable if offline maps are not used." },
    [pscustomobject]@{ Name="Fax";                Description="Fax service. Disable if fax hardware/software is not used." },
    [pscustomobject]@{ Name="RetailDemo";         Description="Retail Demo service. Not needed on a normal personal laptop." },
    [pscustomobject]@{ Name="WMPNetworkSvc";      Description="Windows Media Player Network Sharing. Disable if media sharing is not used." }
)

$ManagedRegistryValues = @(
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name="GlobalUserDisabled"; Value=1; Kind="DWord"; Label="Disable UWP background apps" },
    @{ Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Value=0; Kind="DWord"; Label="Disable Game DVR for current user" },
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name="AllowGameDVR"; Value=0; Kind="DWord"; Label="Disable Game DVR policy" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name="VisualFXSetting"; Value=2; Kind="DWord"; Label="Prefer visual performance" }
)

function Write-Log {
    param([string]$Message)
    if (-not (Test-Path $Root)) { New-Item -Path $Root -ItemType Directory -Force | Out-Null }
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Pause-Menu {
    Write-Host ""
    [void](Read-Host "Tekan Enter untuk kembali ke menu")
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-RegistrySnapshot {
    param([string]$Path, [string]$Name)
    $keyExists = Test-Path -LiteralPath $Path
    $valueExists = $false
    $value = $null
    $kind = $null

    if ($keyExists) {
        try {
            $key = Get-Item -LiteralPath $Path
            if ($key.GetValueNames() -contains $Name) {
                $valueExists = $true
                $value = $key.GetValue($Name)
                $kind = $key.GetValueKind($Name).ToString()
            }
        } catch {}
    }

    [pscustomobject]@{
        Path=$Path; Name=$Name; KeyExists=$keyExists
        ValueExists=$valueExists; Value=$value; Kind=$kind
    }
}

function Set-RegistryValue {
    [CmdletBinding()]
    param([string]$Path, [string]$Name, $Value, [string]$Kind)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}

function Restore-RegistrySnapshot {
    param($Item)
    if ($Item.ValueExists) {
        if (-not (Test-Path -LiteralPath $Item.Path)) {
            New-Item -Path $Item.Path -Force | Out-Null
        }
        New-ItemProperty -LiteralPath $Item.Path -Name $Item.Name -Value $Item.Value -PropertyType $Item.Kind -Force | Out-Null
    } elseif (Test-Path -LiteralPath $Item.Path) {
        Remove-ItemProperty -LiteralPath $Item.Path -Name $Item.Name -ErrorAction SilentlyContinue
        if (-not $Item.KeyExists) {
            # Do not remove a key if it now contains other values.
            $key = Get-Item -LiteralPath $Item.Path -ErrorAction SilentlyContinue
            if ($key -and $key.GetValueNames().Count -eq 0 -and $key.SubKeyCount -eq 0) {
                Remove-Item -LiteralPath $Item.Path -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Get-ServiceSnapshot {
    param([string]$Name)
    $svc = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
    if (-not $svc) { return $null }
    [pscustomobject]@{
        Name=$Name
        StartMode=$svc.StartMode
        State=$svc.State
    }
}

function New-Baseline {
    if (Test-Path $BackupFile) {
        Write-Host "Baseline sudah ada: $BackupFile" -ForegroundColor Yellow
        Write-Host "Restore baseline lama terlebih dahulu jika ingin membuat baseline baru."
        return
    }

    New-Item -Path $Root -ItemType Directory -Force | Out-Null

    $serviceSnapshots = @()
    foreach ($entry in $OptionalServices) {
        $snap = Get-ServiceSnapshot -Name $entry.Name
        if ($null -ne $snap) { $serviceSnapshots += $snap }
    }

    $registrySnapshots = @()
    foreach ($entry in $ManagedRegistryValues) {
        $registrySnapshots += (Get-RegistrySnapshot -Path $entry.Path -Name $entry.Name)
    }

    $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $pagefileSnapshots = @()
    $pagefileSettingsCaptured = [bool]$computer.AutomaticManagedPagefile
    if (-not $computer.AutomaticManagedPagefile) {
        try {
            $pagefileSnapshots = @(
                Get-CimInstance Win32_PageFileSetting -ErrorAction Stop |
                    Select-Object Name, InitialSize, MaximumSize
            )
            $pagefileSettingsCaptured = $true
        } catch {
            $pagefileSettingsCaptured = $false
            Write-Host "Konfigurasi pagefile manual tidak dapat dibaca; restore pagefile manual tidak akan dilakukan dari baseline ini." -ForegroundColor Yellow
        }
    }

    $baseline = [pscustomobject]@{
        Created=(Get-Date).ToString("o")
        ComputerName=$env:COMPUTERNAME
        AutomaticManagedPagefile=[bool]$computer.AutomaticManagedPagefile
        PagefileSettingsCaptured=$pagefileSettingsCaptured
        PagefileSettings=$pagefileSnapshots
        Services=$serviceSnapshots
        Registry=$registrySnapshots
    }

    $baseline | ConvertTo-Json -Depth 8 | Set-Content -Path $BackupFile -Encoding UTF8
    Write-Log "Baseline created."
    Write-Host "Baseline berhasil dibuat: $BackupFile" -ForegroundColor Green
}

function Ensure-Baseline {
    if (-not (Test-Path $BackupFile)) { New-Baseline }
    if (-not (Test-Path $BackupFile)) {
        throw "Baseline gagal dibuat. Perubahan dibatalkan."
    }
}

function Get-RamReport {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used = [math]::Round($total - $free, 2)

    Write-Host "`n========== STATUS RAM ==========" -ForegroundColor Cyan
    [pscustomobject]@{
        "Installed RAM (GB)" = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        "Visible RAM (GB)" = $total
        "Used RAM estimate (GB)" = $used
        "Available RAM (GB)" = $free
        "Memory load (%)" = [math]::Round(($used / $total) * 100, 1)
    } | Format-List

    try {
        $mm = Get-MMAgent -ErrorAction Stop
        Write-Host "Memory Compression: $($mm.MemoryCompression)"
    } catch {
        Write-Host "Memory Compression: status tidak dapat dibaca pada sistem ini."
    }
}


function Get-RamSnapshot {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 1)
    $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 1)
    $usedMB = [math]::Max(0, [math]::Round($totalMB - $freeMB, 1))
    [pscustomobject]@{
        TotalMB=$totalMB
        AvailableMB=$freeMB
        UsedMB=$usedMB
        LoadPercent=$(if ($totalMB -gt 0) { [math]::Round(($usedMB / $totalMB) * 100, 1) } else { 0 })
        CapturedAt=(Get-Date).ToString("o")
    }
}

function Get-TopMemoryUsage {
    $groups = Get-Process -ErrorAction SilentlyContinue |
        Group-Object ProcessName |
        ForEach-Object {
            $totalBytes = ($_.Group | Measure-Object -Property WorkingSet64 -Sum).Sum
            [pscustomobject]@{ Process=$_.Name; Instances=$_.Count; RAM_MB=[math]::Round($totalBytes / 1MB, 1) }
        } |
        Sort-Object RAM_MB -Descending |
        Select-Object -First 10

    foreach ($item in $groups) {
        $level = if ($item.RAM_MB -ge 500) { "TINGGI" } elseif ($item.RAM_MB -ge 250) { "PERIKSA" } else { "Normal" }
        [pscustomobject]@{ Process=$item.Process; Instances=$item.Instances; RAM_MB=$item.RAM_MB; Assessment=$level }
    }
}

function Get-CoreServiceHealth {
    $critical = @(
        @{ Name="RpcSs"; Label="Remote Procedure Call" },
        @{ Name="DcomLaunch"; Label="DCOM Server Process Launcher" },
        @{ Name="PlugPlay"; Label="Plug and Play" },
        @{ Name="EventLog"; Label="Windows Event Log" },
        @{ Name="Winmgmt"; Label="Windows Management Instrumentation" },
        @{ Name="Schedule"; Label="Task Scheduler" },
        @{ Name="BFE"; Label="Base Filtering Engine" },
        @{ Name="MpsSvc"; Label="Windows Defender Firewall" },
        @{ Name="CryptSvc"; Label="Cryptographic Services" }
    )
    foreach ($item in $critical) {
        $svc = Get-CimInstance Win32_Service -Filter "Name='$($item.Name)'" -ErrorAction SilentlyContinue
        if (-not $svc) {
            [pscustomobject]@{ Name=$item.Name; Service=$item.Label; State="Not found"; Startup="Unknown"; Assessment="PERIKSA" }
        } elseif ($svc.StartMode -eq "Disabled") {
            [pscustomobject]@{ Name=$item.Name; Service=$item.Label; State=$svc.State; Startup=$svc.StartMode; Assessment="RISIKO" }
        } elseif ($svc.State -ne "Running") {
            [pscustomobject]@{ Name=$item.Name; Service=$item.Label; State=$svc.State; Startup=$svc.StartMode; Assessment="PERIKSA" }
        } else {
            [pscustomobject]@{ Name=$item.Name; Service=$item.Label; State=$svc.State; Startup=$svc.StartMode; Assessment="OK" }
        }
    }
}

function Show-SystemHealthReport {
    $ram = Get-RamSnapshot
    $services = @(Get-CoreServiceHealth)
    $problems = @($services | Where-Object { $_.Assessment -ne "OK" })
    $overall = if ($problems.Count -eq 0) { "OK - service inti yang diperiksa berjalan" } elseif (@($problems | Where-Object { $_.Assessment -eq "RISIKO" }).Count -gt 0) { "RISIKO - ada service inti Disabled" } else { "PERLU PERHATIAN - ada service inti tidak berjalan / tidak terdeteksi" }

    Write-Host "========== RINGKASAN STATUS SISTEM ==========" -ForegroundColor Cyan
    [pscustomobject]@{
        "RAM terpakai (perkiraan)" = "$($ram.UsedMB) MB / $($ram.TotalMB) MB"
        "RAM tersedia" = "$($ram.AvailableMB) MB"
        "Beban RAM" = "$($ram.LoadPercent)%"
        "Status service inti" = $overall
    } | Format-List
    Write-Host "Pemeriksaan service inti:" -ForegroundColor Cyan
    $services | Format-Table Name, State, Startup, Assessment -AutoSize
    Write-Host "10 kelompok proses dengan konsumsi RAM tertinggi:" -ForegroundColor Cyan
    @(Get-TopMemoryUsage) | Format-Table Process, Instances, RAM_MB, Assessment -AutoSize
    Write-Host "Ambang indikatif: >=250 MB PERIKSA; >=500 MB TINGGI. Ini bukan bukti malware atau kerusakan; browser, game, IDE, dan aplikasi kerja dapat wajar memakai RAM besar." -ForegroundColor DarkYellow
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        Write-Host ("Microsoft Defender: AntivirusEnabled={0}; RealTimeProtectionEnabled={1}" -f $mp.AntivirusEnabled, $mp.RealTimeProtectionEnabled)
    } catch {
        Write-Host "Status Microsoft Defender tidak dapat dibaca. Periksa Windows Security / antivirus pihak ketiga secara manual." -ForegroundColor Yellow
    }
}

function Show-OptimizationComparison {
    param($Before, [int]$Attempted, [int]$Succeeded)
    $after = Get-RamSnapshot
    $delta = [math]::Round($Before.UsedMB - $after.UsedMB, 1)
    $rate = if ($Attempted -gt 0) { [math]::Round(($Succeeded / $Attempted) * 100, 1) } else { 0 }
    $ramResult = if ($delta -gt 0) { "Turun sekitar $delta MB" } elseif ($delta -lt 0) { "Naik sekitar $([math]::Abs($delta)) MB" } else { "Tidak berubah secara terukur" }
    Write-Host "========== HASIL OPTIMASI ==========" -ForegroundColor Cyan
    [pscustomobject]@{
        "Tindakan berhasil" = "$Succeeded / $Attempted"
        "Persentase tindakan sukses" = "$rate%"
        "RAM terpakai sebelum" = "$($Before.UsedMB) MB"
        "RAM terpakai sesudah" = "$($after.UsedMB) MB"
        "Perubahan RAM terukur" = $ramResult
        "Beban RAM sebelum" = "$($Before.LoadPercent)%"
        "Beban RAM sesudah" = "$($after.LoadPercent)%"
    } | Format-List
    $record = [pscustomobject]@{
        Timestamp=(Get-Date).ToString("o"); Attempted=$Attempted; Succeeded=$Succeeded
        SuccessPercent=$rate; Before=$Before; After=$after
        EstimatedUsedRamChangeMB=$delta
        Note="Pengukuran langsung dapat dipengaruhi proses latar belakang; bukan pengukuran RAM yang pasti dibebaskan oleh optimasi."
    }
    $record | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $Root "latest-optimization-report.json") -Encoding UTF8
    Write-Host "Catatan: perubahan RAM adalah estimasi sesaat. Untuk hasil lebih adil, restart, tunggu 3-5 menit, lalu jalankan laporan status lagi." -ForegroundColor Yellow
    Write-Log "Optimization result: $Succeeded/$Attempted actions; estimated used RAM delta $delta MB."
}

function Show-RunningServices {
    Write-Host "`n========== SERVICE YANG SEDANG RUNNING ==========" -ForegroundColor Cyan
    Get-CimInstance Win32_Service -Filter "State='Running'" |
        Sort-Object DisplayName |
        Select-Object Name, DisplayName, StartMode, State |
        Format-Table -AutoSize
}

function Show-OptionalServices {
    Write-Host "`n========== SERVICE OPSIONAL ==========" -ForegroundColor Cyan
    $i = 1
    $rows = foreach ($entry in $OptionalServices) {
        $svc = Get-Service -Name $entry.Name -ErrorAction SilentlyContinue
        if ($svc) {
            $cim = Get-CimInstance Win32_Service -Filter "Name='$($entry.Name)'"
            [pscustomobject]@{
                No=$i; Name=$entry.Name; Status=$svc.Status
                Startup=$cim.StartMode; Description=$entry.Description
            }
            $i++
        }
    }
    $rows | Format-Table -Wrap -AutoSize
}

function Disable-SelectedServices {
    Show-OptionalServices
    Write-Host "Masukkan nomor service yang ingin dinonaktifkan, pisahkan koma."
    Write-Host "Contoh: 1,2,3. Hanya pilih service yang fiturnya memang tidak digunakan."
    $inputNumbers = Read-Host "Pilihan"
    if ([string]::IsNullOrWhiteSpace($inputNumbers)) { return }

    $available = @()
    foreach ($entry in $OptionalServices) {
        if (Get-Service -Name $entry.Name -ErrorAction SilentlyContinue) { $available += $entry }
    }

    $selected = @()
    foreach ($part in ($inputNumbers -split ",")) {
        $number = 0
        if ([int]::TryParse($part.Trim(), [ref]$number) -and $number -ge 1 -and $number -le $available.Count) {
            $selected += $available[$number - 1]
        }
    }
    if ($selected.Count -eq 0) { Write-Host "Tidak ada pilihan valid."; return }

    Ensure-Baseline
    foreach ($entry in $selected) {
        try {
            $svc = Get-Service -Name $entry.Name -ErrorAction Stop
            Set-Service -Name $entry.Name -StartupType Disabled
            if ($svc.Status -eq "Running") {
                Stop-Service -Name $entry.Name -Force -ErrorAction Stop
            }
            Write-Host "Disabled: $($entry.Name)" -ForegroundColor Green
            Write-Log "Service disabled: $($entry.Name)"
        } catch {
            Write-Host "Gagal mengubah $($entry.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Set-SelectedServicesManual {
    Show-OptionalServices
    Write-Host "Masukkan nomor service yang ingin diubah ke Manual, pisahkan koma."
    $inputNumbers = Read-Host "Pilihan"
    if ([string]::IsNullOrWhiteSpace($inputNumbers)) { return }

    $available = @()
    foreach ($entry in $OptionalServices) {
        if (Get-Service -Name $entry.Name -ErrorAction SilentlyContinue) { $available += $entry }
    }

    $selectedNames = @()
    foreach ($part in ($inputNumbers -split ",")) {
        $number = 0
        if ([int]::TryParse($part.Trim(), [ref]$number) -and $number -ge 1 -and $number -le $available.Count) {
            $selectedNames += $available[$number - 1].Name
        }
    }
    $selectedNames = @($selectedNames | Sort-Object -Unique)
    if ($selectedNames.Count -eq 0) {
        Write-Host "Tidak ada nomor service valid. Tidak ada perubahan dilakukan." -ForegroundColor Yellow
        return
    }

    Ensure-Baseline
    foreach ($name in $selectedNames) {
        try {
            Set-Service -Name $name -StartupType Manual -ErrorAction Stop
            Write-Host "Manual: $name" -ForegroundColor Green
            Write-Log "Service set Manual: $name"
        } catch {
            Write-Host "Gagal mengubah $name : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Show-BackgroundApps {
    Write-Host "`n========== APLIKASI UWP / BACKGROUND ==========" -ForegroundColor Cyan
    $base = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    $global = Get-ItemProperty -Path $base -Name GlobalUserDisabled -ErrorAction SilentlyContinue
    if ($null -ne $global) {
        if ($global.GlobalUserDisabled -eq 1) {
            Write-Host "Kebijakan global: aplikasi background dibatasi." -ForegroundColor Green
        } else {
            Write-Host "Kebijakan global: aplikasi background diizinkan."
        }
    } else {
        Write-Host "Kebijakan global: default Windows."
    }

    $packages = Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object { $_.PackageFamilyName } |
        Sort-Object Name

    $rows = foreach ($pkg in $packages) {
        $path = Join-Path $base $pkg.PackageFamilyName
        $settings = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $disabled = if ($null -ne $settings -and $null -ne $settings.Disabled) { $settings.Disabled } else { "Default/Unknown" }
        [pscustomobject]@{
            App=$pkg.Name
            BackgroundDisabled=$disabled
            Package=$pkg.PackageFamilyName
        }
    }
    $rows | Format-Table App, BackgroundDisabled -AutoSize
    Write-Host "Catatan: Windows tidak menyediakan satu daftar PowerShell yang selalu akurat untuk status izin background semua aplikasi."
}

function Disable-BackgroundApps {
    Ensure-Baseline
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    try {
        Set-RegistryValue -Path $path -Name "GlobalUserDisabled" -Value 1 -Kind "DWord"
        Write-Host "Pembatasan background apps diterapkan untuk akun Windows saat ini." -ForegroundColor Green
        Write-Log "Global UWP background apps disabled."
        Write-Host "Sign out atau restart bila perubahan belum terlihat."
    } catch {
        Write-Host "Gagal: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-StartupApps {
    Write-Host "`n========== STARTUP APPS ==========" -ForegroundColor Cyan
    Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Command, Location, User |
        Format-Table -Wrap -AutoSize
    Write-Host "Nonaktifkan aplikasi pihak ketiga melalui Task Manager > Startup. Jangan mematikan driver AMD/audio/touchpad/security."
}

function Show-TopMemoryProcesses {
    Write-Host "10 KELOMPOK PROSES PEMAKAI RAM TERBESAR" -ForegroundColor Cyan
    Get-TopMemoryUsage | Format-Table Process, Instances, RAM_MB, Assessment -AutoSize
    Write-Host "Ambang indikatif: >=250 MB PERIKSA; >=500 MB TINGGI. Working Set adalah estimasi dan shared memory dapat dihitung berulang." -ForegroundColor Yellow
}

function Apply-SafeOptimizations {
    Ensure-Baseline
    $before = Get-RamSnapshot
    $attempted = 0
    $succeeded = 0

    foreach ($entry in $ManagedRegistryValues) {
        $attempted++
        try {
            Set-RegistryValue -Path $entry.Path -Name $entry.Name -Value $entry.Value -Kind $entry.Kind -ErrorAction Stop
            $succeeded++
            Write-Host "Applied: $($entry.Label)" -ForegroundColor Green
            Write-Log "Registry changed: $($entry.Path)\$($entry.Name)"
        } catch {
            Write-Host "Gagal: $($entry.Label) - $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Log "Registry change failed: $($entry.Path)\$($entry.Name) - $($_.Exception.Message)"
        }
    }

    $attempted++
    try {
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if (-not $computer.AutomaticManagedPagefile) {
            Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$true } -ErrorAction Stop | Out-Null
        }
        $verify = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if ($verify.AutomaticManagedPagefile) {
            $succeeded++
            Write-Host "Pagefile: System managed" -ForegroundColor Green
            Write-Log "Pagefile system-managed verified."
        } else {
            throw "Verifikasi System Managed Pagefile gagal."
        }
    } catch {
        Write-Host "Gagal mengatur pagefile: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Log "Pagefile change failed: $($_.Exception.Message)"
    }

    Show-OptimizationComparison -Before $before -Attempted $attempted -Succeeded $succeeded
    Write-Host "Sebagian pengaturan memerlukan sign out atau restart. Persentase sukses menghitung tindakan konfigurasi, bukan persentase peningkatan performa." -ForegroundColor Yellow
}

function Set-CustomPagefileOnC {
    Write-Host ""
    Write-Host "========== CUSTOM VIRTUAL MEMORY / PAGEFILE ==========" -ForegroundColor Cyan
    Write-Host "Pagefile hanya akan dibuat pada C:\pagefile.sys dan hanya jika disk C terdeteksi sebagai SSD." -ForegroundColor Yellow
    Write-Host "Pagefile bukan RAM fisik. Jika sering digunakan, performanya tetap jauh lebih lambat daripada RAM." -ForegroundColor Yellow
    Write-Host "Jangan gunakan fitur ini pada HDD. Jika jenis disk tidak dapat dipastikan, proses akan dibatalkan." -ForegroundColor Yellow

    $rawSize = Read-Host "Masukkan ukuran pagefile tetap dalam MB (1000-24000)"
    $sizeMB = 0
    if (-not [int]::TryParse($rawSize, [ref]$sizeMB) -or $sizeMB -lt 1000 -or $sizeMB -gt 24000) {
        Write-Host "Ukuran tidak valid. Masukkan angka 1000 sampai 24000 MB." -ForegroundColor Red
        return
    }

    try {
        $partition = Get-Partition -DriveLetter C -ErrorAction Stop
        $osDisk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop
        $mediaType = [string]$osDisk.MediaType
        if ($mediaType -ne "SSD") {
            Write-Host "DITOLAK: disk C terdeteksi sebagai '$mediaType', bukan SSD yang terkonfirmasi." -ForegroundColor Red
            Write-Host "Tidak ada perubahan dilakukan. Periksa jenis media secara manual jika disk menggunakan RAID/Storage Controller." -ForegroundColor Yellow
            return
        }

        $volume = Get-Volume -DriveLetter C -ErrorAction Stop
        $freeMB = [math]::Floor($volume.SizeRemaining / 1MB)
        $requiredFreeMB = $sizeMB + 2048
        if ($freeMB -lt $requiredFreeMB) {
            Write-Host "DITOLAK: ruang kosong C hanya $freeMB MB. Dibutuhkan minimal $requiredFreeMB MB (pagefile $sizeMB MB + cadangan 2048 MB)." -ForegroundColor Red
            return
        }

        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $oldAutomatic = [bool]$computer.AutomaticManagedPagefile
        $oldSettings = @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop | Select-Object Name, InitialSize, MaximumSize)

        Write-Host "Ringkasan perubahan:" -ForegroundColor Cyan
        [pscustomobject]@{
            "Disk C" = $osDisk.FriendlyName
            "Jenis media" = $mediaType
            "Ruang kosong C" = "$freeMB MB"
            "Ukuran pagefile baru" = "$sizeMB MB (Initial = Maximum)"
            "Lokasi baru" = "C:\pagefile.sys"
            "Pengelolaan otomatis sebelumnya" = $oldAutomatic
            "Pagefile manual sebelumnya" = if ($oldSettings.Count -gt 0) { ($oldSettings | ForEach-Object { "$($_.Name): $($_.InitialSize)/$($_.MaximumSize) MB" }) -join "; " } else { "Tidak ada konfigurasi manual terdeteksi" }
            "Pagefile partisi lain" = "Akan dihapus dari konfigurasi"
        } | Format-List

        Write-Host "PERINGATAN:" -ForegroundColor Yellow
        Write-Host "- Pengaturan ini mengganti konfigurasi pagefile yang ada, termasuk pada partisi selain C."
        Write-Host "- Restart Windows diperlukan agar konfigurasi baru aktif."
        Write-Host "- Baseline toolkit akan dibuat/digunakan untuk membantu pemulihan konfigurasi sebelumnya."
        Write-Host "- SSD dipilih karena akses acak lebih baik daripada HDD; pagefile yang sering aktif tetap dapat menambah aktivitas tulis SSD."
        $confirm = Read-Host "Ketik SET PAGEFILE untuk menerapkan perubahan"
        if ($confirm -cne "SET PAGEFILE") {
            Write-Host "Dibatalkan. Tidak ada perubahan dilakukan."
            return
        }

        Ensure-Baseline
        $changed = $false
        try {
            $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
            Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$false } -ErrorAction Stop | Out-Null
            $changed = $true

            foreach ($setting in @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop)) {
                $deleteResult = Invoke-CimMethod -InputObject $setting -MethodName Delete -ErrorAction Stop
                if ($deleteResult.ReturnValue -ne 0) {
                    throw "Gagal menghapus konfigurasi pagefile '$($setting.Name)'. ReturnValue=$($deleteResult.ReturnValue)"
                }
            }

            $createResult = Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create -Arguments @{
                Name="C:\pagefile.sys"
                InitialSize=[uint32]$sizeMB
                MaximumSize=[uint32]$sizeMB
            } -ErrorAction Stop
            if ($createResult.ReturnValue -ne 0) {
                throw "Gagal membuat pagefile C:. ReturnValue=$($createResult.ReturnValue)"
            }

            $verifyComputer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
            $verifySettings = @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop)
            $cSetting = @($verifySettings | Where-Object { $_.Name -ieq "C:\pagefile.sys" })
            $otherSettings = @($verifySettings | Where-Object { $_.Name -ine "C:\pagefile.sys" })
            if ($verifyComputer.AutomaticManagedPagefile -or $cSetting.Count -ne 1 -or $otherSettings.Count -gt 0 -or $cSetting[0].InitialSize -ne $sizeMB -or $cSetting[0].MaximumSize -ne $sizeMB) {
                throw "Verifikasi konfigurasi pagefile tidak sesuai dengan target C:\pagefile.sys $sizeMB MB."
            }

            Write-Host "Konfigurasi pagefile berhasil disimpan." -ForegroundColor Green
            Write-Host "Lokasi: C:\pagefile.sys"
            Write-Host "Initial Size: $sizeMB MB"
            Write-Host "Maximum Size: $sizeMB MB"
            Write-Host "Restart Windows diperlukan sebelum perubahan aktif." -ForegroundColor Yellow
            Write-Log "Custom pagefile configured on C: SSD only, fixed size $sizeMB MB. Restart required."
        } catch {
            Write-Host "Penerapan gagal: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "Custom pagefile failed: $($_.Exception.Message)"
            if ($changed) {
                try {
                    $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
                    Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$false } -ErrorAction Stop | Out-Null
                    foreach ($current in @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop)) {
                        [void](Invoke-CimMethod -InputObject $current -MethodName Delete -ErrorAction Stop)
                    }
                    if ($oldAutomatic) {
                        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
                        Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$true } -ErrorAction Stop | Out-Null
                    } else {
                        foreach ($old in $oldSettings) {
                            $restoreResult = Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create -Arguments @{
                                Name=[string]$old.Name
                                InitialSize=[uint32]$old.InitialSize
                                MaximumSize=[uint32]$old.MaximumSize
                            } -ErrorAction Stop
                            if ($restoreResult.ReturnValue -ne 0) { throw "Restore pagefile '$($old.Name)' gagal." }
                        }
                    }
                    Write-Host "Konfigurasi pagefile sebelumnya berhasil dipulihkan." -ForegroundColor Green
                } catch {
                    Write-Host "Pemulihan otomatis gagal: $($_.Exception.Message). Gunakan menu 12 Restore baseline." -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "Pemeriksaan SSD/drive C gagal: $($_.Exception.Message). Tidak ada perubahan dilakukan." -ForegroundColor Red
        Write-Log "Custom pagefile pre-check failed: $($_.Exception.Message)"
    }
}

function Set-SystemManagedPagefile {
    Ensure-Baseline
    try {
        $computer = Get-CimInstance Win32_ComputerSystem
        Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$true } | Out-Null
        Write-Host "Pagefile sekarang menggunakan System Managed. Restart diperlukan." -ForegroundColor Green
        Write-Log "Pagefile set to system managed."
    } catch {
        Write-Host "Gagal: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restore-Baseline {
    if (-not (Test-Path $BackupFile)) {
        Write-Host "Baseline tidak ditemukan: $BackupFile" -ForegroundColor Yellow
        return
    }

    $confirm = Read-Host "Kembalikan registry, service, dan pagefile ke kondisi sebelum optimasi? (Y/N)"
    if ($confirm -notmatch '^(Y|YES)$') { return }

    try {
        $baseline = Get-Content -Path $BackupFile -Raw | ConvertFrom-Json

        foreach ($item in $baseline.Registry) {
            try { Restore-RegistrySnapshot -Item $item } catch {
                Write-Host "Registry restore gagal: $($item.Path)\$($item.Name)" -ForegroundColor Yellow
            }
        }

        foreach ($item in $baseline.Services) {
            try {
                $svc = Get-Service -Name $item.Name -ErrorAction SilentlyContinue
                if (-not $svc) { continue }

                $startup = switch ($item.StartMode) {
                    "Auto" { "Automatic" }
                    "Manual" { "Manual" }
                    "Disabled" { "Disabled" }
                    default { $null }
                }

                if ($startup) { Set-Service -Name $item.Name -StartupType $startup }

                if ($item.State -eq "Running") {
                    Start-Service -Name $item.Name -ErrorAction SilentlyContinue
                } elseif ($item.State -eq "Stopped") {
                    Stop-Service -Name $item.Name -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "Service restore gagal: $($item.Name)" -ForegroundColor Yellow
            }
        }

        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if ([bool]$baseline.AutomaticManagedPagefile) {
            Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$true } -ErrorAction Stop | Out-Null
        } else {
            Set-CimInstance -InputObject $computer -Property @{ AutomaticManagedPagefile=$false } -ErrorAction Stop | Out-Null
            if (($baseline.PSObject.Properties.Name -contains "PagefileSettingsCaptured") -and [bool]$baseline.PagefileSettingsCaptured) {
                foreach ($currentSetting in @(Get-CimInstance Win32_PageFileSetting -ErrorAction Stop)) {
                    Invoke-CimMethod -InputObject $currentSetting -MethodName Delete -ErrorAction Stop | Out-Null
                }
                foreach ($setting in @($baseline.PagefileSettings)) {
                    if ($null -eq $setting) { continue }
                    $createResult = Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create -Arguments @{
                        Name=[string]$setting.Name
                        InitialSize=[uint32]$setting.InitialSize
                        MaximumSize=[uint32]$setting.MaximumSize
                    } -ErrorAction Stop
                    if ($createResult.ReturnValue -ne 0) {
                        throw "Gagal memulihkan pagefile '$($setting.Name)'. ReturnValue=$($createResult.ReturnValue)"
                    }
                }
            } else {
                Write-Host "Baseline tidak memiliki snapshot pagefile manual yang valid; pengaturan manual saat ini tidak diubah." -ForegroundColor Yellow
            }
        }

        $archive = Join-Path $Root ("baseline-restored-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")
        Move-Item -Path $BackupFile -Destination $archive -Force

        Write-Host "Baseline berhasil dipulihkan. Arsip: $archive" -ForegroundColor Green
        Write-Host "Restart Windows diperlukan."
        Write-Log "Baseline restored and archived."
    } catch {
        Write-Host "Restore gagal: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Export-SystemReport {
    New-Item -Path $Root -ItemType Directory -Force | Out-Null
    $report = Join-Path $Root ("system-report-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")
    $ram = Get-RamSnapshot
    $services = @(Get-CoreServiceHealth)
    $top = @(Get-TopMemoryUsage)
    $issues = @($services | Where-Object { $_.Assessment -ne "OK" })
    $overall = if ($issues.Count -eq 0) { "OK - service inti yang diperiksa berjalan" } elseif (@($issues | Where-Object { $_.Assessment -eq "RISIKO" }).Count -gt 0) { "RISIKO - ada service inti Disabled" } else { "PERLU PERHATIAN - ada service inti tidak berjalan / tidak terdeteksi" }
    "=== SYSTEM HEALTH SUMMARY ===" | Out-File $report -Encoding UTF8
    [pscustomobject]@{ RAMUsedMB=$ram.UsedMB; RAMAvailableMB=$ram.AvailableMB; RAMTotalMB=$ram.TotalMB; RAMLoadPercent=$ram.LoadPercent; CoreServiceStatus=$overall } | Format-List | Out-String | Add-Content $report
    "=== CORE SERVICE CHECK ===" | Add-Content $report
    $services | Format-Table -AutoSize | Out-String | Add-Content $report
    "=== TOP MEMORY PROCESSES (GROUPED BY PROCESS NAME) ===" | Add-Content $report
    $top | Format-Table -AutoSize | Out-String | Add-Content $report
    "=== COMPUTER ===" | Add-Content $report
    Get-CimInstance Win32_ComputerSystem | Format-List Manufacturer, Model, TotalPhysicalMemory | Out-String | Add-Content $report
    "=== OPERATING SYSTEM ===" | Add-Content $report
    Get-CimInstance Win32_OperatingSystem | Format-List Caption, Version, BuildNumber, OSArchitecture | Out-String | Add-Content $report
    "=== VIDEO CONTROLLER ===" | Add-Content $report
    Get-CimInstance Win32_VideoController | Format-List Name, DriverVersion, AdapterRAM | Out-String | Add-Content $report
    "=== RUNNING SERVICES ===" | Add-Content $report
    Get-CimInstance Win32_Service -Filter "State='Running'" | Select-Object Name, StartMode, State | Format-Table -AutoSize | Out-String | Add-Content $report
    Write-Host "Report dibuat: $report" -ForegroundColor Green
    Write-Host "Status service inti: $overall"
}


function Get-AppRemovalCatalog {
    # Conservative list: consumer apps only. Core Windows components are intentionally excluded.
    $patterns = @(
        [pscustomobject]@{ Pattern="Clipchamp"; Label="Clipchamp" },
        [pscustomobject]@{ Pattern="Microsoft.Xbox"; Label="Xbox apps" },
        [pscustomobject]@{ Pattern="Microsoft.GamingApp"; Label="Xbox app / Gaming Services UI" },
        [pscustomobject]@{ Pattern="Microsoft.BingNews"; Label="Microsoft News" },
        [pscustomobject]@{ Pattern="Microsoft.BingWeather"; Label="Weather" },
        [pscustomobject]@{ Pattern="Microsoft.MicrosoftSolitaireCollection"; Label="Solitaire Collection" },
        [pscustomobject]@{ Pattern="Microsoft.GetHelp"; Label="Get Help" },
        [pscustomobject]@{ Pattern="Microsoft.Getstarted"; Label="Tips / Get Started" },
        [pscustomobject]@{ Pattern="Microsoft.People"; Label="People" },
        [pscustomobject]@{ Pattern="Microsoft.YourPhone"; Label="Phone Link" },
        [pscustomobject]@{ Pattern="Microsoft.SkypeApp"; Label="Skype" },
        [pscustomobject]@{ Pattern="Microsoft.ZuneMusic"; Label="Groove Music" },
        [pscustomobject]@{ Pattern="Microsoft.ZuneVideo"; Label="Movies & TV" },
        [pscustomobject]@{ Pattern="Microsoft.MicrosoftOfficeHub"; Label="Office Hub" },
        [pscustomobject]@{ Pattern="Microsoft.549981C3F5F10"; Label="Cortana (if present)" },
        [pscustomobject]@{ Pattern="Microsoft.MixedReality.Portal"; Label="Mixed Reality Portal" },
        [pscustomobject]@{ Pattern="Microsoft.Microsoft3DViewer"; Label="3D Viewer" },
        [pscustomobject]@{ Pattern="Microsoft.Print3D"; Label="Print 3D" },
        [pscustomobject]@{ Pattern="Microsoft.WindowsMaps"; Label="Maps" },
        [pscustomobject]@{ Pattern="Microsoft.Todos"; Label="Microsoft To Do" },
        [pscustomobject]@{ Pattern="MicrosoftTeams"; Label="Microsoft Teams personal (if present)" }
    )

    $installed = @(Get-AppxPackage -ErrorAction SilentlyContinue)
    $results = @()
    foreach ($rule in $patterns) {
        foreach ($pkg in $installed) {
            # XboxGameCallableUI is a protected Windows system component, not a consumer Xbox app.
            if ($pkg.Name -eq "Microsoft.XboxGameCallableUI" -or $pkg.NonRemovable -eq $true) { continue }
            if ($pkg.Name -like "*$($rule.Pattern)*") {
                $results += [pscustomobject]@{
                    AppLabel = $rule.Label
                    Name = $pkg.Name
                    PackageFullName = $pkg.PackageFullName
                    PackageFamilyName = $pkg.PackageFamilyName
                    InstallLocation = $pkg.InstallLocation
                }
            }
        }
    }
    return $results | Sort-Object Name -Unique
}

function Show-RemovableApps {
    Write-Host "`n========== APLIKASI KONSUMEN YANG DAPAT DIEVALUASI ==========" -ForegroundColor Cyan
    $apps = @(Get-AppRemovalCatalog)
    if ($apps.Count -eq 0) {
        Write-Host "Tidak ditemukan aplikasi dalam katalog penghapusan."
        return
    }

    $i = 1
    $rows = foreach ($app in $apps) {
        [pscustomobject]@{
            No = $i
            App = $app.AppLabel
            Package = $app.Name
        }
        $i++
    }
    $rows | Format-Table -Wrap -AutoSize

    Write-Host "Aplikasi inti Windows, Store, Defender, Edge WebView2, dan komponen sistem tidak dimasukkan ke katalog ini."
}

function Remove-SelectedApps {
    $apps = @(Get-AppRemovalCatalog)
    if ($apps.Count -eq 0) {
        Write-Host "Tidak ada aplikasi yang cocok dengan katalog."
        return
    }

    Write-Host "`nAplikasi yang tersedia:"
    for ($i = 0; $i -lt $apps.Count; $i++) {
        Write-Host ("{0}. {1} [{2}]" -f ($i + 1), $apps[$i].AppLabel, $apps[$i].Name)
    }

    Write-Host "`nMasukkan nomor aplikasi yang ingin dihapus, pisahkan koma. Contoh: 1,3"
    $raw = Read-Host "Pilihan"
    if ([string]::IsNullOrWhiteSpace($raw)) { return }

    $selectedIndexes = @()
    foreach ($part in ($raw -split ",")) {
        $n = 0
        if ([int]::TryParse($part.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $apps.Count) {
            $selectedIndexes += ($n - 1)
        }
    }
    $selectedIndexes = @($selectedIndexes | Sort-Object -Unique)
    if ($selectedIndexes.Count -eq 0) {
        Write-Host "Tidak ada nomor valid."
        return
    }

    $selectedApps = @($selectedIndexes | ForEach-Object { $apps[$_] })
    Write-Host "`nAplikasi terpilih:"
    $selectedApps | Select-Object AppLabel, Name | Format-Table -AutoSize
    Write-Host "Penghapusan berlaku untuk akun Windows saat ini. Aplikasi mungkin dapat dipasang kembali melalui Microsoft Store."
    $confirm = Read-Host "Ketik REMOVE untuk melanjutkan"
    if ($confirm -cne "REMOVE") {
        Write-Host "Dibatalkan."
        return
    }

    $logPath = Join-Path $Root ("removed-apps-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".csv")
    $results = @()
    foreach ($app in $selectedApps) {
        try {
            $current = Get-AppxPackage -Name $app.Name -ErrorAction SilentlyContinue | Where-Object { $_.PackageFullName -eq $app.PackageFullName }
            if ($current) {
                Remove-AppxPackage -Package $current.PackageFullName -ErrorAction Stop
                $status = "Removed for current user"
                Write-Host "Dihapus: $($app.Name)" -ForegroundColor Green
                Write-Log "Appx removed for current user: $($app.Name)"
            } else {
                $status = "Package no longer installed"
            }
        } catch {
            $status = "Failed: " + $_.Exception.Message
            Write-Host "Gagal menghapus $($app.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }

        $results += [pscustomobject]@{
            Date = Get-Date
            AppLabel = $app.AppLabel
            Name = $app.Name
            PackageFullName = $app.PackageFullName
            Status = $status
        }
    }

    $results | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
    Write-Host "Log hasil penghapusan: $logPath" -ForegroundColor Green
    Write-Host "Catatan: log menyimpan identitas paket, bukan file instalasi atau backup aplikasi."
}

function Get-EdgeAuditState {
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    $applicationRoots = @(
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application"),
        (Join-Path $programFilesX86 "Microsoft\Edge\Application"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\Application")
    ) | Where-Object { $_ }

    $applicationDirectories = @()
    $edgeExecutables = @()
    foreach ($root in $applicationRoots) {
        if (Test-Path -LiteralPath $root) {
            $versionDirectories = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^\d+([.]\d+){2,3}$' })
            foreach ($directory in $versionDirectories) {
                $applicationDirectories += $directory.FullName
                $exe = Join-Path $directory.FullName "msedge.exe"
                if (Test-Path -LiteralPath $exe) { $edgeExecutables += $exe }
            }
        }
    }

    $uninstallRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    $uninstallEntries = @()
    foreach ($registryRoot in $uninstallRoots) {
        if (-not (Test-Path -LiteralPath $registryRoot)) { continue }
        foreach ($key in @(Get-ChildItem -LiteralPath $registryRoot -ErrorAction SilentlyContinue)) {
            $item = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
            if ($item -and $item.DisplayName -eq "Microsoft Edge") {
                $uninstallEntries += [pscustomobject]@{
                    DisplayName = $item.DisplayName
                    DisplayVersion = $item.DisplayVersion
                    RegistryPath = $key.Name
                }
            }
        }
    }

    $runningProcesses = @(Get-Process -Name "msedge" -ErrorAction SilentlyContinue)
    $legacyAppx = @()
    try {
        $legacyAppx = @(Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge" -ErrorAction Stop)
    } catch {}

    [pscustomobject]@{
        ApplicationDirectories = @($applicationDirectories | Sort-Object -Unique)
        Executables = @($edgeExecutables | Sort-Object -Unique)
        UninstallEntries = @($uninstallEntries)
        RunningProcesses = @($runningProcesses)
        LegacyAppxPackages = @($legacyAppx)
    }
}

function Show-EdgeAuditReport {
    param($State, [string]$ReportPath)

    $browserPresent = ($State.Executables.Count -gt 0) -or
        ($State.UninstallEntries.Count -gt 0) -or
        ($State.RunningProcesses.Count -gt 0) -or
        ($State.LegacyAppxPackages.Count -gt 0)
    $status = if ($browserPresent) { "MASIH TERDETEKSI" } else { "ABSENT - browser Edge tidak terdeteksi pada lokasi dan registrasi yang diperiksa" }

    $lines = @(
        "MICROSOFT EDGE REMOVAL AUDIT",
        ("Tanggal: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")),
        ("Komputer: {0}" -f $env:COMPUTERNAME),
        ("Status: {0}" -f $status),
        "",
        "=== EXECUTABLE EDGE ==="
    )
    if ($State.Executables.Count -gt 0) { $lines += $State.Executables } else { $lines += "Tidak ditemukan pada lokasi instalasi standar." }
    $lines += @("", "=== REGISTRASI UNINSTALL ===")
    if ($State.UninstallEntries.Count -gt 0) {
        foreach ($entry in $State.UninstallEntries) {
            $lines += ("{0} {1} | {2}" -f $entry.DisplayName, $entry.DisplayVersion, $entry.RegistryPath)
        }
    } else { $lines += "Tidak ditemukan." }
    $lines += @("", "=== PROSES EDGE ===")
    if ($State.RunningProcesses.Count -gt 0) {
        foreach ($process in $State.RunningProcesses) { $lines += ("{0} (PID {1})" -f $process.ProcessName, $process.Id) }
    } else { $lines += "Tidak ada proses msedge.exe yang berjalan." }
    $lines += @("", "=== LEGACY EDGE APPX ===")
    if ($State.LegacyAppxPackages.Count -gt 0) {
        foreach ($package in $State.LegacyAppxPackages) { $lines += ("{0} | NonRemovable={1}" -f $package.Name, $package.NonRemovable) }
    } else { $lines += "Tidak ditemukan." }
    $lines += @("", "=== FOLDER APLIKASI VERSI ===")
    if ($State.ApplicationDirectories.Count -gt 0) { $lines += $State.ApplicationDirectories } else { $lines += "Tidak ditemukan." }
    $lines += @(
        "",
        "WebView2 Runtime, Edge Update service/task, dan komponen Windows yang dilindungi sengaja tidak dihapus atau dianggap sebagai browser Edge.",
        "Audit ini memeriksa lokasi instalasi standar dan registrasi uninstall; bukan pemindaian menyeluruh seluruh disk.",
        "Windows Update, servicing, atau kebijakan organisasi dapat memasang kembali Edge."
    )

    $lines | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "========== HASIL AUDIT MICROSOFT EDGE ==========" -ForegroundColor Cyan
    Write-Host "Status: $status" -ForegroundColor $(if ($browserPresent) { "Yellow" } else { "Green" })
    Write-Host "Executable ditemukan: $($State.Executables.Count)"
    Write-Host "Registrasi uninstall: $($State.UninstallEntries.Count)"
    Write-Host "Proses aktif: $($State.RunningProcesses.Count)"
    Write-Host "Legacy Edge Appx: $($State.LegacyAppxPackages.Count)"
    Write-Host "Laporan: $ReportPath" -ForegroundColor Green
    return (-not $browserPresent)
}

function Show-EdgeComponents {
    Write-Host ""
    Write-Host "========== AUDIT MICROSOFT EDGE / WEBVIEW2 ==========" -ForegroundColor Cyan
    $state = Get-EdgeAuditState
    $report = Join-Path $Root ("edge-audit-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")
    [void](Show-EdgeAuditReport -State $state -ReportPath $report)

    $webViewRoots = @(
        (Join-Path $env:ProgramFiles "Microsoft\EdgeWebView\Application"),
        (Join-Path ([Environment]::GetEnvironmentVariable("ProgramFiles(x86)")) "Microsoft\EdgeWebView\Application")
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    if ($webViewRoots.Count -gt 0) {
        foreach ($path in $webViewRoots) {
            $versions = Get-ChildItem -LiteralPath $path -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^\d+([.]\d+){2,3}$' } |
                Select-Object -ExpandProperty Name
            Write-Host "WebView2 Runtime dipertahankan: $($versions -join ', ') [$path]"
        }
    } else {
        Write-Host "WebView2 Runtime tidak terdeteksi pada lokasi standar."
    }
}

function Uninstall-MicrosoftEdgeAdvanced {
    Write-Host ""
    Write-Host "========== UNINSTALL + CLEANUP + AUDIT MICROSOFT EDGE ==========" -ForegroundColor Yellow
    Write-Host "Fitur ini menghapus browser Microsoft Edge melalui uninstaller bawaan, membersihkan folder aplikasi versi yang tersisa, lalu membuat laporan audit." -ForegroundColor Yellow
    Write-Host "WebView2 Runtime, Edge Update, data profil pengguna, dan komponen Windows yang dilindungi TIDAK dihapus." -ForegroundColor Yellow
    Write-Host "Uninstall dapat mengganggu aplikasi, widget, PWA, dan fitur Windows yang bergantung pada Edge." -ForegroundColor Yellow
    Write-Host "Tidak semua build/region/policy Windows mengizinkan uninstall. Windows Update atau kebijakan organisasi dapat memasang Edge kembali." -ForegroundColor Yellow

    $initialState = Get-EdgeAuditState
    $report = Join-Path $Root ("edge-removal-report-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")
    if ($initialState.RunningProcesses.Count -gt 0) {
        Write-Host "Edge sedang berjalan. Tutup semua jendela Edge lalu jalankan menu ini kembali. Toolkit tidak akan memaksa menutup browser agar data pengguna tidak hilang." -ForegroundColor Red
        [void](Show-EdgeAuditReport -State $initialState -ReportPath $report)
        return
    }

    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    $candidateRoots = @(
        (Join-Path $programFilesX86 "Microsoft\Edge\Application"),
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\Application")
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $setups = @()
    foreach ($root in $candidateRoots) {
        $versions = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+([.]\d+){2,3}$' } |
            Sort-Object { [version]$_.Name } -Descending)
        foreach ($versionDir in $versions) {
            $setup = Join-Path $versionDir.FullName "Installer\setup.exe"
            if (Test-Path -LiteralPath $setup) {
                $setups += [pscustomobject]@{
                    Setup = $setup
                    SystemLevel = ($root -notlike "$env:LOCALAPPDATA*")
                    Version = $versionDir.Name
                }
                break
            }
        }
    }

    if ($setups.Count -eq 0) {
        Write-Host "Uninstaller Edge tidak ditemukan. Tidak ada file yang dihapus secara paksa." -ForegroundColor Yellow
        [void](Show-EdgeAuditReport -State $initialState -ReportPath $report)
        return
    }

    $selected = $setups | Select-Object -First 1
    Write-Host "Versi terdeteksi: $($selected.Version)"
    Write-Host "Uninstaller: $($selected.Setup)"
    Write-Host "Simpan bookmark/password penting sebelum melanjutkan. Data profil tidak dihapus oleh fitur ini."
    $confirm = Read-Host "Ketik UNINSTALL EDGE AND CLEANUP untuk melanjutkan"
    if ($confirm -cne "UNINSTALL EDGE AND CLEANUP") {
        Write-Host "Dibatalkan. Tidak ada perubahan dilakukan."
        return
    }

    try {
        $arguments = @("--uninstall", "--verbose-logging", "--force-uninstall")
        if ($selected.SystemLevel) { $arguments += "--system-level" }
        $process = Start-Process -FilePath $selected.Setup -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
        Write-Log "Edge uninstall process exited with code $($process.ExitCode)."

        $afterUninstall = Get-EdgeAuditState
        if ($afterUninstall.Executables.Count -eq 0 -and $afterUninstall.RunningProcesses.Count -eq 0) {
            foreach ($directory in $afterUninstall.ApplicationDirectories) {
                try {
                    if ((Test-Path -LiteralPath $directory) -and
                        ([IO.Path]::GetFileName($directory) -match '^\d+([.]\d+){2,3}$') -and
                        -not (Test-Path -LiteralPath (Join-Path $directory "msedge.exe"))) {
                        Remove-Item -LiteralPath $directory -Recurse -Force -ErrorAction Stop
                        Write-Log "Removed residual Edge application version folder: $directory"
                    }
                } catch {
                    Write-Host "Tidak dapat membersihkan folder $directory : $($_.Exception.Message)" -ForegroundColor Yellow
                    Write-Log "Edge residual cleanup failed for $directory : $($_.Exception.Message)"
                }
            }
        } else {
            Write-Host "Executable/proses Edge masih ditemukan. Folder aplikasi tidak dibersihkan secara paksa." -ForegroundColor Yellow
        }

        $finalState = Get-EdgeAuditState
        $isAbsent = Show-EdgeAuditReport -State $finalState -ReportPath $report
        if ($process.ExitCode -ne 0) {
            Write-Host "Uninstaller mengembalikan exit code $($process.ExitCode)." -ForegroundColor Yellow
        }
        if ($isAbsent) {
            Write-Host "AUDIT: browser Edge tidak terdeteksi pada lokasi standar dan registrasi uninstall yang diperiksa." -ForegroundColor Green
        } else {
            Write-Host "AUDIT: Edge atau jejak registrasi masih terdeteksi. Periksa laporan; jangan hapus registry/file secara manual." -ForegroundColor Yellow
        }
        Write-Host "Restart Windows, lalu jalankan menu 17 untuk audit ulang."
        Write-Host "WebView2 Runtime, Edge Update, dan data profil pengguna tetap dipertahankan."
        Write-Log "Edge removal audit completed. Absent=$isAbsent; ExitCode=$($process.ExitCode). Report=$report"
    } catch {
        Write-Host "Uninstall/cleanup gagal: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Edge uninstall/cleanup failed: $($_.Exception.Message)"
        $finalState = Get-EdgeAuditState
        [void](Show-EdgeAuditReport -State $finalState -ReportPath $report)
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " WINDOWS 10 RAM & RESPONSIVENESS TOOLKIT" -ForegroundColor Cyan
    Write-Host " Target: Windows 10 22H2 x64 | PowerShell 5.1"
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " 1. Ringkasan penggunaan RAM"
    Write-Host " 2. List semua service yang sedang Running"
    Write-Host " 3. List service opsional yang aman dievaluasi"
    Write-Host " 4. Disable service opsional yang dipilih"
    Write-Host " 5. Ubah service opsional terpilih ke Manual"
    Write-Host " 6. List aplikasi UWP / status background"
    Write-Host " 7. Batasi aplikasi background untuk akun ini"
    Write-Host " 8. List aplikasi Startup"
    Write-Host " 9. List 10 kelompok proses pemakai RAM terbesar"
    Write-Host "10. Terapkan optimasi aman (background, Game DVR, visual, pagefile)"
    Write-Host "11. Aktifkan System Managed Pagefile"
    Write-Host "12. Restore baseline sebelum optimasi"
    Write-Host "13. Export laporan sistem"
    Write-Host "14. Buka folder backup dan log"
    Write-Host "15. List aplikasi bawaan yang dapat dievaluasi untuk uninstall"
    Write-Host "16. Uninstall aplikasi terpilih (UWP / Appx)"
    Write-Host "17. Audit Microsoft Edge, WebView2, dan status instalasi"
    Write-Host "18. Laporan singkat kesehatan service dan konsumsi RAM"
    Write-Host "19. Uninstall Edge + cleanup file + laporan verifikasi"
    Write-Host "20. Atur Virtual Memory custom (SSD C: only, 1000-24000 MB)"
    Write-Host " 0. Keluar"
    Write-Host "----------------------------------------------------"
}

if (-not (Test-Administrator)) {
    Write-Host "Jalankan Windows PowerShell dengan Run as administrator." -ForegroundColor Red
    Read-Host "Tekan Enter untuk keluar"
    exit 1
}

New-Item -Path $Root -ItemType Directory -Force | Out-Null

$exitRequested = $false
do {
    Show-Menu
    $choice = Read-Host "Pilih menu"
    switch ($choice) {
        "1"  { Get-RamReport; Pause-Menu }
        "2"  { Show-RunningServices; Pause-Menu }
        "3"  { Show-OptionalServices; Pause-Menu }
        "4"  { Disable-SelectedServices; Pause-Menu }
        "5"  { Set-SelectedServicesManual; Pause-Menu }
        "6"  { Show-BackgroundApps; Pause-Menu }
        "7"  { Disable-BackgroundApps; Pause-Menu }
        "8"  { Show-StartupApps; Pause-Menu }
        "9"  { Show-TopMemoryProcesses; Pause-Menu }
        "10" { Apply-SafeOptimizations; Pause-Menu }
        "11" { Set-SystemManagedPagefile; Pause-Menu }
        "12" { Restore-Baseline; Pause-Menu }
        "13" { Export-SystemReport; Pause-Menu }
        "14" { Start-Process explorer.exe -ArgumentList $Root }
        "15" { Show-RemovableApps; Pause-Menu }
        "16" { Remove-SelectedApps; Pause-Menu }
        "17" { Show-EdgeComponents; Pause-Menu }
        "18" { Show-SystemHealthReport; Pause-Menu }
        "19" { Uninstall-MicrosoftEdgeAdvanced; Pause-Menu }
        "20" { Set-CustomPagefileOnC; Pause-Menu }
        "0"  { $exitRequested = $true }
        default { Write-Host "Pilihan tidak valid." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
} while (-not $exitRequested)