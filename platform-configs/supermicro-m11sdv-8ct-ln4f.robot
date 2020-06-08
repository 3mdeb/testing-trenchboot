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
