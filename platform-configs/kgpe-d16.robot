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
${net_boot_key}            n
${net_boot_string}         Booting from ROM
${sol_string}              DRAM
${sn_pattern}              ^\\d{7}$
${manufacturer}            ASUS
${cpu}                     AMD Opetron 6282SE

# Regression test flags
${iPXE_config_support}     ${True}
