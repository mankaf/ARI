﻿<#
.Synopsis
Inventory for Azure Key Vault

.DESCRIPTION
This script consolidates information for all microsoft.keyvault/vaults and  resource provider in $Resources variable. 
Excel Sheet Name: Vault

.Link
https://github.com/microsoft/ARI/Modules/Infrastructure/Vault.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.0.1
First Release Date: 19th November, 2020
Authors: Claudio Merola and Renato Gregio 

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Unsupported)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $VAULT = $Resources | Where-Object {$_.TYPE -eq 'microsoft.keyvault/vaults'}

    <######### Insert the resource Process here ########>

    if($VAULT)
        {
            $tmp = @()

            foreach ($1 in $VAULT) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if([string]::IsNullOrEmpty($Data.enableSoftDelete)){$Soft = $false}else{$Soft = $Data.enableSoftDelete}
                if([string]::IsNullOrEmpty($data.enableRbacAuthorization)){$RBAC = $false}else{$RBAC = $Data.enableRbacAuthorization}
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                Foreach($2 in $data.accessPolicies)
                    {
                        $Secrets = if ($2.permissions.secrets.count -gt 1) { $2.permissions.secrets | ForEach-Object { $_ + ' ,' } }else { $2.permissions.secrets }
                        $Secrets = [string]$Secrets
                        $Secrets = if ($Secrets -like '* ,*') { $Secrets -replace ".$" }else { $Secrets }

                        $Keys = if ($2.permissions.keys.count -gt 1) { $2.permissions.keys | ForEach-Object { $_ + ' ,' } }else { $2.permissions.keys }
                        $Keys = [string]$Keys
                        $Keys = if ($Keys -like '* ,*') { $Keys -replace ".$" }else { $Keys }

                        $Certs = if ($2.permissions.certificates.count -gt 1) { $2.permissions.certificates | ForEach-Object { $_ + ' ,' } }else { $2.permissions.certificates }
                        $Certs = [string]$Certs
                        $Certs = if ($Certs -like '* ,*') { $Certs -replace ".$" }else { $Certs }

                        foreach ($Tag in $Tags) {
                                $obj = @{
                                    'ID'                         = $1.id;
                                    'Subscription'               = $sub1.Name;
                                    'Resource Group'             = $1.RESOURCEGROUP;
                                    'Name'                       = $1.NAME;
                                    'Location'                   = $1.LOCATION;
                                    'SKU Family'                 = $data.sku.family;
                                    'SKU'                        = $data.sku.name;
                                    'Vault Uri'                  = $data.vaultUri;
                                    'Public Network Access'      = $data.publicnetworkaccess;
                                    'Enable RBAC'                = $RBAC;
                                    'Enable Soft Delete'         = $Soft;
                                    'Enable for Disk Encryption' = $data.enabledForDiskEncryption;
                                    'Soft Delete Retention Days' = $data.softDeleteRetentionInDays;
                                    'Access Policy ObjectID'     = $2.objectid;
                                    'Certificate Permissions'    = $Certs;
                                    'Key Permissions'            = $Keys;
                                    'Secret Permissions'         = $Secrets;
                                    'Resource U'                 = $ResUCount;
                                    'Tag Name'                   = [string]$Tag.Name;
                                    'Tag Value'                  = [string]$Tag.Value
                                }
                                $tmp += $obj
                                if ($ResUCount -eq 1) { $ResUCount = 0 } 
                            }
                    }               
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.Vault)
    {

        $TableName = ('VaultTable_'+($SmaResources.Vault.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()
        $condtxt += New-ConditionalText false -Range J:J
        $condtxt += New-ConditionalText enabled -Range H:H

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU Family')
        $Exc.Add('SKU')
        $Exc.Add('Vault Uri')
        $Exc.Add('Public Network Access')
        $Exc.Add('Enable RBAC')
        $Exc.Add('Enable Soft Delete')
        $Exc.Add('Enable for Disk Encryption')
        $Exc.Add('Soft Delete Retention Days')
        $Exc.Add('Access Policy ObjectID')
        $Exc.Add('Certificate Permissions')
        $Exc.Add('Key Permissions')
        $Exc.Add('Secret Permissions')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.Vault 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Key Vaults' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

        <######## Insert Column comments and documentations here following this model #########>

        #Close-ExcelPackage $excel 

    }
}