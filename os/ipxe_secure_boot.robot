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

Resource    ../sonoffctrl.robot
Resource    ../rtectrl-rest-api/rtectrl.robot
Resource    ../variables.robot
Resource    ../keywords.robot

*** Variables ***

@{pcrlist_no_drtm}   18 : ffff    17 : ffff    18 : 0000    17 : 0000
@{ipxe_boot_info_list}    PCR extended    lz_main() is about to exit

*** Test Cases ***

PXE1.1 Boot From Ipxe Without DRTM
    [Tags]    asrock    supermicro
    [Documentation]    Boots ipxe on selected platform
    Power On
    Boot from iPXE    ${pxe_address}    tb/yocto/yocto.ipxe
    ${log}=    Telnet.Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{ipxe_boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Not Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is ${case} in boot info
    Sleep    10s
    Telnet.Set Timeout    180
    Telnet.Set Prompt    \#
    Sleep    60s
    Telnet.Read
    Telnet.Write    root
    Telnet.Read Until Prompt
    ${pcrlist}=    Telnet.Execute Command    tpm2_pcrlist | tail -n 25
    Should Contain All    ${pcrlist}    @{pcrlist_no_drtm[:2]}

PXE1.2 Boot From Ipxe With DRTM
    [Tags]    asrock    supermicro
    [Documentation]    Boots ipxe on selected platform
    Power On
    Boot from iPXE    ${pxe_address}    tb/yocto/yocto-lz.ipxe
    ${log}=    Telnet.Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{ipxe_boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is no ${case} in boot info
    Sleep    10s
    Telnet.Set Timeout    180
    Telnet.Set Prompt    \#
    Sleep    60s
    Telnet.Read
    Telnet.Write    root
    Telnet.Read Until Prompt
    ${pcrlist}=    Telnet.Execute Command    tpm2_pcrlist | tail -n 25
    Should Not Contain Any    ${pcrlist}    @{pcrlist_no_drtm}
