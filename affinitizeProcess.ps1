################################################################################
# PowerShell script to affinitize processes to specific logical cores.         #
# Copyright (c) 2018 Frostbyte <frostbytegr@gmail.com>                         #
#                                                                              #
# This program is free software: you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation, either version 3 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.        #
################################################################################
##################### REQUIRES ADMIN PRIVILEGES TO WORK ########################
################################################################################
# Usage(s):	.\affinitizeProcess.ps1 -exec "<EXECUTABLE_NAME>" -cores "0,2,4,6" #
#			.\affinitizeProcess.ps1 -exec "<EXECUTABLE_NAME>" -cores "all"     #
################################################################################

# Declaration of input parameters
param([Parameter(Mandatory=$true)][String]$exec, [Parameter(Mandatory=$true)][String]$cores)

# Function to convert the requested cores input string to a combined affinity mask
# Returns (int32)__combinedAffinityMask
function toAffinityMask($__requestedCoresString) {
	# Fetch processor logical core count
	$private:__logicalCoreCount=(Get-WmiObject -class Win32_processor).NumberOfLogicalProcessors

	# Generate the affinity mask inventory, based on how many logical cores are available
	$private:__affinityMaskInventory=generateAffinityMaskInventory $__logicalCoreCount

	# If all of the cores were requested
	if ($__requestedCoresString -imatch "^all$") {
		# Select the global affinity mask
		$private:__combinedAffinityMask=[Int32]$__affinityMaskInventory[-1]
	} else {
		# Split the requested cores input string to individual core indexes
		$private:__requestedCores=$__requestedCoresString -split ','
		# Iterate through the requested cores
		for ($private:__coreIndex=0; $__coreIndex -lt $__requestedCores.Length; $__coreIndex++) {
			# If any of them was not specified in a numerical format or is out of the expected range
			if ((!($__requestedCores[$__coreIndex] -imatch "[0-9]+")) -or ([Int32]$__requestedCores[$__coreIndex] -lt 0) -or ([Int32]$__requestedCores[$__coreIndex] -ge $__logicalCoreCount)) {
				# Throw an error and exit
				Write-Host "Invalid core settings supplied, please use the keyword 'all' or specify comma-delimited numbers between 0 and"($__logicalCoreCount-1)"."
				Write-Host -NoNewLine "Press any key to exit.."; $host.UI.RawUI.ReadKey()
				exit 2
			}

			# Construct the combined affinity mask
			$private:__combinedAffinityMask+=[Int32]$__affinityMaskInventory[$__requestedCores[$__coreIndex]]
		}
	}

	# Return the resulting afinity mask
	return $__combinedAffinityMask
}

# Function to generate the affinity mask inventory
# Returns (int32)__affinityMaskInventory[], use logical core index for individual mask, or -1 for global mask (all cores)
function generateAffinityMaskInventory($__maxNumOfCores) {
	# Initialize an empty array
	$private:__affinityMaskInventory=@()

	# For every logical core
	for ($private:__coreIndex=0; $__coreIndex -lt $__maxNumOfCores; $__coreIndex++) {
		# Calculate it's affinity mask and append it to the affinity mask inventory
		$__affinityMaskInventory+=[Int32][Math]::Pow(2,$__coreIndex)
	}

	# Then calculate the global affinity mask (all cores) and append it to the affinity mask inventory
	$__affinityMaskInventory+=[Int32]($__affinityMaskInventory[-1]*2-1)

	# Return the affinity mask inventory
	return $__affinityMaskInventory
}

# Run in a loop if the requested process has not yet been detected
while (!(Get-Process -Name $exec -ErrorAction SilentlyContinue)) {
	Clear
	Write-Host -NoNewLine "Waiting for process"$exec" to start.. (CTRL+C to quit)"
	Start-Sleep 5
}

# If there's more than one process matching the user request
if ((Get-Process -Name $exec).Count -gt 1) {
	do {
		# Present the user with a summary
		Clear
		Get-Process -Name $exec | ft id,name,mainWindowTitle -AutoSize
		# Then prompt to choose which one they want to affinitize (until something valid is selected)
		$private:__targetProcess=Read-Host -Prompt "More than one process of $exec are running. Please select which one to affinitize (Enter to refresh, CTRL+C to quit)"
	} while ((Get-Process -ID $__targetProcess -ErrorAction SilentlyContinue).Name -ne $exec)
} else {
	# Fetch the ID of the matching process
	$private:__targetProcess=(Get-Process -Name $exec).ID
}

# Generate the affinity mask in accordance to the requested cores
$local:__affinityMask=toAffinityMask $cores

# Assign the requested cores to the requested process
Clear
Write-Host "Setting affinity mask"$__affinityMask" to process "$exec". (PID: "$__targetProcess")"
$__targetProcess=Get-Process -ID $__targetProcess | %{$_.ProcessorAffinity=$__affinityMask}
Write-Host -NoNewLine "Press any key to exit.."; $host.UI.RawUI.ReadKey()
exit 0
