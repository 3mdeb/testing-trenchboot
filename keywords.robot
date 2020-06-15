*** Keywords ***

Serial setup
    [Documentation]    Setup serial communication via telnet. Takes host and
    ...                ser2net port as an arguments.
    [Arguments]    ${host}    ${s2n_port}
    # provide ser2net port where serial was redirected
    Telnet.Open Connection    ${host}    port=${s2n_port}    newline=LF    terminal_emulation=yes    terminal_type=VT102    window_size=80x24
    # remove encoding setup for terminal emulator pyte
    # Telnet.Set Encoding    errors=ignore
    Set Timeout    15

iPXE shell
    [Documentation]    Enter iPXE shell if network booting is enabled.
    # find string indicating network booting is enabled
    Telnet.Set Timeout    30s
    Telnet.Read Until    ${ipxe_string2}
    Sleep    0.1s
    # use n/N to enter network boot menu
    Telnet.Write Bare    ${net_boot_key}
    Telnet.Read Until    ${net_boot_string}
    # autoboot
    Telnet.Read Until    ${ipxe_string}
    # move arrow up to choose iPXE shell position
    # https://github.com/pcengines/apu2-documentation/blob/master/ipxe/menu.ipxe
    Telnet.Write Bare    ${ipxe_key}
    Wait Until Keyword Succeeds    3x    2s    iPXE wait for prompt

iPXE dhcp
    [Documentation]    Request IP address in iPXE shell. Takes network port
    ...                number as an argument, which by default is set to 0.
    [Arguments]    ${net_port}=0
    # request IP address
    Telnet.Set Timeout    30s
    Telnet.Write Bare    dhcp net${net_port}\n    0.1
    Telnet.Read Until    Configuring
    Telnet.Read Until    ok
    Telnet.Read Until    iPXE>

iPXE wait for prompt
    [Documentation]    Waits until iPXE prompt.
    # press enter
    Telnet.Write Bare    \n    0.1
    # make sure we are inside iPXE shell
    Telnet.Read Until    iPXE>

iPXE menu
    [Documentation]    Enter iPXE menu. Takes PXE IP addres, http port number,
    ...                ipxe filename nad network port number as an arguments.
    [Arguments]    ${pxe_address}    ${filename}    ${net_port}=0
    ...            ${read_until}=iPXE boot menu
    Set Timeout    30
    Wait Until Keyword Succeeds    3x    2s    iPXE dhcp    ${net_port}
    # download and run menu
    Telnet.Write Bare    chain http://${pxe_address}/${filename}\n    0.1
    # wait for custom string from pxe-server
    Telnet.Read Until    ${read_until}
    #Telnet.Write Bare    \x1b[B

Write Bare Checking Every Letter
    [Documentation]    Splits string into characters and writes each of them
    ...                individually, for each checking if it was received before
    ...                moving to next
    [Arguments]    ${string}
    @{characters}=    Split String To Characters    ${string}
    Telnet.Read
    :FOR    ${c}    IN    @{characters}
    \    Write Letter Until Successful    ${c}

Write Letter Until Successful
    [Documentation]    Tries to write a letter, checking if it was properly
    ...                received and retrying if not
    [Arguments]    ${c}    ${iterations}=10
    :FOR    ${_}    IN RANGE    1    ${iterations}
    \    Telnet.Write Bare    ${c}
    \    Sleep    0.5s
    \    ${ret}=    Telnet.Read
    \    ${check}=    Evaluate    """${c}""" in """${ret}"""
    \    Run Keyword If    ${check}    Return From Keyword

iPXE get menu position
    [Documentation]    Evaluate and return relative menu entry position
    ...                described in the argument.
    [Arguments]    ${entry}
    ${output}=    Telnet.Read Until    iPXE boot menu end
    Log    ${output}
    # enumerate output buffer lines and find line number which contain string
    ${ipxe_shell_line}=    Get Line Number Containing String    ${output}    ipxe shell
    ${entry_line}=    Get Line Number Containing String    ${output}    ${entry}
    ${rel_pos}=    Evaluate    ${entry_line} - ${ipxe_shell_line}
    Log    ${rel_pos}
    [Return]    ${rel_pos}

