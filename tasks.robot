*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Desktop
Library             RPA.Browser.Selenium
Library             RPA.FTP
Library             RPA.HTTP
Library             RPA.JSON
Library             String
Library             Collections
Resource            Resource.robot


*** Tasks ***
api_key_post
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    POST    ${base_url}/api_key    headers=${header}
    ${api_key}=    Convert JSON to String    ${response.json()}
    Log To Console    ${response.status_code}
    IF    ${response.status_code} == 201
        Set Suite Variable    ${apikey}    ${api_key.replace('"', '')}
        Log To Console    ${apikey}
    END
    Should Be Equal As Strings    ${response.status_code}    201

Get Available Descriptor
    ${headers}=    Create Dictionary    accept=application/zip    VNF-LCM-KEY=${apikey}
    ${params}=    Create Dictionary    vnfdSpecification=SOL006
    ${response}=    GET    ${base_url}/emulator/vnfds    headers=${headers}    params=${params}
    Log To Console    ${response.content}
    Log To Console    ${response}

Creating VNF
    Log To Console    ${apikey}
    ${header}=    Create Dictionary
    ...    accept=application/json
    ...    Version=2.11.0
    ...    VNF-LCM-KEY=${apikey}
    ...    Content-Type=application/json
    Set Global Variable    ${header}
    ${data}=    evaluate    json.loads('''${json_body}''')    json
    ${response}=    POST    ${base_url}/vnf_instances    json=${json_body}    headers=${header}
    IF    ${response.status_code} == 201
        ${response_dictionary}=    Evaluate    json.loads('''${response.content}''')
        ${vnf_instance_id}=    Get From Dictionary    ${response_dictionary}    id
        Set Global Variable    $vnf_id    ${vnf_instance_id}
        Log To Console    ${vnf_instance_id}
        Log To Console    ${response.status_code}
    END
    Should Be Equal As Strings    ${response.status_code}    201

Instantiate VNF Instance
    ${flavour-id}=    Create Dictionary    flavourId=df-normal
    ${response}=    POST
    ...    ${base_url}/vnf_instances/${vnf_id}/instantiate
    ...    json=${flavour-id}
    # header passed From Creating VNF Instance
    ...    headers=${header}
    IF    ${response.status_code} == 202    Log To Console    ${response}
    Should Be Equal As Strings    ${response.status_code}    202

Terminate VNF Instance
    sleep    40
    ${terminationtype}=    Create Dictionary    terminationType=FORCEFUL
    ${response}=    POST
    ...    ${base_url}/vnf_instances/${vnf_id}/terminate
    ...    json=${terminationtype}
    ...    headers=${header}
    IF    ${response.status_code} == 202    Log To Console    ${response}
    Should Be Equal As Strings    ${response.status_code}    202

Delete VNF Instance
    
    Log To Console    ${apikey}
    ${header_delete}=    Create Dictionary
    ...    accept=*/*
    ...    Version=2.11.0
    ...    VNF-LCM-KEY=${apikey}
    ${url}=    Set Variable    ${base_url}/vnf_instances/${vnf_id}
    Create Session    VNFLCM    ${url}
    ${response}=    DELETE On Session    VNFLCM    url=${url}    headers=${header_delete}
    IF    ${response.status_code} == 204    Log To Console    ${response}
    Should Be Equal As Strings    ${response.status_code}    204

