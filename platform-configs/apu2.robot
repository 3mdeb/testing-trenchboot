*** Variables ***

${rte_s2n_port}            13541
${flash_size}              ${8*1024*1024}
${seabios_string}          F10
${seabios_key}             \x1b[21~
${payload_string}          Payload [setup]
${ipxe_boot_entry}         ?. iPXE
${ipxe_string}             autoboot
${ipxe_string2}            N for PXE boot
${ipxe_key}                \x1b[A
${grub_key}                \x1b[B
${net_boot_key}            n
${net_boot_string}         Booting from ROM
${sol_string}              DRAM
${sn_pattern}              ^\\d{7}$
${manufacturer}            PC Engines
${cpu}                     AMD GX-412TC SOC

## Regression test flags
${iPXE_config_support}     ${True}

*** Keywords ***

Set Platform Library As Preferred
    Set Library Search Order    apu2

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
