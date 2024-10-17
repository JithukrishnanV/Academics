#Section 1: Ask the user if they want to save a new baseline or compare to an existing one
$action = Read-Host "Type 'save' to save a new baseline, or 'check' to compare the current registry with the baseline"

#Section 2: Set up file paths and registry keys to monitor
$folderPath = "C:\RegistryCheck"
$baselineFile = "$folderPath\baseline.txt"
$logFile = "$folderPath\changes_log.txt"

$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)

#Section 3: Patterns to watch for malware-like entries
$malwareSigns = @("*.exe", "*.tmp")

#Section 4: Function to get a snapshot of the registry for the monitored paths
function Get-RegistrySnapshot {
    $snapshot = @()
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $entries = Get-ItemProperty -Path $path
            foreach ($entry in $entries.PSObject.Properties) {
                $snapshot += "$path|$($entry.Name)|$($entry.Value)"
            }
        }
    }
    return $snapshot
}

# Ensure the folder for saving files exists, create it if not
if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
}

#Section 5: Save baseline or check against baseline based on user input
if ($action -eq "save") {
    Get-RegistrySnapshot | Out-File $baselineFile
    Write-Host "Baseline created and saved."
} elseif ($action -eq "check") {
    if (Test-Path $baselineFile) {
        $currentSnapshot = Get-RegistrySnapshot
        $baselineSnapshot = Get-Content $baselineFile

#Section 6: Compare current state with the baseline to find changes
        $differences = Compare-Object $baselineSnapshot $currentSnapshot
        foreach ($difference in $differences) {
            Add-Content $logFile "$difference"
        }

#Section 7: Check for suspicious entries (possible malware)
        foreach ($entry in $currentSnapshot) {
            foreach ($malware in $malwareSigns) {
                if ($entry -like $malware) {
                    Add-Content $logFile "Alert: Suspicious entry found - $entry"
                }
            }
        }
#Section 8: return the result of the action
        Write-Host "Registry checked. Review $logFile for any changes or suspicious entries."
    } else {
        Write-Host "No baseline found. Please run the script and choose 'save' to create one."
    }
} else {
    Write-Host "Invalid input. Please type 'save' or 'check'."
}