iPXE boot entry
    [Documentation]    Enter specified in argument iPXE menu entry.
    [Arguments]    ${menu_entry}
    Set Timeout    30
    ${move}=    iPXE get menu position    ${menu_entry}
    : FOR    ${INDEX}    IN RANGE    0    ${move}
    \   Telnet.Write Bare    \x1b[B    0.1
    \   Sleep    0.5s
    Telnet.Write Bare    \n

GRUB get menu position
    [Documentation]    Evaluate and return relative menu entry position
    ...                described in the argument.
    [Arguments]    ${entry}    ${reference_str}    ${rs_offset}
    Sleep    5s
    ${output}=    Telnet.Read
    Log    ${output}
    # enumerate output buffer lines and find line number which contain string
    ${gnu_header}=    Get Line Number Containing String    ${output}    ${reference_str}
    ${entry_line}=    Get Line Number Containing String    ${output}    ${entry}
    ${rel_pos}=    Evaluate    ${entry_line} - ${gnu_header} - ${rs_offset}
    Log    ${rel_pos}
    [Return]    ${rel_pos}

GRUB boot entry
    [Documentation]    Enter specified in argument iPXE menu entry. By default
    ...                menu entry is presumed to be under the reference string
    ...                so that the move value is positive and default grub_key
    ...                moving down in the menu is used. Otherwise, if the value
    ...                is negative, grub_key is switched to grub_key_up.
    [Arguments]    ${menu_entry}    ${reference_str}    ${rs_offset}
    ${move}=    GRUB get menu position    ${menu_entry}    ${reference_str}    ${rs_offset}
    ${grub_key}=    Set Variable If    ${move} < 0    ${grub_key_up}    ${grub_key}
    : FOR    ${INDEX}    IN RANGE    0    ${move.__abs__()}
    \   Telnet.Write Bare   ${grub_key}
    \   Sleep    0.5s
    Telnet.Write Bare    \n

Open Connection And Log In
    [Documentation]    Open SSH connection and login to session. Setup RteCtrl
    ...                REST API and serial connection 
    SSHLibrary.Set Default Configuration    timeout=60 seconds
    SSHLibrary.Open Connection    ${rte_ip}    prompt=~#
    SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    REST API Setup    RteCtrl
    Serial setup    ${rte_ip}    ${rte_s2n_port}

Log Out And Close Connection
    [Documentation]    Close all opened SSH, serial connections
    SSHLibrary.Close All Connections
    Telnet.Close All Connections

Enter SeaBIOS
    [Documentation]    Enter SeaBIOS with key specified in platform-configs.
    # waiting for SeaBIOS boot menu enter string may be delayed by xHCI init
    # set longer timeout to prevent test failure
    Telnet.Set Timeout    60s
    Telnet.Read Until    ${seabios_string}
    Telnet.Write Bare    ${seabios_key}

Enter SeaBIOS And Return Menu
    [Documentation]    Enter SeaBIOS and returns boot entry menu.
    Enter SeaBIOS
    ${menu}=    Telnet.Read Until    ${payload_string}
    [Return]    ${menu}

Enter iPXE
    [Documentation]    Enter iPXE after device power cutoff.
    # TODO:   2 methods for entering iPXE (Ctrl-B and SeaBIOS)
    # TODO2:  problem with iPXE string (e.g. when 3 network interfaces are available)
    Enter SeaBIOS
    Sleep    0.5s
    ${setup}=    Telnet.Read
    ${lines}=    Get Lines Matching Pattern    ${setup}    ${ipxe_boot_entry}
    Telnet.Write Bare    ${lines[0]}
    Telnet.Read Until    ${ipxe_string}
    Telnet.Write Bare    ${ipxe_key}
    iPXE wait for prompt

Enter sortbootorder
    [Documentation]    Enter sortbootorder menu payload and return menu output.
    Enter SeaBIOS
    ${setup}=    Telnet.Read Until    Payload [setup]
    #${setup_pos}=    Evaluate    int(${setup.split()[-3][0]})
    Telnet.Write Bare    ${setup.split()[-3][0]}
    ${output}=    Telnet.Read Until    s Save configuration and exit
    [Return]    ${output}

Toggle sortbootorder option
    [Documentation]    Toggle sortbootorder menu option specified in the
    ...                argument. Returns sortbootorder output.
    [Arguments]    ${lines}
    Log    ${lines.split()}
    Telnet.Write Bare    ${lines.split()[0][0]}
    ${output}=    Telnet.Read Until    s Save configuration and exit
    [Return]    ${output}

Toggle and check sortbootorder option
    [Documentation]    Toggle sortbootorder option specified in the first
    ...                argument and check operation result with 2nd and 3rd
    ...                arguments.
    [Arguments]    ${lines}    ${option_str}    ${expected_status}
    ${output}=    Toggle sortbootorder option    ${lines}
    ${lines}=    Get Lines Containing String    ${output}    ${option_str}
    ${res}=    Evaluate    "${option_str} - Currently ${expected_status}" in """${lines}"""
    [Return]    ${res}

Verify option change
    [Documentation]    Fails test if sortbootorder option toggle keyword returns
    ...                false, otherwise save configuration and exit sortbootorder.
    [Arguments]    ${lines}    ${option_str}    ${expected_status}
    ${res}=    Toggle and check sortbootorder option    ${lines}    ${option_str}    ${expected_status}
    Run Keyword If    ${res}    Telnet.Write Bare    s
    Run Keyword Unless    ${res}    Fail

Enable sortbootorder option
    [Documentation]    Enable sortbootorder option specified in the argument and
    ...                verify option status or exit without saving based on
    ...                sortbootorder menu output.
    [Arguments]    ${option_str}
    ${output}=    Enter sortbootorder
    ${lines}=    Get Lines Containing String    ${output}    ${option_str}
    ${res}=    Evaluate    "${option_str} - Currently Enabled" in """${lines}"""
    Run Keyword If    ${res}    Telnet.Write Bare    x
    Run Keyword Unless    ${res}    Verify option change    ${lines}    ${option_str}    Enabled

Disable sortbootorder option
    [Documentation]    Disable sortbootorder option specified in the argument
    ...                and verify option status or exit without saving based on
    ...                sortbootorder menu output.
    [Arguments]    ${option_str}
    ${output}=    Enter sortbootorder
    ${lines}=    Get Lines Containing String    ${output}    ${option_str}
    ${res}=    Evaluate    "${option_str} - Currently Disabled" in """${lines}"""
    Run Keyword If    ${res}    Telnet.Write Bare    x
    Run Keyword Unless    ${res}    Verify option change    ${lines}    ${option_str}    Disabled

Enable iPXE
    [Documentation]    Enable network booting option in sortbootorder.
    Enable sortbootorder option    Network/PXE boot

Disable iPXE
    [Documentation]    Disable network boting option in sortbootorder.
    Disable sortbootorder option    Network/PXE boot

Get firmware version from binary
    [Documentation]    Return firmware version from binary file sent via SSH to
    ...                RTE system. Takes binary file path as an argument.
    [Arguments]    ${binary_path}
    ${coreboot_version1}=    SSHLibrary.Execute Command    strings ${binary_path}|grep COREBOOT_ORIGIN_GIT_TAG|cut -d" " -f 3|tr -d '"'
    ${coreboot_version2}=    SSHLibrary.Execute Command    strings ${binary_path}|grep CONFIG_LOCALVERSION|cut -d"=" -f 2|tr -d '"'
    ${coreboot_version3}=    SSHLibrary.Execute Command    strings ${binary_path}|grep -w COREBOOT_VERSION|cut -d" " -f 3|tr -d '"'
    ${version_length1}=    Get Length    ${coreboot_version1}
    ${coreboot_version}=    Set Variable If    ${version_length1} == 0    ${coreboot_version2}    ${coreboot_version1}
    ${version_length}=    Get Length    ${coreboot_version}
    ${coreboot_version}=    Set Variable If    ${version_length} == 0    ${coreboot_version3}    ${coreboot_version}
    [Return]    ${coreboot_version}

Get firmware version
    [Documentation]    Return firmware version via Debian booted from iPXE.
    Boot Flashing Tools for Apu2 from iPXE    boot.3mdeb.com    menu.ipxe
    ...                                       Flashing tools for Apu2
    ${output}=    Telnet.Execute Command    dmidecode -t bios
    ${version}=    Get Lines Containing String    ${output}    Version:
    [Return]    ${version.split()[1]}

Get current CONFIG start index
    [Documentation]    Return current CONFIG start index from CONFIG_LIST
    ...                specified in the argument required for slicing list.
    ...                Return -1 if CONFIG not found in variables.robot.
    [Arguments]    ${config_list}
    ${rte_cpuid}=    Get current RTE param    cpuid
    Should Not Be Equal    ${rte_cpuid}    ${-1}    msg=RTE not found in hw-matrix
    ${index} =    Set Variable    ${0}
    :FOR    ${config}    IN    @{config_list}
    \    ${result}=    Evaluate    ${config}.get("cpuid")
    \    Return From Keyword If   '${result}'=='${rte_cpuid}'    ${index}
    \    ${index} =    Set Variable    ${index + 1}
    Return From Keyword    ${-1}

Get current CONFIG stop index
    [Documentation]    Return current CONFIG stop index from CONFIG_LIST
    ...                specified in the argument required for slicing list.
    ...                Return -1 if CONFIG not found in variables.robot.
    [Arguments]    ${config_list}    ${start}
    ${length}=    Get Length    ${config_list}
    ${index} =    Set Variable    ${start + 1}
    :FOR    ${config}    IN    @{config_list[${index}:]}
    \    ${result}=    Evaluate    ${config}.get("cpuid")
    \    Return From Keyword If   '${result}'!='None'    ${index}
    \    Return From Keyword If   '${index}'=='${length - 1}'    ${index + 1}
    \    ${index} =    Set Variable    ${index + 1}
    Return From Keyword    ${-1}

Get current CONFIG
    [Documentation]    Return current config as a list variable based on start
    ...                and stop indexes.
    [Arguments]    ${config_list}
    ${start}=    Get current CONFIG start index    ${CONFIG_LIST}
    Should Not Be Equal    ${start}    ${-1}    msg=Current CONFIG not found in hw-matrix
    ${stop}=    Get current CONFIG stop index    ${CONFIG_LIST}    ${start}
    Should Not Be Equal    ${stop}    ${-1}    msg=Current CONFIG not found in hw-matrix
    ${config}=    Get Slice From List    ${config_list}    ${start}    ${stop}
    [Return]    ${config}

Get current CONFIG item
    [Documentation]    Return current CONFIG item specified in the argument.
    ...                Return -1 if CONFIG item not found in variables.robot.
    [Arguments]    ${item}
    ${config}=    Get current CONFIG    ${CONFIG_LIST}
    ${length}=    Get Length    ${config}
    Should Be True    ${length} > 1
    :FOR    ${element}    IN    @{config[1:]}
    \    Return From Keyword If    '${element.type}'=='${item}'    ${element}
    Return From Keyword    ${-1}

Get current CONFIG item param
    [Documentation]    Return current CONFIG item parameter specified in the
    ...                arguments.
    [Arguments]    ${item}    ${param}
    ${device}=    Get current CONFIG item    ${item}
    [Return]    ${device.${param}}

Get current RTE
    [Documentation]    Return RTE index from RTE list taken as an argument.
    ...                Return -1 if CPU ID not found in variables.robot.
    [Arguments]    @{rte_list}
    ${cpuid}=    SSHLibrary.Execute Command    cat /proc/cpuinfo |grep Serial|cut -d":" -f2|tr -d " "
    ${index} =    Set Variable    ${0}
    :FOR    ${item}    IN    @{rte_list}
    \    Return From Keyword If    '${item.cpuid}' == '${cpuid}'    ${index}
    \    ${index} =    Set Variable    ${index + 1}
    Return From Keyword    ${-1}

Get current RTE param
    [Documentation]    Return current RTE parameter value specified in the argument.
    [Arguments]    ${param}
    ${idx}=    Get current RTE    @{RTE_LIST}
    Should Not Be Equal    ${idx}    ${-1}    msg=RTE not found in hw-matrix
    &{rte}=    Get From List    ${RTE_LIST}    ${idx}
    [Return]    &{rte}[${param}]

Flash firmware
    [Documentation]    Flash platform with firmware file specified in the
    ...                argument. Keyword fails if file size doesn't match target
    ...                chip size.
    [Arguments]    ${fw_file}
    ${file_size}=    Run    ls -l ${fw_file} | awk '{print $5}'
    Run Keyword If    '${file_size}'!='${flash_size}'     Fail    Image size doesn't match the flash chip's size!
    Put File    ${fw_file}    /tmp/coreboot.rom
    Sleep    2s
    ${platform}=    Get current RTE param    platform
    Run Keyword If    '${platform[:4]}' == 'apu1'    Flash apu1
    ...    ELSE IF    '${platform[:3]}' == 'apu'    Flash apu
    ...    ELSE    Fail    Unknown platform ${platform}

Prepare Test Suite
    [Documentation]    Keyword prepares Test Suite by importing specific
    ...                platform configuration keywords and variables, opening
    ...                SSH and serial connections, setting current platform to
    ...                global variable and setting Device Under Test to start
    ...                state. Keyword used in all [Suite Setup] sections.
    Run Keyword If   '${config[:4]}' == 'apu2'    Run Keywords    Import Resource
    ...        ${CURDIR}/platform-configs/apu2.robot
    ...        AND    Set Library Search Order    apu2
    ...    ELSE IF   '${config[:6]}' == 'asrock'  Run Keywords    Import Resource
    ...        ${CURDIR}/platform-configs/asrock-r1000v.robot
    ...        AND    Set Library Search Order    asrock-r1000v
    ...    ELSE IF    '${config[:10]}' == 'supermicro'    Run Keywords    Import Resource
    ...        ${CURDIR}/platform-configs/supermicro-m11sdv-8ct-ln4f.robot
    ...        AND    Set Library Search Order    supermicro-m11sdv-8ct-ln4f
    Run Keyword If   '${dev_type}' not in ['auto', 'None']
    ...               Set Storage Device Number And Type

    Open Connection And Log In
    ${platform}=    Get current RTE param    platform
    Set Global Variable    ${platform}
    Get DUT To Start State

Set Storage Device Number And Type
    ${dev_number}=    Evaluate    int(${dev_type[3:]})
    ${dev_type}=      Evaluate    '${dev_type[:3]}'
    Set Suite Variable    ${dev_type}
    Set Suite Variable    ${dev_number}

Get DUT To Start State
    [Documentation]    Clear telnet buffer and get Device Under Test to start
    ...                state (RTE Relay On).
    Telnet.Read
    ${result}=    Get Relay State
    Run Keyword If    '${result}'=='low'    RteCtrl Relay

Check If iPXE Is Enabled
    [Documentation]    Enable iPXE if network booting is disabled. Do nothing if
    ...                current config doesn't equal apuX.
    Return From Keyword If    not ${iPXE_config_support}
    Log To Console    \nEnabling iPXE boot option ...\n
    Power On
    Enable iPXE

Power Cycle On
    [Documentation]    Clear telnet buffer and perform full power cycle with RTE
    ...                relay set to ON.
    Telnet.Read
    ${result}=    RteCtrl Relay
    Sleep    1s
    Run Keyword If   ${result}==0  run keywords
    ...    Sleep    4s
    ...    AND      RteCtrl Relay

Power Cycle Off
    [Documentation]    Clear telnet buffer and perform full power cycle with RTE
    ...                relay set to OFF.
    # sleep for DUT Start state in Suite Setup
    Sleep    1s
    # clear buffer
    Telnet.Read
    ${result}=    RteCtrl Relay
    Sleep    1s
    Run Keyword If   ${result}==1  RteCtrl Relay

Get Relay State
    [Documentation]    Return RTE relay state through REST API.
    ${state}=    RteCtrl Get GPIO State    0
    [Return]    ${state}

Boot from Hard-Disk
    [Documentation]    Boots system from Hard-Disk. By deafult the variable
    ...    ${hard_disk} is Hard-Disk. It can be specified by adding an argument.
    [Arguments]    ${hard_disk}=Hard-Disk
    ${menu}=    Enter SeaBIOS And Return Menu
    ${line}=    Get Lines Containing String    ${menu}    ${hard_disk}
    ${lines_count}=    Get Line Count    ${line}
    Run Keyword If    '${lines_count}'=='0'    Fail    ${hard_disk} not detected
    @{characters}=    Split String To Characters    ${line}
    Telnet.Write Bare    ${characters[0]}

Boot from USB
    [Documentation]    Boots system from USB. By deafult the variable
    ...    ${usb} is USB. It can be specified by adding an argument.
    [Arguments]    ${usb}=USB
    ${menu}=    Enter SeaBIOS And Return Menu
    ${line}=    Get Lines Containing String    ${menu}    ${usb}
    ${lines_count}=    Get Line Count    ${line}
    Run Keyword If    '${lines_count}'=='0'    Fail    ${usb} not detected
    @{characters}=    Split String To Characters    ${line}
    Telnet.Write Bare    ${characters[0]}

Boot from SD Card
    [Documentation]    Boots system from SD Card. By deafult the variable
    ...    ${sd_card} is SD card. It can be specified by adding an argument.
    [Arguments]    ${sd_card}=SD card
    ${sd_card}=    Set Variable If  '${platform[:4]}' == 'apu5'    Multiple Card${SPACE}${SPACE}Reader    SD card
    ${menu}=    Enter SeaBIOS And Return Menu
    ${line}=    Get Lines Containing String    ${menu}    ${sd_card}
    ${lines_count}=    Get Line Count    ${line}
    Run Keyword If    '${lines_count}'=='0'    Fail    ${sd_card} not detected
    @{characters}=    Split String To Characters    ${line}
    Telnet.Write Bare    ${characters[0]}

Gather and install meta-trenchboot artifacts
    [Documentation]    TODO
    [Arguments]    ${install_device}    ${artifacts_link}
    ${bmap_file}=    Set Variable    tb-minimal-image-pcengines-apu2.wic.bmap
    ${gz_file}=    Set Variable    tb-minimal-image-pcengines-apu2.wic.gz
    Telnet.Execute Command    cd /tmp
    Telnet.Execute Command    wget -O artifacts.zip ${artifacts_link}
    Telnet.Execute Command    unzip artifacts.zip && cd artifacts
    Telnet.Execute Command    bmaptool copy --bmap ${bmap_file} ${gz_file} ${install_device}

Boot From Storage Device
    [Arguments]    ${dev_type}
    Run Keyword If    '${dev_type}'=='SSD'    Boot From Hard-Disk
    ...    ELSE IF    '${dev_type}'=='HDD'    Boot From Hard-Disk
    ...    ELSE IF    '${dev_type}'=='USB'    Boot From USB
    ...    ELSE IF    '${dev_type}'=='SDC'    Boot From SD Card
    ...    ELSE IF    '${dev_type}'=='None'   Return From Keyword

Choose Device Type
    Set Global Variable    ${dev_number}    0
    ${conf}=    Get Current CONFIG    ${CONFIG_LIST}
    :FOR    ${s}    in    @{STORAGE_PRIORITY}
    \    Run Keyword If    '${s}' in [c['type'] for c in ${conf[1:]}]
    ...    Run Keywords    Set Suite Variable   ${dev_type}   ${s.rstrip('_Storage')}
    ...    AND             Exit For Loop

Increment Device File
    [Documentation]    Naive implementation of block device file incrementation
    [Arguments]    ${dev_file}
    ${dev_file}=    Evaluate   '${dev_file[:-1]}' + chr(ord('${dev_file[-1]}')+${dev_number})
    [Return]    ${dev_file}

Choose Device File
    ${fdisk_l}=    Telnet.Execute Command    fdisk -l
    ${dev_file}=    Set Variable If
    ...             '${dev_type}'=='SSD'    /dev/sda
    ...             '${dev_type}'=='HDD'    /dev/hda
    ...             '${dev_type}'=='USB'    /dev/sda
    ...             '${dev_type}'=='SDC'    /dev/mmcblk0
    ${dev_file}=    Increment Device File   ${dev_file}
    Should Contain    ${fdisk_l}    ${dev_file}
    ...    msg=\nThere's no storage device: ${dev_file}
    Set Suite Variable    ${dev_file}

Choose Storage Device For Install
    [Documentation]    Checks for available storage devices in Config and
    ...                directly on the machine to choose which one should be
    ...                used for TB image installation. If dev_type==auto
    ...                choice will be made in order: SSD->HDD->USB->SDC
    ...                If dev_file==auto first of a type is chosen eg. /dev/sda
    ...                Device file may be incremented, eg. HDD1 -> /dev/hdb
    Run Keyword If    '${dev_type}'=='auto'    Choose Device Type
    Run Keyword If    '${dev_file}'=='auto'    Choose Device File
    Log To Console    \ndev_type:${dev_type}, dev_file:${dev_file}, dev_number:${dev_number}

Should Contain All
    [Arguments]    ${log}    @{params}
    :FOR    ${param}    IN    @{params}
    \    Should Contain    ${log}    ${param}
