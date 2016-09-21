# This script will export ESXi configuration to a file in XML format.
# Mostly useful before reinstalling an ESXi or performing a backup before upgrading.

# Get ESXi information
Write-Host "`nEnter ESX to export configuration: "
$esx = Read-Host

Write-Host "`nEnter username: "
$user = Read-Host

Write-Host "`nEnter password: "
$pass = Read-Host

# Add VMware Snap-In
Write-Host "`nAdding VMware snap-in..."
Add-PSSnapin VMware.VimAutomation.Core

# Connect to ESXi
Write-Host "`nConnecting to " $esx "..."
$esxConnect = Connect-VIServer $esx -User $user -Password $pass

# Display amenu to the user
write-host "`nChoose one of the options below: `n1. Export only specific ESXi configuration (NTP, DNS, vSwitch and Datastores)"
write-host "2. Export ALL ESXi configuration`nType your choise here (1 or 2): "
$choise = Read-Host

# Export specific data from the ESXi ((NTP, DNS, vSwitch and Datastores)
if ($choise -eq 1)
{
    $EsxConfigs = ""
    
    # Create new ESX configuration object
    $EsxConfigs = New-Object -TypeName PSObject

    # Add the NTP servers to the ESX object
    Write-Host "Getting NTP servers..."
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "NTPServers" -Value (Get-VMHostNtpServer -VMHost $esx)
    
    # Add the DNS servers to the ESX object
    Write-Host "Getting DNS configuration..."
    $hostNetwork = Get-VMHostNetwork -VMHost $esx
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "DNSDomainName" -Value $hostNetwork.DomainName
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "DNSSearch" -Value $hostNetwork.SearchDomain
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "DNSAddress" -Value $hostNetwork.DnsAddress
    
    $vswitches = Get-VirtualSwitch
    
    Write-Host "Getting vSwitches configuration..."
    foreach ($vswitch in $vswitches)
    {
        if ($vswitch.Id -notlike "*Distributed*")
        {
            # Create a vSwitch PS object and add the relevant parameters to it
            $vswitchObj = New-Object -TypeName PSObject
            $vswitchObj | Add-Member -MemberType NoteProperty -Name "Name" -Value $vswitch.Name
            $vswitchObj | Add-Member -MemberType NoteProperty -Name "Nics" -Value $vswitch.Nic
    
            $portGroups = $vswitch.ExtensionData.Portgroup
    
            foreach ($portGroup in $portGroups)
            {
                # Create a Port Group PS object and add the relevant parameters to it
                $portGroupObg = New-Object -TypeName PSObject
                $port = Get-VirtualPortGroup | Where-Object {$_.Key -like $portGroup}
                $vmk = Get-VMHostNetworkadapter | Where-Object {$_.PortGroupName -like $port.Name}
    
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "Name" -Value $port.Name
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "IP" -Value $vmk.IP
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "Subnet Mask" -Value $vmk.SubnetMask
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "VLAN" -Value $port.VLanId
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "VMotionEnabled" -Value $vmk.VMotionEnabled
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "MTU" -Value $vmk.Mtu
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "Security" -Value $port.ExtensionData.ComputedPolicy.Security
                $portGroupObg | Add-Member -MemberType NoteProperty -Name "NicOrder" -Value $port.ExtensionData.ComputedPolicy.NicTeaming.NicOrder
    
    
                $vswitchObj | Add-Member -MemberType NoteProperty -Name $port.name -Value $portGroupObg
            }
            $EsxConfigs | Add-Member -MemberType NoteProperty -Name $vswitch.name -Value $vswitchObj
        }
    }
    
    Write-Host "Getting Datastore configuration..."
    #$datastores = Get-Datastore | Where-Object {$_.Type -like "VMFS"}
    #$datastores = Get-Datastore | Where-Object {$_.Type -like "NFS"}
    $datastores = Get-Datastore
    $allDatastoresObg = New-Object -TypeName PSObject
    
    foreach ($datastore in $datastores)
    {
        $datastoreObg = New-Object -TypeName PSObject
        $datastoreObg | Add-Member -MemberType NoteProperty -Name "Name" -Value $datastore.Name
        $datastoreObg | Add-Member -MemberType NoteProperty -Name "Type" -Value $datastore.Type
        
        # Add additional values if the DS is NFS
        if ($datastore.Type -like "NFS")
        {
            $datastoreObg | Add-Member -MemberType NoteProperty -Name "Path" -Value $datastore.RemotePath
            $datastoreObg | Add-Member -MemberType NoteProperty -Name "NFSHost" -Value $datastore.RemoteHost
        }
        
        $allDatastoresObg | Add-Member -MemberType NoteProperty -Name $datastoreObg.Name -Value $datastoreObg
    }
    
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "Datastores" -Value $allDatastoresObg
    
    $fileName = (Get-VMHost).Name + "_Configs"
    
    Write-Host "Exporting host configuration to file..."
    $EsxConfigs | Export-Clixml "c:\temp\$fileName"
    Write-Host "The file is located at: " "c:\Temp\$fileName"
    
    Disconnect-VIServer * -Force -Confirm:$false
    
}

