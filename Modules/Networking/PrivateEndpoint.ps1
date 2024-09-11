﻿<#
.Synopsis
Inventory for Azure Private Endpoint

.DESCRIPTION
This script consolidates information for all microsoft.network/privateendpoints and resource provider in $Resources variable. 
Excel Sheet Name: Private Endpoints

.Link
https://github.com/microsoft/ARI/Modules/Networking/PrivateEndpoint.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.2.1
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle, $Unsupported) 
If ($Task -eq 'Processing') {

    $PrivateEdp = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/privateendpoints' }
    $NICs = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/networkinterfaces' }

    if($PrivateEdp)
        {
            $tmp = @()

            foreach ($1 in $PrivateEdp) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                $VNET = if(![string]::IsNullOrEmpty($data.subnet.id)){$data.subnet.id.split('/')[8]}else{''}
                $Subnet = if(![string]::IsNullOrEmpty($data.subnet.id)){$data.subnet.id.split('/')[10]}else{''}

                if([string]::IsNullOrEmpty($data.customDnsConfigs.ipAddresses))
                    {
                        $NIC = $NICs | Where-Object {$_.id -eq $data.networkInterfaces.id}
                        $IPAddress = if ($NIC.properties.ipconfigurations.properties.privateipaddress.count -gt 1) { $NIC.properties.ipconfigurations.properties.privateipaddress | ForEach-Object { $_ + ' ,' } }else { $NIC.properties.ipconfigurations.properties.privateipaddress }
                        $IPAddress = [string]$IPAddress
                        $IPAddress = if ($IPAddress -like '* ,*') { $IPAddress -replace ".$" }else { $IPAddress }

                        $FQDN = if ($NIC.properties.ipconfigurations.properties.privatelinkconnectionproperties.fqdns.count -gt 1) { $NIC.properties.ipconfigurations.properties.privatelinkconnectionproperties.fqdns | ForEach-Object { $_ + ' ,' } }else { $NIC.properties.ipconfigurations.properties.privatelinkconnectionproperties.fqdns }
                        $FQDN = [string]$FQDN
                        $FQDN = if ($FQDN -like '* ,*') { $FQDN -replace ".$" }else { $FQDN }
                    }
                else
                    {
                        $IPAddress = if ($data.customDnsConfigs.ipAddresses.count -gt 1) { $data.customDnsConfigs.ipAddresses | ForEach-Object { $_ + ' ,' } }else { $data.customDnsConfigs.ipAddresses }
                        $IPAddress = [string]$IPAddress
                        $IPAddress = if ($IPAddress -like '* ,*') { $IPAddress -replace ".$" }else { $IPAddress }

                        $FQDN = if ($data.customDnsConfigs.fqdn.count -gt 1) { $data.customDnsConfigs.fqdn | ForEach-Object { $_ + ' ,' } }else { $data.customDnsConfigs.fqdn }
                        $FQDN = [string]$FQDN
                        $FQDN = if ($FQDN -like '* ,*') { $FQDN -replace ".$" }else { $FQDN }
                    }
                
                foreach ($Tag in $Tags) {     
                    $obj = @{
                        'ID'                              = $1.id;
                        'Subscription'                    = $sub1.Name;
                        'Resource Group'                  = $1.RESOURCEGROUP;
                        'Name'                            = $1.NAME;
                        'Location'                        = $1.LOCATION;
                        'VNET'                            = $VNET;
                        'Subnet'                          = $Subnet;
                        'Private Link Name'               = $data.privateLinkServiceConnections.name;
                        'Private Link Status'             = $data.privatelinkserviceconnections.properties.privateLinkServiceConnectionState.status;
                        'Private Link Resource Type'      = [string]$data.privatelinkserviceconnections.properties.groupids;
                        'Private Link Target Resource'    = [string]$data.privatelinkserviceconnections.properties.privatelinkserviceid;
                        'IP Address'                      = $IPAddress;
                        'FQDN'                            = $FQDN;
                        'Tag Name'                        = [string]$Tag.Name;
                        'Tag Value'                       = [string]$Tag.Value;
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }            
            }
            $tmp
        }
}
Else {
    if ($SmaResources.PrivateEndpoint) {

        $TableName = ('PvtEndpointTable_'+($SmaResources.PrivateEndpoint.id | Select-Object -Unique).count)
        $Style = @()
        $Style += New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('VNET')
        $Exc.Add('Subnet')
        $Exc.Add('Private Link Name')
        $Exc.Add('IP Address')
        $Exc.Add('FQDN')
        $Exc.Add('Private Link Status')
        $Exc.Add('Private Link Resource Type')
        $Exc.Add('Private Link Target Resource')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.PrivateEndpoint

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Private Endpoint' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -ConditionalText $condtxt -TableStyle $tableStyle -Style $Style
    
    }   
}