# Add VMware Snap-In
Write-Host "`nAdding VMware snap-in..."
Add-PSSnapin VMware.VimAutomation.Core

# Get vCenter information
$vc = Read-Host "`nEnter vCenter IP/name"
$user = Read-Host "Enter username"
$pass = Read-Host "Enter password"

# Connect to vCenter
Write-Host "`nConnecting to " $vc "...`n"
$vcConnect = Connect-VIServer $vc -User $user -Password $pass

$vm = Read-Host "Enter VM Name"
$vm = get-vm $vm

$view = Get-View $vm
if ($view.Config.Version -ge "vmx-07" -and $view.Config.changeTrackingEnabled -eq $true) {
	if (($view.snapshot -eq $null) -and ($vm.PowerState -eq 'PoweredOn')) {
		#Disable CBT 
		Write-Host "Disabling CBT for" $vm
		$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
		$spec.ChangeTrackingEnabled = $false 
		$vm.ExtensionData.ReconfigVM($spec) 
		
		#Take/Remove Snapshot to reconfigure VM State
        Write-Host "Creating snapshot"
		$SnapName = New-Snapshot -vm $vm -Name "CBT-Rest-Snapshot"
        Write-Host "Waiting 2 seconds..."
        sleep 2
        write-host "Removing snapshot"
		$SnapRemove = Remove-Snapshot -Snapshot $SnapName -Confirm:$false
        Write-Host "Waiting 2 seconds..."
        sleep 2

		#Enable CBT 
		Write-Host "Enabling CBT for" $vm
		$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
		$spec.ChangeTrackingEnabled = $true 
		$vm.ExtensionData.ReconfigVM($spec) 
					
		#Take/Remove Snapshot to reconfigure VM State
        Write-Host "Creating snapshot"
		$SnapName1 = New-Snapshot -vm $vm -Name "CBT-Verify-Snapshot"
        Write-Host "Waiting 2 seconds..."
        sleep 2
        write-host "Removing snapshot"
		$SnapRemove1 = Remove-Snapshot -Snapshot $SnapName1 -Confirm:$false
        Write-Host "Waiting 2 seconds..."
        sleep 2
	}
}