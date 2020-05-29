*** Variables ***

${rte_s2n_port}            13541
${flash_size}              ${128*1024*1024}
${seabios_string}          F10
${seabios_key}             \x1b[23~
${payload_string}          Payload [setup]
${ipxe_boot_entry}         ?. iPXE
${ipxe_string}             Press F12 to boot from PXE/LAN
${ipxe_string2}            autoboot
${ipxe_key}                \x1b[23~   #\x7F
${net_boot_key}            n
${net_boot_string}         Booting from ROM
${sol_string}              DRAM
${sn_pattern}              ^\\d{7}$
${manufacturer}            Supermicro
${cpu}                     AMD EPYC 3201 SoC

# Regression test flags
${iPXE_config_support}     ${True}

*** Keywords ***

Power On
    Sleep    3s
    RteCtrl Power Off
    Sleep    1s
    # read the old output
    Telnet.Read
    RteCtrl Power On
