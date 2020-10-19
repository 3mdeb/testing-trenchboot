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
${pxe_filename}         tb/menu.ipxe
${yoc_ipxe_option}      Debian stable netboot 4.14.y
${power_ctrl}           sonoff

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

Enter BIOS
    [Documentation]    Enter BIOS with key specified in platform-configs.
    # waiting for SeaBIOS boot menu enter string may be delayed by xHCI init
    # set longer timeout to prevent test failure
    Telnet.Set Timeout    60s
    Telnet.Read Until    ${bios_string}
    Sleep    5s
    Telnet.Write Bare    ${bios_key}

#GRUB boot entry
#    [Documentation]    Enter specified in argument iPXE menu entry.
#    [Arguments]    ${menu_entry}    ${reference_str}    ${rs_offset}
#    Telnet.Set Timeout    120s
#    Telnet.Read Until    GNU GRUB
#    ${move}=    GRUB get menu position    ${menu_entry}    ${reference_str}    ${rs_offset}
#    ${grub_key}=    Set Variable If    ${move} < 0    ${grub_key_up}    ${grub_key}
#    : FOR    ${INDEX}    IN RANGE    0    ${move.__abs__()}
#    \   Telnet.Write Bare   ${grub_key}
#    \   Sleep    0.5s
#    Telnet.Write Bare    \n
#    RteCtrl Power On

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
    Telnet.Write Bare    \r

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
    [Documentation]    Boot Supermicro from iPXE menu. Takes PXE IP addres chosen
    ...    ipxe image filename  and network port number as an arguments.
    [Arguments]   ${pxe_address}   ${filename}   ${menu_entry}=None   ${net_port}=0
    ${boot_menu_ipxe}=    Get Current RTE param    boot_menu_ipxe
    Boot From Storage Device   ${boot_menu_ipxe}
    Sleep    30s
    iPXE menu    ${pxe_address}    ${filename}    ${net_port}    Linux
    Log To Console    Menu entry ${menu_entry}'$
    Run Keyword If    '${menu_entry}'!='None'    iPXE boot entry    ${menu_entry}

GRUB boot entry
    [Documentation]    Enter specified in argument iPXE menu entry.
    [Arguments]    ${menu_entry}    ${reference_str}    ${rs_offset}
    Telnet.Set Timeout    90s
    Telnet.Read Until    GNU GRUB
    ${move}=    GRUB get menu position
    ...    ${menu_entry}    ${reference_str}    ${rs_offset}    sleep=1s
    ${grub_key}=    Set Variable If    ${move} < 0    ${grub_key_up}    ${grub_key}
    : FOR    ${INDEX}    IN RANGE    0    ${move.__abs__()}
    \   Telnet.Write Bare   ${grub_key}
    \   Sleep    0.5s
    Telnet.Write Bare    \n

Gather and install meta-trenchboot artifacts
    [Documentation]    TODO
    [Arguments]    ${install_device}    ${artifacts_link}
    ${bmap_file}=    Set Variable   tb-minimal-efi-image-genericx86-64.wic.bmap
    ${gz_file}=    Set Variable    tb-minimal-efi-image-genericx86-64.wic.gz
    Telnet.Execute Command    cd /tmp
    Telnet.Execute Command    echo 'nameserver 1.1.1.1' > /etc/resolv.conf
    Telnet.Execute Command    wget -O unzip https://cloud.3mdeb.com/index.php/s/3gikLqy6B68HaJ8/download
    Telnet.Execute Command    chmod +x unzip
    Telnet.Execute Command    wget -O artifacts.zip ${artifacts_link}
    Telnet.Execute Command    ./unzip artifacts.zip && cd artifacts-uefi
    ${log}=    Telnet.Execute Command
    ...    bmaptool copy --bmap ${bmap_file} ${gz_file} ${install_device}
    Should Contain    ${log}    bmaptool: info: copying time

Boot From Storage Device
    [Arguments]    ${dev}
    Enter BIOS
    Boot Menu Choose Entry    ${dev}
