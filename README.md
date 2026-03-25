# Win11Requirements.ps1

A PowerShell script that checks whether a Windows 10 machine meets the hardware and configuration requirements for a Windows 11 upgrade. Written during a Windows 11 migration project at a healthcare organization managing 5,000+ endpoints.

## Background

During a large-scale Windows 11 migration, manually verifying compatibility across hundreds of machines was tedious and error-prone. We found ourselves often forgetting what requirements each machine was missing and having to constantly check was eating into our productivity. This script consolidates all the relevant checks into a single output so a technician can assess a machine in seconds. Instead of checking tpm.msc then diskmgmt.msc, etc, all you need to run is this one script. 

## Requirements

- Windows 10 (PowerShell 5.1)
- Must be run as Administrator

## Checks Performed

| Check | Requirement |
|---|---|
| TPM | Version 2.0, enabled |
| Partition Style | GPT |
| Secure Boot | Enabled via UEFI |
| Windows Edition | Enterprise |
| Pending Reboot | None |
| RAM | 4 GB minimum |
| Free Disk Space | 64 GB minimum on C: |
| Drive Info | Media type and bus type (SSD/HDD, NVMe/SATA) |
| Static IP | Detects manually assigned IPs on Ethernet adapters (based on our specific requirements, yours will likely be different) |

## Example Output

```
RYAN-LAPTOP 03/24/2026 19:53:24

[✓] TPM 2.0
[✓] GPT Partition
[X] Secure Boot
[X] Enterprise Edition
[✓] No Pending Reboot
[✓] 64 GB RAM
[✓] 932GB/1407GB Free Space
Drive: SSD (NVMe)
No Static IP Detected
```

## Notes
- This does not check processor compatibility as we made use of the processor bypass
- CIM queries run in parallel using `Start-Job` to reduce runtime on older hardware
- Static IP detection targets internal RFC 1918 ranges (10.x, 172.x) on Ethernet adapters only
- `MediaType` may return `Unspecified` on some older drives due to a WMI limitation
