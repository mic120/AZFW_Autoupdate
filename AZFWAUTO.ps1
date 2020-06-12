#JSON FILES
$WWJSON =  "D:\Users\sum\Desktop\azfw\worldwide.json"
$bkfile =  "D:\Users\sum\Desktop\azfw\AZfirewall.json"

#OUTFILES
$Applicationconf = ".\Application.txt"
$networkconf = ".\Network.txt"

#Configure
$srcaddress = "10.0.0.0/0"

#CMDSET
            $acmd1 = "= New-AzFirewallApplicationRule -Name"
            $acmd2 = "-SourceAddress "
            $acmd3 = "-Protocol"
            $acmd4 = "-TargetFqdn"
            $acmd10 = "`$AppRuleCollection = New-AzFirewallApplicationRuleCollection -Name App-Coll01 -Priority 200 -ActionType Allow -Rule"

            $ncmd1 = "= New-AzFirewallNetworkRule -Name"
            $ncmd2 = "-Protocol TCP -SourceAddress"
            $ncmd5 = "-Protocol UDP -SourceAddress"
            $ncmd6 = "-Protocol "
            $ncmd7 = "-SourceAddress"
            $ncmd3 = "-DestinationAddress"
            $ncmd4 = "-DestinationPort"
            $ncmd10 = "`$AppRuleCollection = New-AzFirewallApplicationRuleCollection -Name RCNET01  -Priority 200 -ActionType Allow -Rule"

#Clear files
if(Test-Path $Applicationconf){
    Remove-Item $Applicationconf
    }

if(Test-Path $networkconf){
    Remove-Item $networkconf
    }

#Convert file from Json and choose services
$InRules = Get-Content $WWJSON -Encoding UTF8 -Raw | ConvertFrom-Json
$bkrules = Get-Content $bkfile -Encoding UTF8 -Raw |ConvertFrom-Json
$InRules2 = $InRules |Where-Object {$_.servicearea -eq "Skype" -or $_.servicearea -eq "Common"}
$InRules3 = $InRules2 |Where-Object {$_.required -eq "True"} 

#Var Initialize
$acount = 1
$alistvarno = ""

#Azure Firewall Create Application Rules
foreach($arule in $InRules3){
    if($arule.urls -ne $null){
        $aurls = $arule.urls -join ","

        if($arule.tcpports -ne $null){

            $avarno = "`$AppRule$acount"
            $aname = $arule.id
            $asrcad = $srcaddress
            $aprtcl = $arule.tcpPorts |ForEach-Object {$_ -replace '80','Http' -replace '443','Https'}
            $atarget = $aurls
            $alistvarno = "$alistvarno" +" " + "$avarno"
           
            Add-Content -Path $Applicationconf -value "$avarno $acmd1 $aname $acmd2 $asrcad $acmd3 $aprtcl $acmd4 $atarget"  
            
            $acount++
    
        }else{
            write-host "There protocol not support with this tool"
        }
         
}
}


            Add-Content -Path $Applicationconf -value "$acmd10$alistvarno"

            
#Var Initialize
$ncount = 1
$nlistvarno = ""



#Azure Firewall Create Network Rules
foreach($nrule in $InRules3){
    if($nrule.ips -ne $null){
        $nips = $nrule.ips -join ","

        if($nrule.tcpports -ne $null){
            $nvarno = "`$NetRule$ncount"
            $nname = $nrule.id
            $nsrcad = $srcaddress
            $ntarget = $nips
            $nprtcl = $nrule.tcpports
            $nlistvarno = "$nlistvarno" +" " + "$nvarno"

            Add-Content -Path $networkconf -value "$nvarno $ncmd1 $nname $ncmd2 $nsrcad $ncmd3 $ntarget $ncmd4 $nprtcl"  
            
            $ncount++

         }elseif($nrule.udpports -ne $null){
            $nvarno = "`$NetRule$ncount"
            $nname = $nrule.id
            $nsrcad = $srcaddress
            $ntarget = $nips
            $nprtcl = $nrule.udpports
            $nlistvarno = "$nlistvarno" +" " + "$nvarno"

            Add-Content -Path $networkconf -value "$nvarno $ncmd1 $nname $ncmd5 $nsrcad $ncmd3 $ntarget $ncmd4 $nprtcl"  
            
            $ncount++
        }


}
}


            Add-Content -Path $networkconf -value "$ncmd10$nlistvarno"



#Create Config from backup files
#Azure Firewall Create Application Rules from Backup

$bkarules = $bkrules.resources.properties.applicationRuleCollections

#Var Initialize
$bkacount = 1
$bkalistvarno = ""

foreach($bkar in $bkarules){
    $bknrname = $bkar.properties.rules|Where-Object{$bkar.name -eq "Skype"}
    foreach ($bka in $bknrname){
            $bkatargettemp = $bka.targetfqdns  -join ","
            $bkaprtcltemp = $bka.protocols.protocolType -join ","
  
            $bkavarno = "`$BKAppRule$bkacount"
            $bkaname = $bka.name
            $bkasrcad = $bka.sourceaddresses
            $bkaprtcl = $bkaprtcltemp
            $bkatarget = $bkatargettemp
            $bkalistvarno = "$bkalistvarno" +" " + "$bkavarno"

            $bkacount++

            Add-Content -Path $Applicationconf -value "$bkavarno $acmd1 $bkaname $acmd2 $bkasrcad $acmd3 $bkaprtcl $acmd4 $bkatarget"  
        }
        }

$bknrules = $bkrules.resources.properties.networkRuleCollections

#Var Initialize
$bkncount = 1
$bknlistvarno = ""

foreach($bknr in $bknrules){ 
    $bkarname = $bknr.properties.rules|Where-Object{$bknr.name -eq "OnpremiseIN"}
    foreach($sk in $bkarname){
            $bknsrcadtemp = $sk.sourceAddresses -join ","
            $bknprtcltemp = $sk.protocols -join ","
            $bknipstemp = $sk.destinationAddresses -join ","
            $bkdestport2 = $sk.destinationPorts -join ","

            $bknvarno = "`$BKNetRule$vkncount"
            $bknname = $sk.name
            $bknsrcad = $bknsrcadtemp
            $bkntarget = $bknipstemp
            $bknprtcl = $bknprtcltemp
            $bkdestport1 = $bkdestport2
            $bknlistvarno = "$bknlistvarno" +" " + "$bknvarno"

            Add-Content -Path $networkconf -value "$bknvarno $ncmd1 $bknname $ncmd6 $bknprtcl $ncmd7 $bknsrcad $ncmd3 $bkntarget $ncmd4 $bkdestport1"  
            
            $bkncount++

    write-host $sk.name
    write-host $sk.protocols
    }
}

            Add-Content -Path $Applicationconf -value "`$Azfw.ApplicationRuleCollections.Add(`$AppRuleCollection)"
            Add-Content -Path $Applicationconf -value "Set-AzFirewall -AzureFirewall `$Azfw"


            Add-Content -Path $networkconf -value "`$Azfw.ApplicationRuleCollections.Add(`$AppRuleCollection)"
            Add-Content -Path $networkconf -value "Set-AzFirewall -AzureFirewall `$Azfw"


        write-host $acount
        write-host $ncount
