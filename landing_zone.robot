*** Settings ***
Library     SSHLibrary    timeout=90 seconds
Library     Telnet    timeout=20 seconds    connection_timeout=120 seconds
Library     Process
Library     OperatingSystem
Library     String
Library     RequestsLibrary
Library     Collections

Suite Setup       Run Keywords    Prepare Test Suite
...                               Check If iPXE Is Enabled
Suite Teardown    Log Out And Close Connection
Test Teardown     Run Keyword If Test Failed    Check CPU temp

Resource    ../rtectrl-rest-api/rtectrl.robot
Resource    ../snipeit-rest-api/snipeit-api.robot
Resource    ../variables.robot
Resource    ../keywords.robot

*** Keywords ***

Cursor Up
    ${ctrl_p}    Evaluate    chr(int(16))
    Telnet.Write    ${ctrl_p}
    Telnet.Read

Cursor Down
    ${ctrl_n}    Evaluate    chr(int(14))
    Telnet.Write    ${ctrl_n}
    Telnet.Read

*** Test Cases ***

LZ1.1 Verify content of grub.cfg file
    # https://github.com/pcengines/apu2-documentation/issues/64
    # Sometimes platform hangs, hard reset is required
    Power On
    Serial root login Linux    nixos
    ${log}=    Telnet.Execute Command    cat /boot/grub/grub.cfg
    ${status}=    Run Keyword And Return Status    Should Contain
    ...           ${log}    menuentry "NixOS - Secure Launch"
    Should Be True    ${status}    Error: There is no Secure Launch entry
    ${entry}=    Fetch From Right    ${log}    "NixOS - Secure Launch"
    ${status}=    Run Keyword And Return Status    Should Contain
    ...           ${entry}    slaunch skinit
    Should Be True    ${status}    Error: There is no slaunch skinit
    ${status}=    Run Keyword And Return Status    Should Contain
    ...           ${entry}    slaunch_module ($drive2)/boot/lz_header
    Should Be True    ${status}    Error: There is no slaunch module

LZ1.2 Compare bootlog with DRTM and without DRTM
    Power On
    # TBD Entering GRUB and selecting "NixOS - Default"
    ${log}=    Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Not Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is ${case} in boot info
    # TBD Entering GRUB and selecting "NixOS - Secure Launch"
    ${log}=    Read Until    Booting the kernel.
    :FOR    ${case}    IN     @{boot_info_list}
    \    ${status}=    Run Keyword And Return Status    Should Contain
    ...   ${log}    ${case}
    \    Should Be True    ${status}    Error: There is no ${case} in boot info

LZ1.3 Check if LZ utilizes SHA256 algorithm when using TPM2.0 module
    Power On
    # TBD Entering GRUB and selecting "NixOS - Secure Launch"
    Serial root login Linux    nixos
    ${log_pcr}=    Telnet.Execute Command    tpm2_pcrread
