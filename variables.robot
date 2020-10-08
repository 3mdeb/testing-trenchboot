*** Variables ***

${pxe_address}         boot.3mdeb.com
${http_port}           8000
${pxe_filename}        menu.ipxe
${USERNAME}            root
${PASSWORD}            meta-rte
${dev_type}            auto    # Supported values: SSD, HDD, USB, SDC
${dev_file}            auto    # For example: /dev/sda


@{STORAGE_PRIORITY}  SSD_Storage    HDD_Storage    USB_Storage    SDC_Storage
# TB Hardware config

&{RTE01}    cpuid=02c000420c4ce851    pcb_rev=0.5.3
...         platform=apu2       board-revision=c4
...         rte_ip=none
...         install_disk=auto
...         boot_menu_entry=auto

&{RTE02}    cpuid=02c00042f3ba1188    pcb_rev=0.5.3
...         platform=apu2       board-revision=d
...         platform_vendor=PC Engines    rte_ip=none
...         install_disk=/dev/disk/by-id/ata-Hoodisk_SSD_JCTTC7A11230049
...         boot_menu_entry=AHCI/0: Hoodisk SSD ATA-11 Hard-Disk (15272 MiBytes)

&{RTE03}    cpuid=02c0004298d28199    pcb_rev=0.5.3
...         platform=asrock       board-revision=none
...         platform_vendor=Asrock    rte_ip=none
...         install_disk=/dev/disk/by-id/usb-Innostor_Innostor_7529196330783-0:0
...         boot_menu_entry=UEFI: InnostorInnostor 1.00, Partition 1
...         boot_menu_ipxe=USB: SanDisk

&{RTE04}    cpuid=02c00042a0dd0cd0    pcb_rev=0.5.3
...         platform=supermicro       board-revision=none
...         platform_vendor=supermicro    rte_ip=none
...         install_disk=/dev/disk/by-id/usb-SanDisk_Ultra_Fit_4C530000030116217075-0:0
...         boot_menu_entry=UEFI: SanDisk, Partition 1
...         boot_menu_ipxe=ADATA USB Flash Drive 1100



@{RTE_LIST}    &{RTE01}    ${RTE02}    ${RTE03}    ${RTE04}

# hardware configuration:
# -----------------------------------------------------------------------------
#&{HDD01}        vendor=Toshiba    volume=250GB    type=HDD_Storage
#...             interface=SATA    count=1
#@{HDD_LIST}     &{HDD01}
# -----------------------------------------------------------------------------
&{SSD01}        vendor=Hoodisk    volume=32GB    type=SSD_Storage
...             interface=mSATA    count=1
&{SSD02}        vendor=Hoodisk    volume=16GB    type=SSD_Storage
...             interface=mSATA    count=1
@{SSD_LIST}     &{SSD01}    ${SSD02}
# -----------------------------------------------------------------------------
&{CARD01}       vendor=SanDisk    volume=16GB    type=SDC_Storage
...             interface=SD    count=1
@{CARD_LIST}    &{CARD01}
# -----------------------------------------------------------------------------
&{USB01}        vendor=Kingston    volume=16GB    type=USB_Storage
...             protocol=3.0    interface=USB    count=1
&{USB02}        vendor=Sandisk    volume=16GB    type=USB_Storage
...             protocol=3.0    interface=USB    count=2
@{USB_LIST}     &{USB01}    &{USB02}
# -----------------------------------------------------------------------------
&{MODULE01}       vendor=Infineon-SLB9665 TT 2.0    type=TPM_Module
...               interface=LPC    count=2
@{MODULE_LIST}    &{MODULE01}
# -----------------------------------------------------------------------------

# hardware configurations:
@{CONFIG01}    &{RTE01}       &{SSD01}       &{CARD01}       &{USB01}
...            &{MODULE01}
@{CONFIG02}    &{RTE02}    ${SSD02}    ${MODULE01}
@{CONFIG03}    &{RTE03}    ${USB02}
@{CONFIG04}    &{RTE04}

@{CONFIG_LIST}    @{CONFIG01}    @{CONFIG02}    @{CONFIG03}    @{CONFIG04}
