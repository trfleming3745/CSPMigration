$creds = Get-Credential
#Add-AzureAccount -Credential $creds

Login-AzureRmAccount -Credential $creds
$subs = Get-AzureRmSubscription | Select Name,SubscriptionID

#Grabbing Resource Group Names from Non-CSP Subscription#
Select-AzureRmSubscription -SubscriptionName $subs[0].Name 
    $oldRSG = Get-AzureRmResourceGroup

#Azure Inventory Assessment of Current Subscription to CSV#
    Select-AzureRmSubscription -SubscriptionName $subs[0].Name
    $Assessment =  @()
    $Path = 'C:\Temp'
    ForEach($RG in $oldRSG){
        $Inventory = Get-AzureRmResource | where {$_.resourcegroupname -like $RG.resourcegroupname}
        $Assessment += $Inventory
    }
    $Assessment | Export-Csv -Path "$($Path)\AzureInventory.csv" -NoTypeInformation 

#Creating Identical Resource Groups in CSP Subscription#
Select-AzureRmSubscription -SubscriptionName $subs[1].Name
    foreach($RG in $oldRSG){
        $RGCheck = Get-AzureRmResourceGroup -Name $RG.ResourceGroupName -ErrorAction SilentlyContinue
        [boolean] $RGCheck
        if($RGCheck -eq $false)
            {Add-AzureRmResourceGroup -Name $RG.ResourceGroupName -Location $RG.Location}   
    }

#Move Resources from Old Subscription to New Subscription#
Select-AzureRmSubscription -SubscriptionName $subs[0].Name
$oldRSG = Get-AzureRmResourceGroup
$Resources = Get-AzureRmResource | Where {$_.ResourceGroupName -eq "TEST-CLIENTGW"}
    foreach($Resource in $Resources){
        Move-AzureRmResource -ResourceId $Resource.ResourceId -DestinationSubscriptionId $subs.SubscriptionID[1] -DestinationResourceGroupName $RSG.ResourceGroupName
    }
        