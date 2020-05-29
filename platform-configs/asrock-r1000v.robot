*** Variables ***

${rte_s2n_port}            13541
${flash_size}              ${8*1024*1024}
${seabios_string}          F11
${seabios_key}             \x1b\x21
${payload_string}          Payload [setup]
${ipxe_boot_entry}         PXE
${ipxe_string}             autoboot
${ipxe_string2}            N for PXE boot
${ipxe_key}                \x1b[A
${boot_menu_key}           \x1b[B
${grub_key}                \x1b[B
${net_boot_key}            n
${net_boot_string}         Booting from ROM
${sol_string}              DRAM
${sn_pattern}              ^\\d{7}$
${manufacturer}            Asrock
${cpu}                     AMD R1505G SOC

# Regression test flags
${iPXE_config_support}     ${True}

*** Keywords ***

Set Chosen Platform Library As Preferred
    Set Library Search Order    asrock-r1000v

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

Get Boot Menu Position
    [Documentation]    Evaluate and return relative menu entry position
    ...                described in the argument.
    [Arguments]    ${entry}
    Sleep    5s
    ${output}=    Telnet.Read
    Log    ${output}
    # enumerate output buffer lines and find line number which contain string
    ${first_line}=    Get Line Number Containing String    ${output}    Please select boot device
    ${entry_line}=    Get Line Number Containing String    ${output}    ${entry}
    ${rel_pos}=    Evaluate    ${entry_line} - ${first_line} - 2
    [Return]    ${rel_pos}

Boot Menu Choose Entry
    [Documentation]    Enter specified in argument iPXE menu entry.
    [Arguments]    ${menu_entry}
    Set Timeout    30s
    ${move}=    Get Boot Menu Position    ${menu_entry}
    : FOR    ${INDEX}    IN RANGE    0    ${move}
    \   Telnet.Write Bare   ${boot_menu_key}
    \   Sleep    0.5s
    Telnet.Write Bare    \n

Enter BIOS
    [Documentation]    Enter BIOS with key specified in platform-configs.
    # waiting for SeaBIOS boot menu enter string may be delayed by xHCI init
    # set longer timeout to prevent test failure
    Telnet.Set Timeout    60s
    Telnet.Read Until    ${seabios_string}
    Telnet.Write Bare    ${seabios_key}

Enter iPXE
    [Documentation]    Enter iPXE after device power cutoff.
    Enter BIOS
    Sleep    0.5s
    Boot Menu Choose Entry    PXE
    iPXE wait for prompt

iPXE menu
    [Documentation]    Enter iPXE menu. Takes PXE IP addres, http port number,
    ...                ipxe filename nad network port number as an arguments.
    [Arguments]    ${pxe_address}    ${filename}    ${net_port}=0
    ...            ${read_until}=iPXE boot menu
    Set Timeout    30
    Sleep    30s
    Telnet.Read
    Wait Until Keyword Succeeds    3x    2s    iPXE dhcp    ${net_port}
    Write Bare Checking Every Letter    chain http://${pxe_address}/${filename}\n
