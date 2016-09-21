$vmsInfo = @()
$totalDisksSize = 0
$vms = get-vm
foreach ($vm in $vms)
{
#    Write-Host "VM name: " $vm.name
    $disks = Get-VMHardDiskDrive $vm
    foreach ($hd in $disks)
    {
        $vhd = Get-VHD $hd.Path
        $disksize = $vhd.Size
        $totalDisksSize = $totalDisksSize + $disksize
    }
    $totalDisksSizeGB = $totalDisksSize/1024/1024/1024
    $disksCount = $disks.count

    $system = New-Object -TypeName PSObject
    Add-Member -InputObject $system -MemberType NoteProperty -Name "VM Name" -Value $vm.name
    Add-Member -InputObject $system -MemberType NoteProperty -Name "Total Capacity (GB)" -Value $totalDisksSizeGB
    Add-Member -InputObject $system -MemberType NoteProperty -Name "Disks Count" -Value $disksCount
    Add-Member -InputObject $system -MemberType NoteProperty -Name OS -Value "..."
    $vmsInfo += $system
    
}

#$vmsInfo | out-string | Out-File -FilePath "c:\test.txt"

$vmsInfo | Export-Csv -Path "c:\VMs_Report.csv" -notypeinformation
$vmsInfo | out-string