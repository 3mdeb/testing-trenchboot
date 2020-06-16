*** Settings ***
Library     SSHLibrary    timeout=90 seconds
Library     Telnet    timeout=20 seconds
Library     Process
Library     OperatingSystem
Library     String
Library     RequestsLibrary
Library     Collections

Suite Setup       Prepare Test Suite
Suite Teardown    Log Out And Close Connection

Resource    ../rtectrl-rest-api/rtectrl.robot
Resource    ../variables.robot
Resource    ../keywords.robot

*** Keywords ***

Prepare fw_file
    ${file_name}=    Set Variable    ${platform}_${fw_version}.rom
    ${log}=    Run    wget -N https://3mdeb.com/open-source-firmware/pcengines/${platform}/${file_name}
    Run Keyword If    "ERROR 404: Not Found" in """${log}"""    Fail    Requested file not found on the FTP server.
    Set Test Variable    ${fw_file}    ${EXECDIR}/${file_name}

*** Test Cases ***

FCO1.1 Flash firmware and verify
    [Tags]    apu2
    ${file_exists}=    Run Keyword And Return Status   Variable Should Exist    ${fw_file}
    Run Keyword If    not ${file_exists} and "mainline" in """${config}"""
    ...    Fail    Flashing from FTP is not supported on ${config}
    Run Keyword If    not ${file_exists}    Prepare fw_file
    Flash firmware    ${fw_file}
    Run Keyword If    not ${file_exists}    OperatingSystem.Run    rm ${fw_file}
    Power Cycle On
    Check If iPXE Is Enabled
    # TBD, Flashing Tools Apu lack dmidecode
    #${version}=    Get firmware version
    #${coreboot_version}=    Get firmware version from binary    /tmp/coreboot.rom
    #Should Be Equal    ${coreboot_version}    ${version}
