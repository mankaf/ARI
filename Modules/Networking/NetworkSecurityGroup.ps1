<#
.Synopsis
Inventory for Azure Network Security Group

.DESCRIPTION
This script consolidates information for all microsoft.network/Netowrksecuritygroup and resource provider in $Resources variable.
Excel Sheet Name: NetworkSecuritytGroup

.Link
https://github.com/microsoft/ARI/Modules/Networking/NetworkSecurityGroup.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.1.0
First Release Date: 2021.10.05
Authors: Christopher Lewis

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle, $Unsupported)
If ($Task -eq 'Processing') {

    $NSGs = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/networksecuritygroups' }
    $nic = $Resources | Where-Object {$_.TYPE -eq 'microsoft.network/networkinterfaces'}
    $vmss = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachinescalesets'}

    if ($NSGs) {
        $tmp = @()

        foreach ($1 in $NSGs) {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
            $data = $1.PROPERTIES
            $RetDate = ''
            $RetFeature = '' 
            $Tags = if (![string]::IsNullOrEmpty($1.tags.psobject.properties)) { $1.tags.psobject.properties }else { '0' }
            $RelatedNics = @()
            $RelatedSubs = @()

            if (![string]::IsNullOrEmpty($data.networkInterfaces.id))
                {
                    foreach ($NICID in $data.networkInterfaces.id)
                        {
                            $NICDetails = $nic | Where-Object {$_.id -eq $NICID}
                            if (![string]::IsNullOrEmpty($NICDetails))
                                {
                                    $RelatedNics += ($NICDetails.name + ' ('+$NICDetails.properties.ipconfigurations.properties.privateipaddress+')')
                                }
                            elseif ($NICID -like '*microsoft.compute/virtualmachinescalesets*')
                                {
                                    $RelatedNics += $NICID.split('/')[12]
                                }
                            
                        }
                    $FinalNICs = if ($RelatedNics.count -gt 1) { $RelatedNics | ForEach-Object { $_ + ' ,' } }else { $RelatedNics }
                    $FinalNICs = [string]$FinalNICs
                    $FinalNICs = if ($FinalNICs -like '* ,*') { $FinalNICs -replace ".$" }else { $FinalNICs }
                }
            if (![string]::IsNullOrEmpty($data.Subnets.id))
                {
                    foreach ($SUBID in $data.Subnets.id)
                        {
                            $RelatedSubs += ($SUBID.Split('/')[8] + ' ('+ $SUBID.Split('/')[10] + ')')
                        }
                    $FinalSUBs = if ($RelatedSubs.count -gt 1) { $RelatedSubs | ForEach-Object { $_ + ' ,' } }else { $RelatedSubs }
                    $FinalSUBs = [string]$FinalSUBs
                    $FinalSUBs = if ($FinalSUBs -like '* ,*') { $FinalSUBs -replace ".$" }else { $FinalSUBs }
                }
            elseif ([string]::IsNullOrEmpty($data.Subnets.id) -and $data.networkInterfaces.id -like '*microsoft.compute/virtualmachinescalesets*')
                {
                    $VMSSs = $vmss | Where-Object {$_.properties.virtualmachineprofile.networkprofile.networkinterfaceconfigurations.properties.networksecuritygroup.id -eq $1.id}
                    foreach ($VM in $VMSSs)
                        {
                            $SUBID = $VM.properties.virtualmachineprofile.networkprofile.networkinterfaceconfigurations.properties.ipconfigurations.properties.subnet.id
                            $RelatedSubs += ($SUBID.Split('/')[8] + ' ('+ $SUBID.Split('/')[10] + ')')
                        }
                    $FinalSUBs = if ($RelatedSubs.count -gt 1) { $RelatedSubs | ForEach-Object { $_ + ' ,' } }else { $RelatedSubs }
                    $FinalSUBs = [string]$FinalSUBs
                    $FinalSUBs = if ($FinalSUBs -like '* ,*') { $FinalSUBs -replace ".$" }else { $FinalSUBs }
                }

            foreach ($2 in $data.securityRules)
            {
                foreach ($Tag in $Tags) {
                    if (![string]::IsNullOrEmpty($2.properties.sourceAddressPrefixes))
                        {
                            $Source = if ($2.properties.sourceAddressPrefixes.count -gt 1) { $2.properties.sourceAddressPrefixes | ForEach-Object { $_ + ' ,' } }else { $2.properties.sourceAddressPrefixes }
                            $Source = [string]$Source
                            $Source = if ($Source -like '* ,*') { $Source -replace ".$" }else { $Source }
                        }
                    elseif(![string]::IsNullOrEmpty($2.properties.sourceAddressPrefix))
                        {
                            $Source = if ($2.properties.sourceAddressPrefix.count -gt 1) { $2.properties.sourceAddressPrefix | ForEach-Object { $_ + ' ,' } }else { $2.properties.sourceAddressPrefix }
                            $Source = [string]$Source
                            $Source = if ($Source -like '* ,*') { $Source -replace ".$" }else { $Source }
                        }
                    else
                        {
                            $Source = ''
                        }

                    if (![string]::IsNullOrEmpty($2.properties.sourcePortRanges))
                        {
                            $SourcePort = if ($2.properties.sourcePortRanges.count -gt 1) { $2.properties.sourcePortRanges | ForEach-Object { $_ + ' ,' } }else { $2.properties.sourcePortRanges }
                            $SourcePort = [string]$SourcePort
                            $SourcePort = if ($SourcePort -like '* ,*') { $SourcePort -replace ".$" }else { $SourcePort }
                        }
                    elseif(![string]::IsNullOrEmpty($2.properties.sourcePortRange))
                        {
                            $SourcePort = if ($2.properties.sourcePortRange.count -gt 1) { $2.properties.sourcePortRange | ForEach-Object { $_ + ' ,' } }else { $2.properties.sourcePortRange }
                            $SourcePort = [string]$SourcePort
                            $SourcePort = if ($SourcePort -like '* ,*') { $SourcePort -replace ".$" }else { $SourcePort }
                        }
                    else
                        {
                            $SourcePort = ''
                        }

                    if (![string]::IsNullOrEmpty($2.properties.destinationAddressPrefixes))
                        {
                            $Destination = if ($2.properties.destinationAddressPrefixes.count -gt 1) { $2.properties.destinationAddressPrefixes | ForEach-Object { $_ + ' ,' } }else { $2.properties.destinationAddressPrefixes }
                            $Destination = [string]$Destination
                            $Destination = if ($Destination -like '* ,*') { $Destination -replace ".$" }else { $Destination }
                        }
                    elseif(![string]::IsNullOrEmpty($2.properties.destinationAddressPrefix))
                        {
                            $Destination = if ($2.properties.destinationAddressPrefix.count -gt 1) { $2.properties.destinationAddressPrefix | ForEach-Object { $_ + ' ,' } }else { $2.properties.destinationAddressPrefix }
                            $Destination = [string]$Destination
                            $Destination = if ($Destination -like '* ,*') { $Destination -replace ".$" }else { $Destination }
                        }
                    else
                        {
                            $Destination = ''
                        }

                    if (![string]::IsNullOrEmpty($2.properties.destinationPortRanges))
                        {
                            $DestinationPort = if ($2.properties.destinationPortRanges.count -gt 1) { $2.properties.destinationPortRanges | ForEach-Object { $_ + ' ,' } }else { $2.properties.destinationPortRanges }
                            $DestinationPort = [string]$DestinationPort
                            $DestinationPort = if ($DestinationPort -like '* ,*') { $DestinationPort -replace ".$" }else { $DestinationPort }
                        }
                    elseif(![string]::IsNullOrEmpty($2.properties.destinationPortRange))
                        {
                            $DestinationPort = if ($2.properties.destinationPortRange.count -gt 1) { $2.properties.destinationPortRange | ForEach-Object { $_ + ' ,' } }else { $2.properties.destinationPortRange }
                            $DestinationPort = [string]$DestinationPort
                            $DestinationPort = if ($DestinationPort -like '* ,*') { $DestinationPort -replace ".$" }else { $DestinationPort }
                        }
                    else
                        {
                            $DestinationPort = ''
                        }

                    if ($data.networkInterfaces.count -eq 0 -and $data.subnets.count -eq 0) 
                        {
                            $Orphaned = $true;
                        } else {
                            $Orphaned = $false;
                        }

                    $obj = @{
                        'ID'                           = $1.id;
                        'Subscription'                 = $sub1.Name;
                        'Resource Group'               = $1.RESOURCEGROUP;
                        'Name'                         = $1.NAME;
                        'Location'                     = $1.LOCATION;
                        'Retirement Date'              = [string]$RetDate;
                        'Retirement Feature'           = $RetFeature;
                        'Orphaned'                     = $Orphaned;
                        'Security Rules'               = $2.name;
                        'Direction'                    = $2.properties.direction;
                        'Action'                       = $2.properties.Access;
                        'Priority'                     = [string]$2.properties.priority;
                        'Protocol'                     = [string]$2.properties.protocol;
                        'Source'                       = $Source;
                        'Source Port'                  = $SourcePort;
                        'Destination'                  = $Destination;
                        'Destination Port'             = $DestinationPort;
                        'Related NICs'                 = $FinalNICs;
                        'Related VNETs and Subnets'    = $FinalSUBs;
                        'Tag Name'                     = [string]$Tag.Name;
                        'Tag Value'                    = [string]$Tag.Value
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 }
                }
            }    
        }
        $tmp
    }
} Else {
    # --------------------------------------------------------------------------------
    # the $SmaResources object for a module should be the same as the name of the file.
    #  In this case the file name is "NetworkSecurityGroup.ps1" so the SMA object
    #  is $SmaResources.NetworkSecurityGroup
    # --------------------------------------------------------------------------------
    $ExcelVar = $SmaResources.NetworkSecurityGroup
    if ($ExcelVar) {

        $TableName = ('NSGTable_'+($SmaResources.NetworkSecurityGroup.id | Select-Object -Unique).count)
        $Style = @()
        $Style += New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -NumberFormat 0 -Range "M:M" -Width 70
        $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -NumberFormat 0 -Range "O:O" -Width 70
        $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -NumberFormat 0 -Range "Q:R" -Width 70

        #Conditional formats.  Note that this can be $() for none
        $condtxt = @()
        $condtxt += New-ConditionalText TRUE -Range G:G
        $condtxt += New-ConditionalText - -Range E:E -ConditionalType ContainsText

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Retirement Date')
        $Exc.Add('Retirement Feature')
        $Exc.Add('Orphaned')
        $Exc.Add('Security Rules')
        $Exc.Add('Direction')
        $Exc.Add('Action')
        $Exc.Add('Priority')
        $Exc.Add('Protocol')
        $Exc.Add('Source')
        $Exc.Add('Source Port')
        $Exc.Add('Destination')
        $Exc.Add('Destination Port')
        $Exc.Add('Related NICs')
        $Exc.Add('Related VNETs and Subnets')

        if ($InTag) {
            $Exc.Add('Tag Name')
            $Exc.Add('Tag Value')
        }

        $noNumberConversion = @()
        $noNumberConversion += 'Source'
        $noNumberConversion += 'Destination'

        $ExcelVar |
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc |
        Export-Excel -Path $File -WorksheetName 'Network Security Groups' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style -NoNumberConversion $noNumberConversion


        <######## Insert Column comments and documentations here following this model.  See StoraceAcc.ps1 for samples #########>


    }
}
