*** Keywords ***
# These keywords assume that SSH connection to the RTE is open and set as active
# and that sonoff ip is accessible from the RTE.

Sonoff Turn On
    [Arguments]    ${ip}
    SSHLibrary.Execute Command    wget -q -O - http://${ip}/switch/sonoff_s20_relay/turn_on --method=POST

Sonoff Turn Off
    [Arguments]    ${ip}
    SSHLibrary.Execute Command    wget -q -O - http://${ip}/switch/sonoff_s20_relay/turn_off --method=POST

Sonoff Toggle
    [Arguments]    ${ip}
    SSHLibrary.Execute Command    wget -q -O - http://${ip}/switch/sonoff_s20_relay/toggle --method=POST

Sonoff Get State
    [Documentation]    Return current state of sonoff swtich. Correct values are
    ...                "ON" and "OFF".
    [Arguments]    ${ip}
    ${s}=    SSHLibrary.Execute Command
    ...    wget -q -O - http://${ip}/switch/sonoff_s20_relay
    ${s}=    evaluate    json.loads('''${s}''')    json
    [Return]    ${s['state']}
