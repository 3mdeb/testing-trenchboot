*** Variables ***

${rte_s2n_port}         13541
${bios_string}          F11
${bios_key}             \x1b\x21
${payload_string}       Payload [setup]
${ipxe_boot_entry}      PXE
${ipxe_string}          autoboot
${ipxe_string2}         N for PXE boot
${ipxe_key}             \x1b[A
${boot_menu_key}        \x1b[B
${grub_key}             \x1b[B
${grub_key_up}          \x1b[A
${grub_reference_str}   *boot
${grub_rs_offset}       0
${dev_type}             None

@{grub_boot_info_list}    PCR extended    lz_main() is about to exit
...    grub_cmd_slaunch

# Regression test flags
${iPXE_config_support}     ${False}

*** Keywords ***

Power On
    Sleep    3s
    RteCtrl Power Off
    Sleep    1s
    # read the old output
    Telnet.Read
    RteCtrl Power On

GRUB boot entry
    [Documentation]    Enter specified in argument iPXE menu entry.
    [Arguments]    ${menu_entry}    ${reference_str}    ${rs_offset}
    Telnet.Set Timeout    120s
    Telnet.Read Until    GNU GRUB
    ${move}=    GRUB get menu position    ${menu_entry}    ${reference_str}    ${rs_offset}
    ${grub_key}=    Set Variable If    ${move} < 0    ${grub_key_up}    ${grub_key}
    : FOR    ${INDEX}    IN RANGE    0    ${move.__abs__()}
    \   Telnet.Write Bare   ${grub_key}
    \   Sleep    0.5s
    Telnet.Write Bare    \n
    RteCtrl Power On

iPXE dhcp
    [Documentation]    Request IP address in iPXE shell. Takes network port
    ...                number as an argument, which by default is set to 0.
    [Arguments]    ${net_port}=0
    # request IP address
    Telnet.Set Timeout    50s
    Telnet.Write Bare    dhcp net${net_port}\n
    Telnet.Read Until    Configuring
    Telnet.Read Until    ok
    Telnet.Read Until    iPXE>

iPXE menu
    [Documentation]    Enter iPXE menu. Takes PXE IP addres, http port number,
    ...                ipxe filename nad network port number as an arguments.
    [Arguments]    ${pxe_address}    ${filename}    ${net_port}=0
    ...            ${read_until}=iPXE boot menu
    Set Timeout    30
    Sleep    30s
    Telnet.Read
    Wait Until Keyword Succeeds    3x    2s    iPXE dhcp    ${net_port}
    Sleep    10s
    Telnet.Write Bare    chain http://${pxe_address}/${filename}\n    0.1
    Telnet.Set Timeout    90s

Boot from iPXE
    [Documentation]    Boot Asrock from iPXE menu. Takes PXE IP addres chosen
    ...    ipxe image filename  and network port number as an arguments.
    [Arguments]   ${pxe_address}   ${filename}   ${option}=None   ${net_port}=0
    Sleep    30s
    iPXE menu    ${pxe_address}    ${filename}    ${net_port}    Linux
