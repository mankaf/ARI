﻿<#
.Synopsis
Inventory for Azure Virtual Network

.DESCRIPTION
This script consolidates information for all microsoft.network/virtualnetworks and  resource provider in $Resources variable. 
Excel Sheet Name: VirtualNetwork

.Link
https://github.com/microsoft/ARI/Modules/Networking/VirtualNetwork.ps1

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

    $VirtualNetwork = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualnetworks' }

    if($VirtualNetwork)
        {
            $tmp = @()

            foreach ($1 in $VirtualNetwork) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $RetDate = ''
                $RetFeature = '' 
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}

                $AddrPool = if ($data.addressSpace.addressPrefixes.count -gt 1) { $data.addressSpace.addressPrefixes | ForEach-Object { $_ + ' ,' } }else { $data.addressSpace.addressPrefixes }
                $AddrPool = [string]$AddrPool
                $AddrPool = if ($AddrPool -like '* ,*') { $AddrPool -replace ".$" }else { $AddrPool }

                $DNSServers = if ($data.dhcpOptions.dnsServers.count -gt 1) { $data.dhcpOptions.dnsServers| ForEach-Object { $_ + ' ,' } }else { $data.dhcpOptions.dnsServers }
                $DNSServers = [string]$DNSServers
                $DNSServers = if ($DNSServers -like '* ,*') { $DNSServers -replace ".$" }else { $DNSServers }

                foreach ($2 in $data.subnets)
                    {
                        $ConsumedIPs = [int]$2.properties.ipConfigurations.id.count
                        $Prefixes = if(![string]::IsNullOrEmpty($2.properties.addressPrefix)){$2.properties.addressPrefix}else{$2.properties.addressPrefixes}
                        $Prefix = $Prefixes.split('/')[1]
                        $AvailableIPs = $null

                        $Delegations = if ($2.properties.delegations.properties.servicename.count -gt 1) { $2.properties.delegations.properties.servicename | ForEach-Object { $_ + ' ,' } }else { $2.properties.delegations.properties.servicename}
                        $Delegations = [string]$Delegations
                        $Delegations = if ($Delegations -like '* ,*') { $Delegations -replace ".$" }else { $Delegations }

                        switch ([int]$Prefix)
                            {
                                8 {$AvailableIPs = 16777211 - $ConsumedIPs}
                                9 {$AvailableIPs = 8388603 - $ConsumedIPs}
                                10 {$AvailableIPs = 4194299 - $ConsumedIPs}
                                11 {$AvailableIPs = 2097147 - $ConsumedIPs}
                                12 {$AvailableIPs = 1048571 - $ConsumedIPs}
                                13 {$AvailableIPs = 524283 - $ConsumedIPs}
                                14 {$AvailableIPs = 262139 - $ConsumedIPs}
                                15 {$AvailableIPs = 131067 - $ConsumedIPs}
                                16 {$AvailableIPs = 65531 - $ConsumedIPs}
                                17 {$AvailableIPs = 32763 - $ConsumedIPs}
                                18 {$AvailableIPs = 16379 - $ConsumedIPs}
                                19 {$AvailableIPs = 8187 - $ConsumedIPs}
                                20 {$AvailableIPs = 4091 - $ConsumedIPs}
                                21 {$AvailableIPs = 2043 - $ConsumedIPs}
                                22 {$AvailableIPs = 1019 - $ConsumedIPs}
                                23 {$AvailableIPs = 507 - $ConsumedIPs}
                                24 {$AvailableIPs = 251 - $ConsumedIPs}
                                25 {$AvailableIPs = 123 - $ConsumedIPs}
                                26 {$AvailableIPs = 59 - $ConsumedIPs}
                                27 {$AvailableIPs = 27 - $ConsumedIPs}
                                28 {$AvailableIPs = 11 - $ConsumedIPs}
                                29 {$AvailableIPs = 4 - $ConsumedIPs}
                                30 {$AvailableIPs = 2 - $ConsumedIPs}
                                31 {$AvailableIPs = 2 - $ConsumedIPs}
                                32 {$AvailableIPs = 1 - $ConsumedIPs}
                                Default 
                                    {
                                        $null
                                    }
                            }
                        foreach ($Tag in $Tags) 
                            {
                                $obj = @{
                                    'ID'                                           = $1.id;
                                    'Subscription'                                 = $sub1.Name;
                                    'Resource Group'                               = $1.RESOURCEGROUP;
                                    'Name'                                         = $1.NAME;
                                    'Location'                                     = $1.LOCATION;
                                    'Retirement Date'                              = [string]$RetDate;
                                    'Retirement Feature'                           = $RetFeature;
                                    'Address Space'                                = $AddrPool;
                                    'Enable DDOS Protection'                       = $data.enableDdosProtection;
                                    'DNS Servers'                                  = $DNSServers;
                                    'Consumed IPs'                                 = [string]$ConsumedIPs;
                                    'Available IPs'                                = [string]$AvailableIPs;
                                    'Subnet Name'                                  = $2.name;
                                    'Private Subnet'                               = if($2.properties.defaultOutboundAccess -eq 'false'){'true'}else{'false'};
                                    'Subnet Prefix'                                = $Prefixes;
                                    'Subnet Private Link Service Network Policies' = $2.properties.privateLinkServiceNetworkPolicies;
                                    'Subnet Private Endpoint Network Policies'     = $2.properties.privateEndpointNetworkPolicies;
                                    'Subnet Delegations'                           = $Delegations;
                                    'Subnet Route Table'                           = if ($2.properties.routeTable.id) { $2.properties.routeTable.id.split("/")[8] };
                                    'Subnet Network Security Group'                = if ($2.properties.networkSecurityGroup.id) { $2.properties.networkSecurityGroup.id.split("/")[8] };
                                    'Resource U'                                   = $ResUCount;
                                    'Tag Name'                                     = [string]$Tag.Name;
                                    'Tag Value'                                    = [string]$Tag.Value
                                }
                                $tmp += $obj
                                if ($ResUCount -eq 1) { $ResUCount = 0 } 
                            }
                    }
            }
            $tmp
        }
}

