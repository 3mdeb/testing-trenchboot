*** Variables ***

${pxe_address}         boot.3mdeb.com
${http_port}           8000
${filename}            menu.ipxe
${USERNAME}            root
${PASSWORD}            armbian
${artifacts_link}   https://gitlab.com/trenchboot1/3mdeb/meta-trenchboot/-/jobs/529653096/artifacts/download

@{boot_info_list}    grub_cmd_slaunch    grub_cmd_slaunch_module
...                  grub_slaunch_boot_skinit

# TB Hardware config

&{RTE01}    cpuid=02c000420c4ce851    pcb_rev=0.5.3
...         platform=apu2       board-revision=c4
...         rte_ip=none

@{RTE_LIST}    &{RTE01}

# hardware configuration:
# -----------------------------------------------------------------------------
#&{HDD01}        vendor=Toshiba    volume=250GB    type=HDD_Storage
#...             interface=SATA    count=1
#@{HDD_LIST}     &{HDD01}
# -----------------------------------------------------------------------------
&{SSD01}        vendor=Hoodisk    volume=32GB    type=Storage_SSD
...             interface=mSATA    count=2
@{SSD_LIST}     &{SSD01}
# -----------------------------------------------------------------------------
&{CARD01}       vendor=SanDisk    volume=16GB    type=SD_Storage
...             interface=SD    count=2
@{CARD_LIST}    &{CARD01}
# -----------------------------------------------------------------------------
&{USB01}        vendor=Kingston    volume=16GB    type=USB_Storage
...             protocol=3.0    interface=USB    count=2
@{USB_LIST}     &{USB01}
# -----------------------------------------------------------------------------
&{MODULE01}       vendor=Infineon-SLB9665 TT 2.0    type=TPM_Module
...               interface=LPC    count=3
@{MODULE_LIST}    &{MODULE01}
# -----------------------------------------------------------------------------

# hardware configurations:
@{CONFIG01}    &{RTE01}       &{SSD01}       &{CARD01}       &{USB01}
...            &{MODULE01}

@{CONFIG_LIST}    @{CONFIG01}
