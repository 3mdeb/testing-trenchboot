*** Variables ***

${rte_s2n_port}         13541
${flash_size}           ${8*1024*1024}
${seabios_string}       F10
${seabios_key}          \x1b[21~
${payload_string}       Payload [setup]
${ipxe_boot_entry}      ?. iPXE
${ipxe_string}          autoboot
${ipxe_string2}         N for PXE boot
${ipxe_key}             \x1b[A
${grub_key}             \x1b[B
${grub_key_up}          \x1b[A
${grub_reference_str}   GNU GRUB
${grub_rs_offset}       3
${net_boot_key}         n
${net_boot_string}      Booting from ROM
${yoc_ipxe_option}      Flashing tools for Apu2

@{grub_boot_info_list}    grub_cmd_slaunch    grub_cmd_slaunch_module
...                       grub_slaunch_boot_skinit

## Regression test flags
${iPXE_config_support}     ${True}

*** Keywords ***

Power On
    [Documentation]    Keyword clears telnet buffer and sets Device Under Test
    ...                into Power On state using RTE OC buffers. Implementation
    ...                must be compatible with the theory of operation of a
    ...                specific platform.
    Sleep    3s
    RteCtrl Power Off
    Sleep    1s
    # read the old output
    Telnet.Read
    RteCtrl Power On

Flash apu
    [Documentation]    Flash Device Under Test firmware, check flashing result
    ...                and set RTE relay to OFF state. Implementation must be
    ...                compatible with the theory of operation of a specific
    ...                platform.
    RteCtrl Power Off
    Sleep    2s
    # set WP pin free in case BIOS WP was not disabled to let flashrom disable flash WP
    RteCtrl Set OC GPIO    12    high-z
    ${flash_result}    ${rc}=    SSHLibrary.Execute Command    flashrom -f -p linux_spi:dev=/dev/spidev1.0,spispeed=16000 -w /tmp/coreboot.rom 2>&1    return_rc=True
    Run Keyword If    ${rc} != 0    Log To Console    \nFlashrom returned status ${rc}\n
    Return From Keyword If    ${rc} == 3
    Return From Keyword If    "Warning: Chip content is identical to the requested image." in """${flash_result}"""
    Should Contain    ${flash_result}     VERIFIED
    Power Cycle Off

Read firmware apu
    [Documentation]    Read Device Under Test firmware and set RTE relay to OFF
    ...                state. Implementation must be compatible with the theory
    ...                of operation of a specific platform.
    RteCtrl Power Off
    Sleep    2s
    SSHLibrary.Execute Command    flashrom -p linux_spi:dev=/dev/spidev1.0,spispeed=16000 -r /tmp/coreboot.rom
    Power Cycle Off

Boot from iPXE
    [Documentation]    Boot Flasing Tools For Apu 2 from iPXE menu and login to
    ...                system. Takes PXE IP addres, http port number, ipxe
    ...                filename, system version and network port number as an arguments.
    [Arguments]    ${pxe_address}    ${filename}    ${option}    ${net_port}=0
    Enter iPXE
    iPXE menu    ${pxe_address}    ${filename}    ${net_port}
    iPXE boot entry    ${option}
    Sleep    10s
    Telnet.Set Timeout    180
    Telnet.Set Prompt    \#
    Sleep    60s
    Telnet.Read
    Telnet.Write    root
    Telnet.Read Until Prompt

Boot From Storage Device
    [Arguments]    ${dev}
    Boot Menu Choose Entry    ${dev}

Gather and install meta-trenchboot artifacts
    [Documentation]    TODO
    [Arguments]    ${install_device}    ${artifacts_link}
    #${bmap_file}=    Set Variable    tb-minimal-image-pcengines-apu2.wic.bmap
    ${gz_file}=    Set Variable    tb-minimal-image-pcengines-apu2.wic.gz
    Telnet.Execute Command    cd /tmp
    Telnet.Execute Command    wget -O artifacts.zip ${artifacts_link}
    Telnet.Execute Command    unzip artifacts.zip && cd artifacts
    Telnet.Execute Command    bmaptool copy --bmap ${gz_file} ${install_device}
