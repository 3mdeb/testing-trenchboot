*** Settings ***
Library     SSHLibrary    timeout=90 seconds
Library     Telnet    timeout=90 seconds
Library     Process
Library     OperatingSystem
Library     String
Library     RequestsLibrary
Library     Collections

Suite Setup       Run Keywords    Prepare Test Suite
...                               Check If iPXE Is Enabled
Suite Teardown    Log Out And Close Connection\

Resource    ../rtectrl-rest-api/rtectrl.robot
Resource    ../variables.robot
Resource    ../keywords.robot

*** Variables ***

@{pcrlist_no_drtm}   18 : ffff    17 : ffff    18 : 0000    17 : 0000

*** Test Cases ***

YOC1.1 Meta-trenchboot Yocto Install
    [Tags]    apu2    asrock    supermicro
    [Documentation]    Performs an installation of given meta-trenchboot image
    ...                on chosen platform
    Power On
    Boot from iPXE    ${pxe_address}    ${pxe_filename}
    ...               ${yoc_ipxe_option}

    Run Keyword If    '${platform}' in ('asrock', 'supermicro')    Run Keywords
    ...           Telnet.Set Timeout    90s
    ...    AND    Telnet.Set Prompt    root@debian:
    ...    AND    Telnet.Login    root    debian

    # Chosen device values are set as Suite Variables
    Choose Storage Device For Install
    Gather and install meta-trenchboot artifacts    ${install_disk}    ${artifacts_link}

YOC1.2 Boot Without DRTM
    [Tags]    apu2    asrock    supermicro
    [Documentation]    Boots into previously flashed image with DRTM disabled
    ...                option and performs checks related to DRTM function
    Power On
    Boot From Storage Device    ${boot_menu_entry}
    GRUB Boot Entry    boot    ${grub_reference_str}    ${grub_rs_offset}
    ${log}=    Telnet.Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{grub_boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Not Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is ${case} in boot info
    Sleep    45s
    Telnet.Read
    Telnet.Set Prompt    \~#
    Telnet.Execute Command    root
    ${pcrlist}=    Telnet.Execute Command    tpm2_pcrlist | tail -n 25
    Should Contain All    ${pcrlist}    @{pcrlist_no_drtm[:2]}

YOC1.3 Boot With DRTM
    [Tags]    apu2    asrock    supermicro
    [Documentation]    Boots into previously flashed image with DRTM enabled
    ...                option and performs checks related to DRTM function
    Power On
    Boot From Storage Device    ${boot_menu_entry}
    GRUB Boot Entry    secure-boot    ${grub_reference_str}    ${grub_rs_offset}
    ${log}=    Telnet.Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{grub_boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is no ${case} in boot info
    Sleep    45s
    Telnet.Read
    Telnet.Set Prompt    \~#
    Telnet.Execute Command    root
    ${pcrlist}=    Telnet.Execute Command    tpm2_pcrlist | tail -n 25
    Should Not Contain Any    ${pcrlist}    @{pcrlist_no_drtm}

YOC1.4 Verify If PCR Values Correspond To Manually Extended
    [Tags]    apu2    asrock    supermicro
    Power On
    Boot From Storage Device    ${boot_menu_entry}
    GRUB Boot Entry    secure-boot    ${grub_reference_str}    ${grub_rs_offset}
    Sleep    45s
    Telnet.Read
    Telnet.Set Prompt    \#
    Telnet.Execute Command    root

    Verify PCR Values
