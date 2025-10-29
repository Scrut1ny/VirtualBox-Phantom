# ==================================================
# Admin Check
# ==================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$($PWD.Path)'; & '$($myInvocation.InvocationName)'`"" -Verb RunAs
    Exit
}

# ==================================================
# VirtualBox Configuration Script
# ==================================================

$VBoxManager = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"

if (-not (Test-Path $VBoxManager)) {
    Write-Host "  # VirtualBox is not installed." -ForegroundColor Red
    exit 1
}

Write-Host "`n  # Available VMs:`n"
& $VBoxManager list vms

$VM = Read-Host "`n  # Enter VM Name"
$VDI = "$env:USERPROFILE\VirtualBox VMs\$VM\$VM.vdi"

try {
    & $VBoxManager modifyvm $VM --clipboard-mode "bidirectional" --drag-and-drop "bidirectional"
    & $VBoxManager modifyvm $VM --mouse "ps2" --keyboard "ps2"
    & $VBoxManager modifyvm $VM --pae "on" --nested-hw-virt "on"
    & $VBoxManager modifyvm $VM --paravirtprovider "none" --nested-paging "on"
    & $VBoxManager modifyvm $VM --audio-out "on" --audio-in "on"
    & $VBoxManager modifyvm $VM --nic1 "bridged" --mac-address1 "428D5C257A8B"
    & $VBoxManager modifyvm $VM --hwvirtex "on" --vtx-ux "on"
    & $VBoxManager modifyvm $VM --large-pages "on"


    # ===== Storage Config [SATA > NVMe] =====
    # Notes:
    # - Many OS installers (especially older Windows installers) expect to boot from a SATA/AHCI controller.
    # - Recommended workflow:
    #     1. Create VM and attach disk to SATA (AHCI) controller.
    #     2. Install the OS onto the disk while attached to SATA.
    #     3. After installation (and tools/driver availability confirmed), add an NVMe controller:
    #         - `storagectl --name "NVMe" --add "pcie" --controller "NVMe" --bootable "on"`
    #         - detach disk from SATA and attach to NVMe (storageattach).
    # - There are known quirks with VirtualBox NVMe emulation; the example lines below are commented.
    # - If switching to NVMe, consider setting the NVMe extradata "MsiXSupported"/"CtrlMemBufSize" fixes if required.
    #
    # Example (commented out):
    # & $VBoxManager storagectl $VM --name "NVMe" --add "pcie" --controller "NVMe" --bootable "on"
    # & $VBoxManager storageattach $VM --storagectl "SATA" --port "0" --device "0" --medium "none"
    # & $VBoxManager storageattach $VM --storagectl "NVMe" --port "0" --device "0" --type "hdd" --medium "$VDI" --nonrotational "on"
    # NVMe fixes (if needed):
    # & $VBoxManager setextradata $VM "VBoxInternal/Devices/nvme/0/Config/MsiXSupported" "0"
    # & $VBoxManager setextradata $VM "VBoxInternal/Devices/nvme/0/Config/CtrlMemBufSize" "0"


    # ===== CPU =====
    & $VBoxManager modifyvm $VM --cpu-profile "AMD Ryzen 7 1800X Eight-Core"

    # RDTSC handling: reduce the gap between host/guest TSC behavior
    & $VBoxManager setextradata $VM "VBoxInternal/TM/TSCMode" "RealTSCOffset"

    # Expose SSE features to guest
    & $VBoxManager setextradata $VM "VBoxInternal/CPUM/SSE4.1" "1"
    & $VBoxManager setextradata $VM "VBoxInternal/CPUM/SSE4.2" "1"


    # ===== SMBIOS / DMI Configuration =====

    # DMI BIOS Information (type 0)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "American Megatrends International, LLC."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "1.A0"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "11/23/2023"

    # DMI System Information (type 1)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "Micro-Star International Co., Ltd."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "MS-7D78"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "1.0"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "To be filled by O.E.M."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "To be filled by O.E.M."

    # DMI Base Board / Module Information (type 2)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "Micro-Star International Co., Ltd."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "PRO B650-P WIFI (MS-7D78)"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "1.0"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "To be filled by O.E.M."

    # DMI System Enclosure / Chassis (type 3)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "Micro-Star International Co., Ltd."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" "03"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "1.0"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "To be filled by O.E.M."

    # DMI Processor Information (type 4)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "Advanced Micro Devices, Inc."
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "AMD Ryzen 7 1800X Eight-Core Processor"

    # DMI OEM strings (type 11)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" "<EMPTY>"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" "<EMPTY>"

    # Configure Hard Disk/VPD strings (optional cosmetic values)
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" "Samsung SSD 980 EVO"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "L4Q8G9Y1"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" "J8R9H3P5N4Q7W0X2Y9A5"

    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ModelNumber" "HL-DT-ST BD-RE WH16NS60"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/FirmwareRevision" "P2K9W6X5"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/SerialNumber" "Q2W3E4R5T6Y7U8I9O0PA"

    # CD/DVD drive identification strings
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIProductId" "DVD A DS8A8SH"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIRevision" "KAA2"
    & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIVendorId" "Slimtype"

    Write-Host "`n  # Success" -ForegroundColor Green
}
catch {
    Write-Host "`n  # An error occurred: $_" -ForegroundColor Red
}

# https://en.wikipedia.org/wiki/CPUID
# "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" list cpu-profiles
# "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" list hostcpuids

# & $VBoxManager modifyvm $VM --cpuid-set "00000001", "00a60f12", "02100800", "7ed8320b", "178bfbff"
# & $VBoxManager modifyvm $VM --paravirtdebug "enabled=1,vendor=AuthenticAMD"
# & $VBoxManager modifyvm $VM --paravirtdebug "enabled=1,vendor=GenuineIntel"
