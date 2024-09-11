<#
.Synopsis
Inventory for Azure MySQLF lexible Server

.DESCRIPTION
This script consolidates information for all  resource provider in $Resources variable. 
Excel Sheet Name: MySQL flexible

.Link
https://github.com/microsoft/ARI/Modules/Data/MySQLFlexible.ps1

.COMPONENT
    This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 2.0.0
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $MySQLFlexible = $Resources | Where-Object { $_.TYPE -eq 'Microsoft.DBforMySQL/flexibleServers' }

    if($MySQLFlexible)
        {
            $tmp = @()
            foreach ($1 in $MySQLFlexible) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                    foreach ($Tag in $Tags) {
                        $obj = @{
                            'ID'                                = $1.id;
                            'Subscription'                      = $sub1.Name;
                            'Resource Group'                    = $1.RESOURCEGROUP;
                            'Name'                              = $1.NAME;
                            'Location'                          = $1.LOCATION;
                            'SKU'                               = $data.sku.name;
                            'Version'                           = $data.version;
                            'State'                             = $data.state;
                            'Zone'                              = $data.availabilityZone;
                            'Administrator Login'               = $data.administratorLogin;
                            'Storage Size (GB)'                 = $data.storage.storageSizeGB;
                            'Limit IOPs'                        = $data.storage.iops;
                            'Auto Grow'                         = $data.storage.autoGrow;
                            'Storage Sku'                       = $data.storage.storageSku;
                            'Custom Maintenance Window'         = $data.maintenanceWindow.customWindow;
                            'Replication Role'                  = $data.replicationRole;
                            'Replica Capacity'                  = $data.replicaCapacity;
                            'Public Network Access'             = $data.network.publicNetworkAccess;
                            'Backup Retention Days'             = $data.backup.backupRetentionDays;
                            'Geo Redundant Backup'              = $data.backup.geoRedundantBackup;
                            'High Availability'                 = $data.highAvailability.mode;
                            'High Availability State'           = $data.highAvailability.state;                            
                            'FQDN'                              = $data.fullyQualifiedDomainName;
                            'Tag Name'                          = [string]$Tag.Name;
                            'Tag Value'                         = [string]$Tag.Value
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }                
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.MySQLFlexible ##########>

    if ($SmaResources.MySQLFlexible) {

        $TableName = ('MySQLFlexTable_'+($SmaResources.MySQLFlexible.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Version')
        $Exc.Add('State')
        $Exc.Add('Zone')
        $Exc.Add('Administrator Login')
        $Exc.Add('Storage Size (GB)')
        $Exc.Add('Limit IOPs')
        $Exc.Add('Auto Grow')
        $Exc.Add('Storage Sku')
        $Exc.Add('Custom Maintenance Window')
        $Exc.Add('Replication Role')
        $Exc.Add('Replica Capacity')
        $Exc.Add('Public Network Access')
        $Exc.Add('Backup Retention Days')
        $Exc.Add('Geo Redundant Backup')
        $Exc.Add('High Availability')
        $Exc.Add('High Availability State')
        $Exc.Add('FQDN')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.MySQLFlexible 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'MySQL Flexible' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}