elseif ($choise -eq 2)
{
    $EsxConfigs = ""

    $EsxConfigs = New-Object -TypeName PSObject

    Write-Host "Getting NTP servers..."
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "NTP_servers" -Value (Get-VMHostNtpServer -VMHost $esx)
    
    Write-Host "Getting DNS configuration..."
    $hostNetwork = Get-VMHostNetwork -VMHost $esx
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "DNS_Config" -Value $hostNetwork
    
    $vswitches = Get-VirtualSwitch
    
    Write-Host "Getting vSwitches configuration..."
    foreach ($vswitch in $vswitches)
    {
        if ($vswitch.Id -notlike "*Distributed*")
        {
            $vswitchObj = New-Object -TypeName PSObject
            $vswitchObj | Add-Member -MemberType NoteProperty -Name $vswitch.Name -Value $vswitch
    
            $portGroups = $vswitch.ExtensionData.Portgroup
    
            foreach ($portGroup in $portGroups)
            {
                $portGroupObg = New-Object -TypeName PSObject
                $port = Get-VirtualPortGroup | Where-Object {$_.Key -like $portGroup}
                $vmk = Get-VMHostNetworkadapter | Where-Object {$_.PortGroupName -like $port.Name}
    
                $portGroupObg | Add-Member -MemberType NoteProperty -Name $port.Name -Value $port
                $portGroupObg | Add-Member -MemberType NoteProperty -Name $vmk.DeviceName -Value $vmk
    
    
                $vswitchObj | Add-Member -MemberType NoteProperty -Name $port.name -Value $portGroupObg
            }
            $EsxConfigs | Add-Member -MemberType NoteProperty -Name $vswitch.name -Value $vswitchObj
        }
    }
    
    Write-Host "Getting Datastore configuration..."
    $datastores = Get-Datastore
    $allDatastoresObg = New-Object -TypeName PSObject
    
    foreach ($datastore in $datastores)
    {
        $allDatastoresObg | Add-Member -MemberType NoteProperty -Name $datastore.Name -Value $datastore
    }
    
    $EsxConfigs | Add-Member -MemberType NoteProperty -Name "Datastores" -Value $allDatastoresObg
    
    $fileName = (Get-VMHost).Name + "_All_Configs"
    
    Write-Host "Exporting host configuration to file..."
    $EsxConfigs | Export-Clixml "c:\temp\$fileName"
    Write-Host "The file is located at: " "c:\Temp\$fileName"
    
    Disconnect-VIServer * -Force -Confirm:$false
}

else
{
    Write-Host "`nPlease enter only 1 or 2`n";
}

Write-Host "Press enter to quit.."
Read-Host
#pause