Else {
    if ($SmaResources.VirtualNetwork) {

        $TableName = ('VNETTable_'+($SmaResources.VirtualNetwork.id | Select-Object -Unique).count)

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range F:F
        $condtxt += New-ConditionalText - -Range H:H -ConditionalType ContainsText
        $condtxt += New-ConditionalText -ConditionalType LessThan 20 -Range N:N

        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Address Space')
        $Exc.Add('Enable DDOS Protection')
        $Exc.Add('Retirement Date')
        $Exc.Add('Retirement Feature')  
        $Exc.Add('DNS Servers')
        $Exc.Add('Subnet Name')
        $Exc.Add('Private Subnet')
        $Exc.Add('Subnet Prefix')
        $Exc.Add('Consumed IPs')
        $Exc.Add('Available IPs')
        $Exc.Add('Subnet Private Link Service Network Policies')
        $Exc.Add('Subnet Private Endpoint Network Policies')
        $Exc.Add('Subnet Delegations')
        $Exc.Add('Subnet Route Table')
        $Exc.Add('Subnet Network Security Group')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }
        
        $noNumberConversion = @()
        $noNumberConversion += 'DNS Servers'
        $noNumberConversion += 'Address Space'
        $noNumberConversion += 'Subnet Prefix'

        $ExcelVar = $SmaResources.VirtualNetwork 

        
        $ExcelVar | 
            ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Virtual Networks' -AutoSize -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style -NoNumberConversion $noNumberConversion
        

        $excel = Open-ExcelPackage -Path $File -KillExcel

        $null = $excel.VirtualNetwork.Cells["F1"].AddComment("Azure DDoS Protection Standard, combined with application design best practices, provides enhanced DDoS mitigation features to defend against DDoS attacks.", "Azure Resource Inventory")
        $excel.VirtualNetwork.Cells["F1"].Hyperlink = 'https://docs.microsoft.com/en-us/azure/ddos-protection/ddos-protection-overview'

        Close-ExcelPackage $excel 

    }
}