﻿<#
.Synopsis
Inventory for Azure SQLDB

.DESCRIPTION
This script consolidates information for all microsoft.sql/servers/databases resource provider in $Resources variable. 
Excel Sheet Name: SQLDB

.Link
https://github.com/microsoft/ARI/Modules/Data/SQLDB.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.0.1
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle) 

if ($Task -eq 'Processing') {

    $SQLDB = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }

    if($SQLDB)
        {
            $tmp = @()

            foreach ($1 in $SQLDB) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $DBServer = $1.id.split("/")[8]
                $PoolId = [string]$data.elasticPoolId.split("/")[10]

                $RestorePoint = [string](get-date($data.earliestrestoredate))
                
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                         = $1.id;
                            'Subscription'               = $sub1.Name;
                            'Resource Group'             = $1.RESOURCEGROUP;
                            'Name'                       = $1.NAME;
                            'Location'                   = $1.LOCATION;
                            'Database Server'            = $DBServer;
                            'Default Secondary Location' = $data.defaultSecondaryLocation;
                            'Status'                     = $data.status;
                            'Availability Zone'          = $data.availabilityzone;
                            'Earliest Restore Point'     = $RestorePoint;
                            'Min DTU Capacity'           = $data.minCapacity;
                            'DTU Capacity'               = $data.currentSku.capacity;
                            'Service Tier'               = $data.currentSku.tier;
                            'Hardware Configuration'     = $data.currentsku.name;
                            'Zone Redundant'             = $data.zoneRedundant;
                            'Catalog Collation'          = $data.catalogCollation;
                            'Read Replica Count'         = $data.readReplicaCount;
                            'Data Max Size (GB)'         = (($data.maxSizeBytes / 1024) / 1024) / 1024;
                            'Resource U'                 = $ResUCount;
                            'ElasticPool ID'             = $PoolId;
                            'Tag Name'                   = [string]$Tag.Name;
                            'Tag Value'                  = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }               
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLDB) {

        $TableName = ('SQLDBTable_'+($SmaResources.SQLDB.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Database Server')
        $Exc.Add('Default Secondary Location')
        $Exc.Add('Status')
        $Exc.Add('Availability Zone')
        $Exc.Add('Min DTU Capacity')
        $Exc.Add('DTU Capacity')
        $Exc.Add('Service Tier')
        $Exc.Add('Hardware Configuration')
        $Exc.Add('Data Max Size (GB)')
        $Exc.Add('Zone Redundant')
        $Exc.Add('Catalog Collation')
        $Exc.Add('Read Replica Count')
        $Exc.Add('ElasticPool ID')
        
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.SQLDB 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL DBs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}
