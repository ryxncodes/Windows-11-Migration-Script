#Requires -RunAsAdministrator
# Written by Ryan 3/5/2026; optimized 3/24/2026 and added hard drive checks

$pass = "[" + [char]0x2713 + "]"
$fail = "[X]"

$jobRAM   = Start-Job { (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory }
$jobDisk  = Start-Job { Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } }
$jobTPM   = Start-Job { Get-CimInstance -Namespace "root/cimv2/Security/MicrosoftTpm" -ClassName Win32_Tpm }
$jobOS    = Start-Job { (Get-CimInstance Win32_OperatingSystem).Caption }
$jobDrive = Start-Job { (Get-Disk | Where-Object { $_.Number -eq 0 }).PartitionStyle }
$jobDriveInfo = Start-Job { 
    $disk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq "0" }
    [PSCustomObject]@{
        MediaType = $disk.MediaType.ToString()
        BusType = $disk.BusType.ToString()
    }
}

try { $secureBoot = Confirm-SecureBootUEFI } catch { $secureBoot = $false }

$pendingReboot = (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or
                 (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -or
                 (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations")

$static = Get-NetIPAddress | Where-Object {
    $_.AddressFamily -eq "IPv4" -and
    $_.InterfaceAlias -like "*Ethernet*" -and
    ($_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*") -and
    $_.PrefixOrigin -eq "Manual"
}

$ramRaw    = Receive-Job $jobRAM   -Wait
$cDrive    = Receive-Job $jobDisk  -Wait
$tpm       = Receive-Job $jobTPM   -Wait
$osCaption = Receive-Job $jobOS    -Wait
$partStyle = Receive-Job $jobDrive -Wait
$driveInfo = Receive-Job $jobDriveInfo -Wait

Get-Job | Remove-Job

$ram        = [Math]::Round($ramRaw / 1GB, [System.MidpointRounding]::AwayFromZero)
$space      = [Math]::Round($cDrive.FreeSpace / 1GB, [System.MidpointRounding]::AwayFromZero)
$driveSize  = [Math]::Round($cDrive.Size / 1GB, [System.MidpointRounding]::AwayFromZero)
$tpmVersion = $tpm.SpecVersion -like "*2.0*" -and $tpm.IsEnabled_InitialValue
$GPT        = $partStyle -eq "GPT"
$os         = $osCaption -like "*Enterprise*"

Write-Host "$env:COMPUTERNAME $(Get-Date)`n"
Write-Host "$(if ($tpmVersion) {$pass}else{$fail}) TPM 2.0"
Write-Host "$(if ($GPT) {$pass}else{$fail}) GPT Partition"
Write-Host "$(if ($secureBoot) {$pass}else{$fail}) Secure Boot"
Write-Host "$(if ($os) {$pass}else{$fail}) Enterprise Edition"
Write-Host "$(if (-not $pendingReboot) {$pass}else{$fail}) No Pending Reboot"
Write-Host "$(if ($ram -ge 4) {$pass}else{$fail}) $ram GB RAM"
Write-Host "$(if ($space -gt 64) {$pass}else{$fail}) $($space)GB/$($driveSize)GB Free Space"
Write-Host "Drive: $($driveInfo.MediaType) ($($driveInfo.BusType))"
if ($static) {
    Write-Host "Static IP: $($static.IPAddress)"
} else {
    Write-Host "No Static IP Detected"
}

Read-Host "`nPress Enter to Close"