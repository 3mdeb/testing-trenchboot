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
    [Tags]    apu2
    [Documentation]    Performs an installation of given meta-trenchboot image
    ...                on chosen platform
    Power On
    Boot from iPXE    ${pxe_address}    ${pxe_filename}
    ...               ${yoc_ipxe_option}

    Run Keyword If    '${platform}' in ('asrock', 'supermicro')   Login To Debian

    # Chosen device values are set as Suite Variables, used if install disk
    # & boot menu entry not set
    Choose Storage Device For Install
    Gather and install meta-trenchboot artifacts self hosted    /dev/sda    ${pxe_address}/tb/upstream/

YOC1.2 Boot With DRTM and run eventlog
    [Tags]    apu2
    [Documentation]    Boots into previously flashed image with DRTM enabled
    ...                option and performs checks related to DRTM function
    Power On
    Boot From Storage Device    AHCI/0: 30GB SATA Flash Drive ATA-11 Hard-Disk (28626 MiBytes)
    GRUB Boot Entry    secure-boot    ${grub_reference_str}    ${grub_rs_offset}
    ${log}=    Telnet.Read Until    Booting the kernel.
    Login To TB Minimal
    ${pcrlist}=    Telnet.Execute Command    tpm2_pcrlist | tail -n 25
    Log to Console    ${pcrlist}
    Should Not Contain Any    ${pcrlist}    @{pcrlist_no_drtm}
    Telnet.Execute Command    wget ${pxe_address}/tb/upstream/cbmem
    Telnet.Execute Command    chmod +x cbmem
    ${eventlog}=    Telnet.Execute Command    ./cbmem -d
    Log to Console    ${eventlog}
