# Windows Health Check Script

$results = @{}

#  1. Check IIS Service
try {
    $service = Get-Service -Name "W3SVC" -ErrorAction Stop
    if ($service.Status -eq "Running") {
        $results["ServiceStatus"] = "W3SVC is RUNNING"
    } else {
        $results["ServiceStatus"] = "W3SVC is STOPPED"
    }
} catch {
    $results["ServiceStatus"] = "W3SVC NOT FOUND"
}

#  2. Check Website Response
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        $results["WebStatus"] = "Website OK (200)"
    } else {
        $results["WebStatus"] = "Website Error: $($response.StatusCode)"
    }
} catch {
    $results["WebStatus"] = "Website DOWN"
}

#  3. CPU Usage
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$results["CPU"] = "$cpu % CPU Load"

#  4. Memory
$os = Get-CimInstance Win32_OperatingSystem
$total = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
$free  = [math]::Round(($os.FreePhysicalMemory / 1MB), 2)
$used  = $total - $free
$results["Memory"] = "$used GB / $total GB Used"

#  5. Disk C:
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB  = [math]::Round(($disk.FreeSpace / 1GB), 2)
$totalGB = [math]::Round(($disk.Size / 1GB), 2)
$results["Disk"] = "$freeGB GB free of $totalGB GB"

#  OUTPUT JSON (critical!)
$results | ConvertTo-Json -Depth 5
