#Provide Input. Firewall Policy Name, Firewall Policy Resource Group & Firewall Policy Rule Collection Group Name
$fpname = "MyFirewallPolicy"
$fprg = "azurehub"
$fprcgname = "DefaultNetworkRuleCollectionGroup"

$targetfp = Get-AzFirewallPolicy -Name $fpname -ResourceGroupName $fprg
$targetrcg = New-AzFirewallPolicyRuleCollectionGroup -Name $fprcgname -Priority 400 -FirewallPolicyObject $targetfp

$RulesfromCSV = @()
# Change the folder where the CSV is located
$sourceAddresses = @()
$destinationAddresses = @()
$sourceAddress = @()
$destinationAddress = @()

$readObj = import-csv "C:\Users\suvasara\Desktop\AzTS-Modules\rules.csv"
foreach ($entry in $readObj)
{
    $sourceAddresses += $entry.SourceAddresses
    $objects = $sourceAddresses -split ','
    $quotedObjects = $objects | ForEach-Object {"$_"}
    $sourceAddressesStringobject = "[" + ($quotedObjects -join ",") + "]"
    $sourceAddressesStringobjectfinal = $sourceAddressesStringobject.substring(1,$sourceAddressesStringobject.length-2)
    Write-Output $sourceAddressesStringobjectfinal

    $destinationAddresses += $entry.DestinationAddresses
    $objects = $destinationAddresses -split ','
    $quotedObjects = $objects | ForEach-Object {"$_"}
    $destinationAddressesStringobject = "[" + ($quotedObjects -join ",") + "]"
    $destinationAddressesStringobjectfinal = $destinationAddressesStringobject.substring(1,$destinationAddressesStringobject.length-2)
    Write-Output $destinationAddressesStringobjectfinal

    $properties = [ordered]@{
        RuleCollectionName = $entry.RuleCollectionName;
        RulePriority = $entry.RulePriority;
        ActionType = $entry.ActionType;
        Name = $entry.Name;
        protocols = $entry.protocols -split ", ";
        SourceAddresses = $sourceAddressesStringobjectfinal
        DestinationAddresses = $destinationAddressesStringobjectfinal
        SourceIPGroups = $entry.SourceIPGroups -split ", ";
        DestinationIPGroups = $entry.DestinationIPGroups -split ", ";
        DestinationPorts = $entry.DestinationPorts -split ", ";
        DestinationFQDNs = $entry.DestinationFQDNs -split ", ";
    }
    $obj = New-Object psobject -Property $properties
    $RulesfromCSV += $obj

$RulesfromCSV
Clear-Variable rules
$rules = @()
foreach ($entry in $RulesfromCSV)
{
    $RuleParameter = @{
        Name = $entry.Name;
        Protocol = $entry.protocols
        sourceAddress = $entry.SourceAddresses -split ','
        DestinationAddress = $entry.DestinationAddresses -split','
        DestinationPort = $entry.DestinationPorts
        
    }   
    
    $rule = New-AzFirewallPolicyNetworkRule @RuleParameter
    Write-Output $rule
    $NetworkRuleCollection = @{
        Name = $entry.RuleCollectionName
        Priority = $entry.RulePriority
        ActionType = $entry.ActionType
        Rule       = $rules += $rule
    }
}
}
# Create a network rule collection
$NetworkRuleCategoryCollection = New-AzFirewallPolicyFilterRuleCollection @NetworkRuleCollection
# Deploy to created rule collection group
Set-AzFirewallPolicyRuleCollectionGroup -Name $targetrcg.Name -Priority 500 -RuleCollection $NetworkRuleCategoryCollection -FirewallPolicyObject $targetfp
