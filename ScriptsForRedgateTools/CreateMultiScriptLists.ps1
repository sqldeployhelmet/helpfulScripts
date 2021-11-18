<#
    This script will query for registered servers and create server lists to import
    into SQL Multiscript.

    Author:     josh smith
    Created:    2021-11-14
#>
Function Out-MultiScriptImportFile ([Object]$ServersList, [Object]$ServerGroup,
    [string]$ExportPath, [Int16]$GroupType) {

    switch ($GroupType) {
        1 {
            $TempList = $SQLServersList | Where-Object { $_.Source -eq $ServerGroup.Source }
            $ListName = $ServerGroup.Source
            break
        }
        2 {
            $TempList = $SQLServersList | Where-Object { $_.Group -eq $ServerGroup.Group }
            $ListName = $ServerGroup.Group
            break
        }
        3 {
            $TempList = $SQLServersList
            $ListName = 'All Servers'
        }
        default { throw "Unknown ServerGroup type: expected values are 1, 2 or 3" }
    }

    # ditch invalid file name characters from the list name:
    $ListName = $ListName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

    $FileHeader = '<?xml version="1.0" encoding="utf-16" standalone="yes"?>
<!--
SQL Multi Script
SQL Multi Script
Version:1.4.16.1316-->
<databaseListsFile version="1" type="databaseListsFile">
  <databaseLists type="List_databaseList" version="1">
    <value version="2" type="databaseList">
    '

    $ListHeader = "      <name>$ListName</name>
    <databases type=`"BindingList_database`" version=`"1`">"

    # Add an entry for each server in the list:
    foreach ($t in $TempList) {

        $SQLInstance = $t.ServerName
        $SQLServerName = $t.Name
        $body = $body + 
        "        <value version=`"6`" type=`"database`">
                    <name>master</name>
                    <server>$SQLInstance</server>
                    <integratedSecurity>True</integratedSecurity>
                    <connectionTimeout>15</connectionTimeout>
                    <protocol>-1</protocol>
                    <packetSize>4096</packetSize>
                    <encrypted>False</encrypted>
                    <selected>True</selected>
                    <cserver>$SQLServerName</cserver>
                    <readonly>False</readonly>
                </value>
        "
    }

    $guid = New-Guid

    $FileFooter = "      </databases>
    <guid>$guid</guid>
    </value>
    </databaseLists>
    </databaseListsFile>"

    $ListName = $ListName -replace ' ', '_'
    $filePath = $ExportPath + $ListName + ".smsdl"

    $data = $FileHeader + $ListHeader + $body + $FileFooter

    Out-File -FilePath $filePath -Encoding ASCII -InputObject $data -Force 
}

########################################################################################
# leave $RegServer null to use local server groups from SSMS and/or Azure Data Studio
$RegServer = $null
$ExportFolder = 'C:\Temp\'

$SQLServersList = Get-DBARegServer -SqlInstance $RegServer -IncludeSelf

# iterate through all the returned sources and create lists:
$Sources = $SQLServersList | Select-Object -Property Source -Unique
$Groups = $SQLServersList | Select-Object -Property Group -Unique

foreach ($s in $sources) {
    if ($null -ne $s) {

        Out-MultiScriptImportFile $SQLServersList $s $ExportFolder 1
    }
}

foreach ($g in $Groups) {
    if ($null -eq $g) {
        
        Out-MultiScriptImportFile $SQLServersList $g $ExportFolder 2
    }
}

Out-MultiScriptImportFile $SQLServersList $null $ExportFolder 3
