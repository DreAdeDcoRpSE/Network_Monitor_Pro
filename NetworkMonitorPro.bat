@echo off
setlocal enabledelayedexpansion

:START
cls
title Network Monitor Pro - Ping ^& Traceroute Tool v2.0

echo.
echo  ============================================================
echo           NETWORK MONITOR PRO - v2.0
echo  ============================================================
echo.
echo  This professional network monitoring tool provides:
echo.
echo    ^> Real-time latency monitoring with visual graphs
echo    ^> Packet loss tracking and statistics
echo    ^> Jitter calculation (latency variation)
echo    ^> Periodic background traceroutes
echo    ^> Detailed logging to CSV and TXT formats
echo    ^> DNS resolution verification
echo    ^> Color-coded performance indicators
echo    ^> Path Monitor mode (shows all hops!)
echo.
echo  ============================================================
echo  ^>^> Created by Derek 'coRpSE' McGuire, ^(c^) headshotdomain.net ^<^<
echo  ============================================================
echo.
echo  Enter hostname, domain, or IP address to monitor:
echo  Examples: google.com, 8.8.8.8, github.com
echo.
set /p TARGET=  Target:

if "%TARGET%"=="" (
    echo.
    echo  [ERROR] No target entered.
    echo.
    pause
    goto START
)

:: Strip out http:// or https:// if user included it
set TARGET=%TARGET:https://=%
set TARGET=%TARGET:http://=%
set TARGET=%TARGET:/=%

echo.
echo  Validating target...

:: Quick validation ping
ping -n 1 -w 2000 %TARGET% >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [WARNING] Target "%TARGET%" may be unreachable or blocking ICMP.
    echo  Some websites/servers block ping requests for security.
    echo.
    echo  Do you want to continue anyway? (Y/N^)
    set /p CONTINUE=  Choice:
    if /i not "!CONTINUE!"=="Y" goto START
)

echo.
echo  ============================================================
echo           MONITORING MODE
echo  ============================================================
echo.
echo    1. Standard       (Ping every 1 second)
echo    2. Fast           (Ping every 0.5 seconds) [31m*Not really recommended.[0m
echo    3. Slow           (Ping every 2 seconds)
echo    4. Custom         (Specify interval)
echo    5. Path Monitor   (Ping every hop in the route)
echo.
set /p MODECHOICE=  Select mode (1-5):

if "%MODECHOICE%"=="1" set INTERVAL=1 & set MONITOR_MODE=dest
if "%MODECHOICE%"=="2" set INTERVAL=0.5 & set MONITOR_MODE=dest
if "%MODECHOICE%"=="3" set INTERVAL=2 & set MONITOR_MODE=dest
if "%MODECHOICE%"=="4" (
    echo.
    set CUSTOM_INTER=1
    set /p CUSTOM_INTER=  Enter interval in seconds (0.5-10^):
    :: Validate: must be number between 0.5 and 10
    powershell -c "if([double]::TryParse('!CUSTOM_INTER!', [ref]$null) -and [double]'!CUSTOM_INTER!' -ge 0.5 -and [double]'!CUSTOM_INTER!' -le 10) { exit 0 } else { exit 1 }" 2>nul
    if errorlevel 1 (
        echo.
        echo  [WARNING] Invalid interval. Using default 1 second.
        set INTERVAL=1
    ) else (
        set INTERVAL=!CUSTOM_INTER!
    )
    set MONITOR_MODE=dest
)
if "%MODECHOICE%"=="5" set MONITOR_MODE=path

if not defined MONITOR_MODE set MONITOR_MODE=dest
if not defined INTERVAL set INTERVAL=1

:: =========================================
:: DURATION OPTIONS - CONTEXT AWARE
:: =========================================
echo.
echo  ============================================================
echo           MONITORING DURATION OPTIONS
echo  ============================================================
echo  ============================================================
echo  Note: traceroute takes about 10 - 20 seconds to start.
echo        The timing below already includes that delay.
echo  ============================================================
echo.

if "%MONITOR_MODE%"=="path" goto :DUR_PATH
goto :DUR_DEST

:DUR_PATH
    echo    1. Short Test      [93m(About 30 seconds)[0m
    echo    2. Medium Test     [93m(About 1 minute)[0m
    echo    3. Long Test       [93m(About 2 minutes)[0m
    echo    4. Extended Test   [93m(About 5 minutes)[0m
    echo    5. Marathon Test   [93m(About 10 minutes)[0m
    echo    6. Continuous      [93m(Manual stop with CTRL+C)[0m
    echo.
    set /p DURATION=  Select option (1-6):
    if "%DURATION%"=="1" set SECONDS=45
    if "%DURATION%"=="2" set SECONDS=80
    if "%DURATION%"=="3" set SECONDS=140
    if "%DURATION%"=="4" set SECONDS=320
    if "%DURATION%"=="5" set SECONDS=620
    if "%DURATION%"=="6" set SECONDS=0
    goto :DUR_END

:DUR_DEST
    echo    1. Quick Test      [93m(15 seconds)[0m
    echo    2. Short Test      [93m(30 seconds)[0m
    echo    3. Medium Test     [93m(1 minute)[0m
    echo    4. Long Test       [93m(2 minutes)[0m
    echo    5. Extended Test   [93m(5 minutes)[0m
    echo    6. Marathon Test   [93m(10 minutes)[0m
    echo    7. Continuous      [93m(Manual stop with CTRL+C)[0m
    echo.
    set /p DURATION=  Select option (1-7):
    if "%DURATION%"=="1" set SECONDS=15
    if "%DURATION%"=="2" set SECONDS=30
    if "%DURATION%"=="3" set SECONDS=60
    if "%DURATION%"=="4" set SECONDS=120
    if "%DURATION%"=="5" set SECONDS=300
    if "%DURATION%"=="6" set SECONDS=600
    if "%DURATION%"=="7" set SECONDS=0

:DUR_END

if not defined SECONDS (
    echo.
    echo  [ERROR] Invalid option selected.
    echo.
    pause
    goto START
)

echo.
echo  Starting monitoring...
timeout /t 1 /nobreak >nul

:: =========================================
:: Create temporary PowerShell script
:: =========================================
set PSFILE=%TEMP%\_netmonitor_temp.ps1

> "%PSFILE%" echo param([string]$Target, [int]$Duration, [double]$Interval, [string]$Mode)
>>"%PSFILE%" echo.
>>"%PSFILE%" echo $ErrorActionPreference = 'Continue' # Changed from SilentlyContinue to see errors
>>"%PSFILE%" echo $startTime = Get-Date
>>"%PSFILE%" echo $timestamp = Get-Date -Format "yyyy-MM-dd__hh-mm-ss.tt"
>>"%PSFILE%" echo.
>>"%PSFILE%" echo # Create main results directory
>>"%PSFILE%" echo $mainResultsDir = "NetworkMonitorPro_Results"
>>"%PSFILE%" echo if (-not (Test-Path $mainResultsDir)) {
>>"%PSFILE%" echo     New-Item -ItemType Directory -Path $mainResultsDir ^| Out-Null
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo # Determine log file paths based on mode
>>"%PSFILE%" echo if($Mode -eq 'path'){
>>"%PSFILE%" echo     $logGraphDir = "NetMonitor_${Target}_${timestamp}"
>>"%PSFILE%" echo     $fullLogGraphDir = Join-Path $mainResultsDir $logGraphDir
>>"%PSFILE%" echo     # Create directory for graphs and logs
>>"%PSFILE%" echo     if (-not (Test-Path $fullLogGraphDir)) {
>>"%PSFILE%" echo         New-Item -ItemType Directory -Path $fullLogGraphDir ^| Out-Null
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     $logTxt = Join-Path $fullLogGraphDir "NetMonitor_${Target}_${timestamp}.txt"
>>"%PSFILE%" echo     $logCsv = Join-Path $fullLogGraphDir "NetMonitor_${Target}_${timestamp}.csv"
>>"%PSFILE%" echo     # Initial CSV header
>>"%PSFILE%" echo     "Timestamp,Hop,IP,Latency_ms,Status" ^| Out-File $logCsv
>>"%PSFILE%" echo } else {
>>"%PSFILE%" echo     $logDir = "PingTest_${Target}_${timestamp}"
>>"%PSFILE%" echo     $fullLogDir = Join-Path $mainResultsDir $logDir
>>"%PSFILE%" echo     # Create directory for logs
>>"%PSFILE%" echo     if (-not (Test-Path $fullLogDir)) {
>>"%PSFILE%" echo         New-Item -ItemType Directory -Path $fullLogDir ^| Out-Null
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     $logTxt = Join-Path $fullLogDir "PingTest_${Target}_${timestamp}.txt"
>>"%PSFILE%" echo     $logCsv = Join-Path $fullLogDir "PingTest_${Target}_${timestamp}.csv"
>>"%PSFILE%" echo     "Timestamp,PingNumber,Latency_ms,Status,PacketLoss" ^| Out-File $logCsv
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo "Network Monitor Pro - Log File" ^| Out-File $logTxt
>>"%PSFILE%" echo "================================" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "Target: $Target" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "Mode: $(if($Mode -eq 'path'){'Path Monitor'}else{'Destination Only'})" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "".PadRight(80, '=') ^| Out-File $logTxt -Append
>>"%PSFILE%" echo.
>>"%PSFILE%" echo Write-Host "`nResolving DNS for $Target..." -ForegroundColor Cyan
>>"%PSFILE%" echo try {
>>"%PSFILE%" echo     $resolvedIP = [System.Net.Dns]::GetHostAddresses($Target) ^| Select-Object -First 1
>>"%PSFILE%" echo     Write-Host "Resolved to: $($resolvedIP.IPAddressToString)" -ForegroundColor Green
>>"%PSFILE%" echo     "DNS Resolution: $($resolvedIP.IPAddressToString)" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo } catch {
>>"%PSFILE%" echo     Write-Host "Could not resolve DNS (continuing anyway)" -ForegroundColor Yellow
>>"%PSFILE%" echo     "DNS Resolution: Failed" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo }
>>"%PSFILE%" echo "" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo.
>>"%PSFILE%" echo function RunTrace {
>>"%PSFILE%" echo     Start-Job -ScriptBlock {
>>"%PSFILE%" echo         param($tgt, $logfile)
>>"%PSFILE%" echo         $output = tracert.exe -h 15 $tgt 2^>^&1
>>"%PSFILE%" echo         "" ^| Out-File $logfile -Append
>>"%PSFILE%" echo         "===== Traceroute $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =====" ^| Out-File $logfile -Append
>>"%PSFILE%" echo         $output ^| Out-File $logfile -Append
>>"%PSFILE%" echo         "".PadRight(80, '-') ^| Out-File $logfile -Append
>>"%PSFILE%" echo     } -ArgumentList $Target, $logTxt ^| Out-Null
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo function Calculate-Jitter($values) {
>>"%PSFILE%" echo     if($values.Count -lt 2){ return 0 }
>>"%PSFILE%" echo     $validVals = $values ^| Where-Object { $_ -gt 0 }
>>"%PSFILE%" echo     if($validVals.Count -lt 2){ return 0 }
>>"%PSFILE%" echo     $differences = @()
>>"%PSFILE%" echo     for($i = 1; $i -lt $validVals.Count; $i++){
>>"%PSFILE%" echo         $differences += [math]::Abs($validVals[$i] - $validVals[$i-1])
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     return [math]::Round(($differences ^| Measure-Object -Average).Average, 2)
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo function Graph($vals, $showCount = 20) {
>>"%PSFILE%" echo     if($vals.Count -eq 0){ return }
>>"%PSFILE%" echo     $validVals = $vals ^| Where-Object { $_ -gt 0 }
>>"%PSFILE%" echo     if($validVals.Count -eq 0){
>>"%PSFILE%" echo         Write-Host "`n  All pings timed out - no graph available" -ForegroundColor Red
>>"%PSFILE%" echo         return
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     $max = ($validVals ^| Measure-Object -Maximum).Maximum
>>"%PSFILE%" echo     $min = ($validVals ^| Measure-Object -Minimum).Minimum
>>"%PSFILE%" echo     $avg = [math]::Round(($validVals ^| Measure-Object -Average).Average, 2)
>>"%PSFILE%" echo     $jitter = Calculate-Jitter $vals
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     Write-Host "`n  LATENCY STATISTICS:" -ForegroundColor Cyan
>>"%PSFILE%" echo     Write-Host "  ".PadRight(50, '-') -ForegroundColor DarkGray
>>"%PSFILE%" echo     Write-Host ("  Min: {0,6} ms  ^| Max: {1,6} ms" -f $min, $max) -ForegroundColor White
>>"%PSFILE%" echo     Write-Host ("  Avg: {0,6} ms  ^| Jitter: {1,6} ms" -f $avg, $jitter) -ForegroundColor White
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     Write-Host "  LATENCY GRAPH (last $showCount pings):" -ForegroundColor Cyan
>>"%PSFILE%" echo     Write-Host "  ".PadRight(50, '-') -ForegroundColor DarkGray
>>"%PSFILE%" echo     $displayCount = [math]::Min($vals.Count, $showCount)
>>"%PSFILE%" echo     $startIdx = [math]::Max(0, $vals.Count - $displayCount)
>>"%PSFILE%" echo     for($idx = $startIdx; $idx -lt $vals.Count; $idx++){
>>"%PSFILE%" echo         $v = $vals[$idx]
>>"%PSFILE%" echo         $pingNum = $idx + 1
>>"%PSFILE%" echo         if($v -eq 0){
>>"%PSFILE%" echo             Write-Host ("  #{0,-3} {1,7} ^| " -f $pingNum, "TIMEOUT") -NoNewline
>>"%PSFILE%" echo             Write-Host "X" -ForegroundColor Red
>>"%PSFILE%" echo         } else {
>>"%PSFILE%" echo             $scaled = [math]::Ceiling($v / ($max / 40))
>>"%PSFILE%" echo             if($scaled -lt 1){ $scaled = 1 }
>>"%PSFILE%" echo             $bar = "#" * $scaled
>>"%PSFILE%" echo             Write-Host ("  #{0,-3} {1,4} ms ^| " -f $pingNum, $v) -NoNewline
>>"%PSFILE%" echo             if($v -lt 30){ Write-Host $bar -ForegroundColor Green }
>>"%PSFILE%" echo             elseif($v -lt 80){ Write-Host $bar -ForegroundColor Yellow }
>>"%PSFILE%" echo             elseif($v -lt 150){ Write-Host $bar -ForegroundColor DarkYellow }
>>"%PSFILE%" echo             else{ Write-Host $bar -ForegroundColor Red }
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo function LogDestPing($num, $lat, $status, $lossPercent){
>>"%PSFILE%" echo     $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
>>"%PSFILE%" echo     "$t  Ping #$num : $lat ms  ($status)" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo     "$t,$num,$lat,$status,$lossPercent" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo # Function to generate final path graph from CSV with improved size and appearance
>>"%PSFILE%" echo function Generate-PathGraphFromCSV($csvFile, $graphDir, $target, $theme = "light") {
>>"%PSFILE%" echo     # Read the CSV file, skipping the initial header and any separator lines
>>"%PSFILE%" echo     $allDataLines = Get-Content $csvFile
>>"%PSFILE%" echo     $csvData = @()
>>"%PSFILE%" echo     $inDataSection = $false
>>"%PSFILE%" echo     foreach ($line in $allDataLines) {
>>"%PSFILE%" echo         # Check if the line is the header
>>"%PSFILE%" echo         if ($line.Trim() -eq "Timestamp,Hop,IP,Latency_ms,Status") {
>>"%PSFILE%" echo             $inDataSection = $true
>>"%PSFILE%" echo             continue
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         # Check if the line is a separator or comment (starts with # or ---)
>>"%PSFILE%" echo         if ($line -match "^\s*#.*$") {
>>"%PSFILE%" echo             $inDataSection = $false # Stop reading if it's a comment like # Cycle Start
>>"%PSFILE%" echo             continue
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if ($line -match "^\s*-+$") { # Matches lines of just dashes
>>"%PSFILE%" echo             continue # Skip separator lines
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if ($inDataSection -and $line.Trim() -ne "") {
>>"%PSFILE%" echo             # Parse the CSV line manually (simpler for fixed format)
>>"%PSFILE%" echo             $fields = $line -split ',', 5 # Split into max 5 parts to handle commas in status if needed
>>"%PSFILE%" echo             if ($fields.Count -eq 5) {
>>"%PSFILE%" echo                 $csvData += [PSCustomObject]@{
>>"%PSFILE%" echo                     Timestamp  = $fields[0].Trim()
>>"%PSFILE%" echo                     Hop        = $fields[1].Trim()
>>"%PSFILE%" echo                     IP         = $fields[2].Trim()
>>"%PSFILE%" echo                     Latency_ms = $fields[3].Trim()
>>"%PSFILE%" echo                     Status     = $fields[4].Trim()
>>"%PSFILE%" echo                 }
>>"%PSFILE%" echo             }
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     # Filter out initial header lines that might have been captured accidentally
>>"%PSFILE%" echo     $csvData = $csvData ^| Where-Object { $_.Timestamp -match "^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$" }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     if ($csvData.Count -eq 0) {
>>"%PSFILE%" echo         Write-Host "No valid data found in CSV for graphing." -ForegroundColor Yellow
>>"%PSFILE%" echo         return
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     # Generate filename based on target and end time
>>"%PSFILE%" echo     $endTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
>>"%PSFILE%" echo     $graphFile = Join-Path $graphDir "PathGraph_Final_${target}_${theme}_${endTimestamp}.png"
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     Add-Type -AssemblyName System.Windows.Forms.DataVisualization
>>"%PSFILE%" echo     # Create the chart object
>>"%PSFILE%" echo     $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
>>"%PSFILE%" echo     $chart.Width = 1600
>>"%PSFILE%" echo     $chart.Height = 1000
>>"%PSFILE%" echo     if($theme -eq "dark") {
>>"%PSFILE%" echo         $chart.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
>>"%PSFILE%" echo     } else {
>>"%PSFILE%" echo         $chart.BackColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     # Add a title
>>"%PSFILE%" echo     $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
>>"%PSFILE%" echo     $title.Text = "Path Monitor Final Graph for $target"
>>"%PSFILE%" echo     $title.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
>>"%PSFILE%" echo     $title.Alignment = [System.Drawing.StringAlignment]::Center
>>"%PSFILE%" echo     $chart.Titles.Add($title)
>>"%PSFILE%" echo     if($theme -eq "dark") {
>>"%PSFILE%" echo         $title.ForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
>>"%PSFILE%" echo     $chart.ChartAreas.Add($chartArea)
>>"%PSFILE%" echo     $chartArea.AxisX.Title = "Time (HH:mm:ss)"
>>"%PSFILE%" echo     $chartArea.AxisY.Title = "Latency (ms)"
>>"%PSFILE%" echo     $chartArea.AxisY.TitleFont = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
>>"%PSFILE%" echo     $chartArea.AxisX.TitleFont = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
>>"%PSFILE%" echo     $chartArea.AxisX.IntervalType = [System.Windows.Forms.DataVisualization.Charting.DateTimeIntervalType]::Seconds
>>"%PSFILE%" echo     $chartArea.AxisX.LabelStyle.Format = "HH:mm:ss"
>>"%PSFILE%" echo     $chartArea.AxisX.LabelStyle.Font = New-Object System.Drawing.Font("Arial", 10)
>>"%PSFILE%" echo     $chartArea.AxisY.LabelStyle.Font = New-Object System.Drawing.Font("Arial", 10)
>>"%PSFILE%" echo     if($theme -eq "dark") {
>>"%PSFILE%" echo         $chartArea.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
>>"%PSFILE%" echo         $chartArea.AxisX.LabelStyle.ForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo         $chartArea.AxisY.LabelStyle.ForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo         $chartArea.AxisX.TitleForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo         $chartArea.AxisY.TitleForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo         $chartArea.AxisX.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
>>"%PSFILE%" echo         $chartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     # Set minimum and maximum for Y-axis based on data
>>"%PSFILE%" echo     $validLatencies = $csvData ^| Where-Object { $_.Latency_ms -ne "TIMEOUT" -and $_.Latency_ms -ne "FAILED" -and $_.Latency_ms -ne "SUCCESS" } ^| ForEach-Object { [double]$_.Latency_ms }
>>"%PSFILE%" echo     if ($validLatencies.Count -gt 0) {
>>"%PSFILE%" echo         $maxLatency = ($validLatencies ^| Measure-Object -Maximum).Maximum
>>"%PSFILE%" echo         $chartArea.AxisY.Maximum = [math]::Ceiling($maxLatency * 1.1) # Add 10% margin
>>"%PSFILE%" echo         $chartArea.AxisY.Minimum = 0
>>"%PSFILE%" echo     } else {
>>"%PSFILE%" echo         $chartArea.AxisY.Maximum = 100
>>"%PSFILE%" echo         $chartArea.AxisY.Minimum = 0
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
>>"%PSFILE%" echo     $legend.Name = "HopLegend"
>>"%PSFILE%" echo     $legend.Font = New-Object System.Drawing.Font("Arial", 14)
>>"%PSFILE%" echo     $legend.Docking = [System.Windows.Forms.DataVisualization.Charting.Docking]::Right
>>"%PSFILE%" echo     $chart.Legends.Add($legend)
>>"%PSFILE%" echo     if($theme -eq "dark") {
>>"%PSFILE%" echo         $legend.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
>>"%PSFILE%" echo         $legend.ForeColor = [System.Drawing.Color]::White
>>"%PSFILE%" echo         $legend.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     # Group data by IP
>>"%PSFILE%" echo     $groupedData = $csvData ^| Group-Object IP
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     if($theme -eq "dark") {
>>"%PSFILE%" echo       $colors = @(
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(145,255,145),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 100, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(0,255, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(140, 0, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 150, 0),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(0, 255, 20),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(150, 255, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 50, 150)
>>"%PSFILE%" echo       )
>>"%PSFILE%" echo     } else {
>>"%PSFILE%" echo       $colors = @(
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(0, 100, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(0, 200, 100),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 150, 0),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 0, 100),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(120, 0, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(0, 255, 255),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(204, 170, 0),
>>"%PSFILE%" echo           [System.Drawing.Color]::FromArgb(255, 100, 200)
>>"%PSFILE%" echo       )
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     $colorIndex = 0
>>"%PSFILE%" echo     foreach ($group in $groupedData) {
>>"%PSFILE%" echo         $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
>>"%PSFILE%" echo         $series.Name = $group.Name
>>"%PSFILE%" echo         $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::FastLine
>>"%PSFILE%" echo         $series.MarkerStyle = [System.Windows.Forms.DataVisualization.Charting.MarkerStyle]::Circle
>>"%PSFILE%" echo         $series.MarkerSize = 6
>>"%PSFILE%" echo         $series.BorderWidth = 3
>>"%PSFILE%" echo         $series.Color = $colors[$colorIndex %% $colors.Count]
>>"%PSFILE%" echo         $chart.Series.Add($series)
>>"%PSFILE%" echo         $colorIndex++
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         foreach ($point in $group.Group) {
>>"%PSFILE%" echo             if ($point.Latency_ms -ne "TIMEOUT" -and $point.Latency_ms -ne "FAILED" -and $point.Latency_ms -ne "SUCCESS") {
>>"%PSFILE%" echo                 $latencyValue = [double]$point.Latency_ms
>>"%PSFILE%" echo                 # Convert string timestamp to DateTime object
>>"%PSFILE%" echo                 $timeValue = [System.DateTime]::ParseExact($point.Timestamp, "yyyy-MM-dd HH:mm:ss", $null)
>>"%PSFILE%" echo                 [void]$series.Points.AddXY($timeValue, $latencyValue)
>>"%PSFILE%" echo             }
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     # Attempt to save using the standard SaveImage method (usually works better in scripts)
>>"%PSFILE%" echo     try {
>>"%PSFILE%" echo         $chart.SaveImage($graphFile, [System.Drawing.Imaging.ImageFormat]::Png)
>>"%PSFILE%" echo         Write-Host "Final Path Graph saved: $graphFile" -ForegroundColor Green
>>"%PSFILE%" echo     } catch {
>>"%PSFILE%" echo         Write-Host "Error saving graph using standard method: $($_.Exception.Message)" -ForegroundColor Red
>>"%PSFILE%" echo         Write-Host "Trying bitmap method..." -ForegroundColor Yellow
>>"%PSFILE%" echo         # Fallback to bitmap method if SaveImage fails
>>"%PSFILE%" echo         try {
>>"%PSFILE%" echo             $bitmap = New-Object System.Drawing.Bitmap($chart.Width, $chart.Height)
>>"%PSFILE%" echo             $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
>>"%PSFILE%" echo             $graphics.Clear([System.Drawing.Color]::White)
>>"%PSFILE%" echo             $chart.Draw($graphics)
>>"%PSFILE%" echo             $bitmap.Save($graphFile, [System.Drawing.Imaging.ImageFormat]::Png)
>>"%PSFILE%" echo             Write-Host "Final Path Graph saved (using bitmap method): $graphFile" -ForegroundColor Green
>>"%PSFILE%" echo             $graphics.Dispose()
>>"%PSFILE%" echo             $bitmap.Dispose()
>>"%PSFILE%" echo         } catch {
>>"%PSFILE%" echo             Write-Host "Failed to save graph using both methods. Error: $($_.Exception.Message)" -ForegroundColor Red
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     # Clean up chart resources
>>"%PSFILE%" echo     $chart.Dispose()
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo if($Mode -eq 'path'){
>>"%PSFILE%" echo     Write-Host "`nDiscovering route to $Target..." -ForegroundColor Cyan
>>"%PSFILE%" echo     $trace = tracert.exe -d -h 30 -w 1000 $Target 2^>^$null ^| Where-Object { $_ -match '^\s*\d+\s+.*\d+\.\d+\.\d+\.\d+' }
>>"%PSFILE%" echo     $hops = @()
>>"%PSFILE%" echo     foreach($line in $trace){
>>"%PSFILE%" echo         $hopNum = ($line -split '\s+')[1]
>>"%PSFILE%" echo         $tokens = $line -split '\s+'
>>"%PSFILE%" echo         $ip = $null
>>"%PSFILE%" echo         for($i = $tokens.Count - 1; $i -ge 0; $i--){
>>"%PSFILE%" echo             if($tokens[$i] -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'){
>>"%PSFILE%" echo                 $octets = $tokens[$i] -split '\.'
>>"%PSFILE%" echo                 if($octets.Count -eq 4 -and ($octets ^| ForEach-Object { [int]$_ -ge 0 -and [int]$_ -le 255 }) -notcontains $false){
>>"%PSFILE%" echo                     $ip = $tokens[$i]
>>"%PSFILE%" echo                     break
>>"%PSFILE%" echo                 }
>>"%PSFILE%" echo             }
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if($ip -and $hopNum -match '^\d+$'){
>>"%PSFILE%" echo             $hops += [PSCustomObject]@{Hop=$hopNum; IP=$ip}
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     if($hops.Count -eq 0){
>>"%PSFILE%" echo         Write-Host "`n[ERROR] Could not determine route to $Target." -ForegroundColor Red
>>"%PSFILE%" echo         Write-Host "Falling back to destination-only mode." -ForegroundColor Yellow
>>"%PSFILE%" echo         Start-Sleep -Seconds 2
>>"%PSFILE%" echo         $Mode = 'dest'
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo     if($Mode -eq 'path'){
>>"%PSFILE%" echo         Write-Host "`nMonitoring $(($hops.Count)) hops..." -ForegroundColor Green
>>"%PSFILE%" echo         Start-Sleep -Seconds 1
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         # Initialize stats per hop
>>"%PSFILE%" echo         $hopStats = @{}
>>"%PSFILE%" echo         foreach($h in $hops){ $hopStats[$h.IP] = @{Sent=0; Recv=0; TotalMs=0; LastLat=0} }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         # Store ALL data for graphing
>>"%PSFILE%" echo         $allGraphData = @()
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         while($true){
>>"%PSFILE%" echo             $elapsed = ((Get-Date) - $startTime).TotalSeconds
>>"%PSFILE%" echo             if($Duration -gt 0 -and $elapsed -ge $Duration){ break }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             # Add a separator and header for this cycle in the CSV
>>"%PSFILE%" echo             "".PadRight(80, '-') ^| Out-File $logCsv -Append
>>"%PSFILE%" echo             $cycleTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
>>"%PSFILE%" echo             "# Cycle Start: $cycleTimestamp" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo             "Timestamp,Hop,IP,Latency_ms,Status" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             Clear-Host
>>"%PSFILE%" echo             Write-Host "`n  ============================================================" -ForegroundColor Cyan
>>"%PSFILE%" echo             Write-Host "              PATH MONITOR - LIVE VIEW" -ForegroundColor Cyan
>>"%PSFILE%" echo             Write-Host "  ============================================================" -ForegroundColor Cyan
>>"%PSFILE%" echo             Write-Host ("  Target: {0,-25}  Interval: {1}s" -f $Target, $Interval) -ForegroundColor White
>>"%PSFILE%" echo             if($Duration -gt 0){
>>"%PSFILE%" echo                 $remaining = [math]::Max(0, $Duration - $elapsed)
>>"%PSFILE%" echo                 Write-Host ("  Time Remaining: {0} seconds" -f [math]::Round($remaining, 1)) -ForegroundColor Gray
>>"%PSFILE%" echo             } else {
>>"%PSFILE%" echo                 Write-Host "  Mode: Continuous Path Monitoring" -ForegroundColor Gray
>>"%PSFILE%" echo             }
>>"%PSFILE%" echo             Write-Host ""
>>"%PSFILE%" echo             Write-Host "  HOP  IP ADDRESS        LATEST    AVG     LOSS    STATUS" -ForegroundColor Cyan
>>"%PSFILE%" echo             Write-Host "  --------------------------------------------------------" -ForegroundColor DarkGray
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             $cycleHopData = @()
>>"%PSFILE%" echo             foreach($h in $hops){
>>"%PSFILE%" echo                 $ip = $h.IP
>>"%PSFILE%" echo                 $hopNum = $h.Hop
>>"%PSFILE%" echo.
>>"%PSFILE%" echo                 # Ping this hop once
>>"%PSFILE%" echo                 $pingOutput = (ping.exe -n 1 -w 2000 $ip 2>&1) -join "`n"
>>"%PSFILE%" echo                 $hopStats[$ip].Sent++
>>"%PSFILE%" echo                 $t_log = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
>>"%PSFILE%" echo.
>>"%PSFILE%" echo                 if($pingOutput -match "time[=<](\d+)ms"){
>>"%PSFILE%" echo                     $lat = [int]$matches[1]
>>"%PSFILE%" echo                     $hopStats[$ip].Recv++
>>"%PSFILE%" echo                     $hopStats[$ip].TotalMs += $lat
>>"%PSFILE%" echo                     $hopStats[$ip].LastLat = $lat
>>"%PSFILE%" echo                     "$t_log  Hop $hopNum ($ip): $lat ms  (SUCCESS)" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo                     "$t_log,$hopNum,$ip,$lat,SUCCESS" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo                     $latencyToShow = $lat
>>"%PSFILE%" echo                     $statusToShow = "OK"
>>"%PSFILE%" echo                     # Add to cycle data for potential graphing (though not used now)
>>"%PSFILE%" echo                     $cycleHopData += [PSCustomObject]@{
>>"%PSFILE%" echo                         Timestamp = $t_log
>>"%PSFILE%" echo                         Hop = $hopNum
>>"%PSFILE%" echo                         IP = $ip
>>"%PSFILE%" echo                         Latency_ms = $lat
>>"%PSFILE%" echo                         Status = "SUCCESS"
>>"%PSFILE%" echo                     }
>>"%PSFILE%" echo                 } elseif($pingOutput -match "time<1ms"){
>>"%PSFILE%" echo                     $lat = 1
>>"%PSFILE%" echo                     $hopStats[$ip].Recv++
>>"%PSFILE%" echo                     $hopStats[$ip].TotalMs += $lat
>>"%PSFILE%" echo                     $hopStats[$ip].LastLat = $lat
>>"%PSFILE%" echo                     "$t_log  Hop $hopNum ($ip): $lat ms  (SUCCESS)" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo                     "$t_log,$hopNum,$ip,$lat,SUCCESS" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo                     $latencyToShow = $lat
>>"%PSFILE%" echo                     $statusToShow = "OK"
>>"%PSFILE%" echo                     # Add to cycle data for potential graphing (though not used now)
>>"%PSFILE%" echo                     $cycleHopData += [PSCustomObject]@{
>>"%PSFILE%" echo                         Timestamp = $t_log
>>"%PSFILE%" echo                         Hop = $hopNum
>>"%PSFILE%" echo                         IP = $ip
>>"%PSFILE%" echo                         Latency_ms = $lat
>>"%PSFILE%" echo                         Status = "SUCCESS"
>>"%PSFILE%" echo                     }
>>"%PSFILE%" echo                 } else {
>>"%PSFILE%" echo                     "$t_log  Hop $hopNum ($ip): TIMEOUT  (FAILED)" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo                     "$t_log,$hopNum,$ip,TIMEOUT,FAILED" ^| Out-File $logCsv -Append
>>"%PSFILE%" echo                     $latencyToShow = 0
>>"%PSFILE%" echo                     $statusToShow = "TIMEOUT"
>>"%PSFILE%" echo                     # Add to cycle data for potential graphing (though not used now)
>>"%PSFILE%" echo                     $cycleHopData += [PSCustomObject]@{
>>"%PSFILE%" echo                         Timestamp = $t_log
>>"%PSFILE%" echo                         Hop = $hopNum
>>"%PSFILE%" echo                         IP = $ip
>>"%PSFILE%" echo                         Latency_ms = "TIMEOUT"
>>"%PSFILE%" echo                         Status = "FAILED"
>>"%PSFILE%" echo                     }
>>"%PSFILE%" echo                 }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo                 # Calculate stats
>>"%PSFILE%" echo                 $sent = $hopStats[$ip].Sent
>>"%PSFILE%" echo                 $recv = $hopStats[$ip].Recv
>>"%PSFILE%" echo                 $avg = if($recv -gt 0){ [math]::Round($hopStats[$ip].TotalMs / $recv, 1) } else { 0 }
>>"%PSFILE%" echo                 $loss = if($sent -gt 0){ [math]::Round(100 * ($sent - $recv) / $sent, 1) } else { 0 }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo                 # Color logic
>>"%PSFILE%" echo                 if($statusToShow -eq "TIMEOUT"){
>>"%PSFILE%" echo                     Write-Host ("  {0,-4} {1,-15} TIMEOUT   -       {2,5}%   TIMEOUT" -f $hopNum, $ip, $loss) -ForegroundColor Red
>>"%PSFILE%" echo                 } else {
>>"%PSFILE%" echo                     $latColor = "Green"
>>"%PSFILE%" echo                     if($latencyToShow -ge 150){ $latColor = "Red" }
>>"%PSFILE%" echo                     elseif($latencyToShow -ge 80){ $latColor = "Yellow" }
>>"%PSFILE%" echo                     elseif($latencyToShow -ge 30){ $latColor = "DarkYellow" }
>>"%PSFILE%" echo                     $lossColor = if($loss -lt 5){"White"}elseif($loss -lt 15){"Yellow"}else{"Red"}
>>"%PSFILE%" echo                     Write-Host ("  {0,-4} {1,-15}" -f $hopNum, $ip) -NoNewline -ForegroundColor White
>>"%PSFILE%" echo                     Write-Host ("{0,6} ms " -f $latencyToShow) -NoNewline -ForegroundColor $latColor
>>"%PSFILE%" echo                     Write-Host ("{0,7} " -f $avg) -NoNewline -ForegroundColor White
>>"%PSFILE%" echo                     Write-Host ("{0,5}%   OK" -f $loss) -ForegroundColor $lossColor
>>"%PSFILE%" echo                 }
>>"%PSFILE%" echo             }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             # Add cycle data to main graph data array (still kept for potential live graphing if re-enabled)
>>"%PSFILE%" echo             $allGraphData += $cycleHopData
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             # NO GRAPH GENERATION HERE ANYMORE
>>"%PSFILE%" echo             # Generate-PathGraph -allHopData $allGraphData -graphDir $logGraphDir -graphStartTime $startTime
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             Write-Host ""
>>"%PSFILE%" echo             Write-Host "  *** Press CTRL+C to stop monitoring ***" -ForegroundColor Black -BackgroundColor Yellow
>>"%PSFILE%" echo.
>>"%PSFILE%" echo             Start-Sleep -Seconds $Interval
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         # Generate the FINAL comprehensive graph from the CSV file
>>"%PSFILE%" echo         Generate-PathGraphFromCSV -csvFile $logCsv -graphDir $fullLogGraphDir -target $Target -theme "light"
>>"%PSFILE%" echo         Generate-PathGraphFromCSV -csvFile $logCsv -graphDir $fullLogGraphDir -target $Target -theme "dark"
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         # Final summary
>>"%PSFILE%" echo         Clear-Host
>>"%PSFILE%" echo         Write-Host "`n  ============================================================" -ForegroundColor Green
>>"%PSFILE%" echo         Write-Host "              PATH MONITOR COMPLETED" -ForegroundColor Green
>>"%PSFILE%" echo         Write-Host "  ============================================================" -ForegroundColor Green
>>"%PSFILE%" echo         Write-Host ""
>>"%PSFILE%" echo         foreach($h in $hops){
>>"%PSFILE%" echo             $ip = $h.IP
>>"%PSFILE%" echo             $sent = $hopStats[$ip].Sent
>>"%PSFILE%" echo             $recv = $hopStats[$ip].Recv
>>"%PSFILE%" echo             $avg = if($recv -gt 0){ [math]::Round($hopStats[$ip].TotalMs / $recv, 1) } else { 0 }
>>"%PSFILE%" echo             $loss = if($sent -gt 0){ [math]::Round(100 * ($sent - $recv) / $sent, 1) } else { 0 }
>>"%PSFILE%" echo             Write-Host ("  Hop {0}: {1} - Avg: {2} ms, Loss: {3}%" -f $h.Hop, $ip, $avg, $loss) -ForegroundColor $(if($loss -lt 5){"Green"}elseif($loss -lt 15){"Yellow"}else{"Red"})
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo if($Mode -ne 'path'){
>>"%PSFILE%" echo     # ORIGINAL DESTINATION-ONLY MODE
>>"%PSFILE%" echo     $LatencyHistory = @()
>>"%PSFILE%" echo     $HistoryLimit = 60
>>"%PSFILE%" echo     $i = 0
>>"%PSFILE%" echo     $successCount = 0
>>"%PSFILE%" echo     $timeoutCount = 0
>>"%PSFILE%" echo     Write-Host "`nInitializing monitor (traceroute queued in background)...`n" -ForegroundColor Green
>>"%PSFILE%" echo     Start-Sleep -Seconds 1
>>"%PSFILE%" echo     RunTrace
>>"%PSFILE%" echo     while($true){
>>"%PSFILE%" echo         $elapsed = ((Get-Date) - $startTime).TotalSeconds
>>"%PSFILE%" echo         if($Duration -gt 0 -and $elapsed -ge $Duration){ break }
>>"%PSFILE%" echo         Clear-Host
>>"%PSFILE%" echo         Write-Host ""
>>"%PSFILE%" echo         Write-Host "  ============================================================" -ForegroundColor Cyan
>>"%PSFILE%" echo         Write-Host "              NETWORK MONITOR PRO - LIVE VIEW" -ForegroundColor Cyan
>>"%PSFILE%" echo         Write-Host "  ============================================================" -ForegroundColor Cyan
>>"%PSFILE%" echo         Write-Host ("  Target: {0,-30} ^| Interval: {1}s" -f $Target, $Interval) -ForegroundColor White
>>"%PSFILE%" echo         Write-Host ("  Pings: {0,-5}  Success: {1,-5}  Timeouts: {2,-5}" -f $i, $successCount, $timeoutCount) -ForegroundColor White
>>"%PSFILE%" echo         if($i -gt 0){
>>"%PSFILE%" echo             $currentLoss = [math]::Round(($timeoutCount / $i) * 100, 2)
>>"%PSFILE%" echo             $lossColor = "Green"
>>"%PSFILE%" echo             if($currentLoss -ge 15){ $lossColor = "Red" }
>>"%PSFILE%" echo             elseif($currentLoss -ge 5){ $lossColor = "Yellow" }
>>"%PSFILE%" echo             Write-Host "  Packet Loss: " -NoNewline -ForegroundColor White
>>"%PSFILE%" echo             Write-Host "$currentLoss%%" -ForegroundColor $lossColor
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if($Duration -gt 0){
>>"%PSFILE%" echo             $remaining = [math]::Max(0, $Duration - $elapsed)
>>"%PSFILE%" echo             Write-Host ("  Time Remaining: {0} seconds" -f [math]::Round($remaining, 1)) -ForegroundColor Gray
>>"%PSFILE%" echo         } else {
>>"%PSFILE%" echo             Write-Host "  Mode: Continuous monitoring" -ForegroundColor Gray
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         Write-Host ""
>>"%PSFILE%" echo         Write-Host "  *** Press CTRL+C to stop monitoring ***" -ForegroundColor Black -BackgroundColor Yellow
>>"%PSFILE%" echo         Write-Host ""
>>"%PSFILE%" echo.
>>"%PSFILE%" echo         $pingResult = ping.exe -n 1 -w 3000 $Target
>>"%PSFILE%" echo         $replyLine = $pingResult ^| Select-String "Reply from"
>>"%PSFILE%" echo         if($replyLine){
>>"%PSFILE%" echo             if($replyLine.Line -match "time[=<]([0-9]+)ms"){ $lat = [int]$matches[1] }
>>"%PSFILE%" echo             elseif($replyLine.Line -match "time<1ms"){ $lat = 1 }
>>"%PSFILE%" echo             else { $lat = 1 }
>>"%PSFILE%" echo             $LatencyHistory += $lat
>>"%PSFILE%" echo             $successCount++
>>"%PSFILE%" echo             $currentLoss = if($i -gt 0){[math]::Round(($timeoutCount / ($i + 1)) * 100, 2)}else{0}
>>"%PSFILE%" echo             LogDestPing ($i + 1) $lat "SUCCESS" $currentLoss
>>"%PSFILE%" echo             Write-Host "  Latest Ping: " -NoNewline
>>"%PSFILE%" echo             if($lat -lt 30){ $color = "Green"; $status = "Excellent" }
>>"%PSFILE%" echo             elseif($lat -lt 80){ $color = "Yellow"; $status = "Good" }
>>"%PSFILE%" echo             elseif($lat -lt 150){ $color = "DarkYellow"; $status = "Fair" }
>>"%PSFILE%" echo             else{ $color = "Red"; $status = "Poor" }
>>"%PSFILE%" echo             Write-Host "$lat ms" -ForegroundColor $color -NoNewline
>>"%PSFILE%" echo             Write-Host " ($status)" -ForegroundColor Gray
>>"%PSFILE%" echo         } else {
>>"%PSFILE%" echo             $LatencyHistory += 0
>>"%PSFILE%" echo             $timeoutCount++
>>"%PSFILE%" echo             $currentLoss = if($i -gt 0){[math]::Round(($timeoutCount / ($i + 1)) * 100, 2)}else{100}
>>"%PSFILE%" echo             LogDestPing ($i + 1) "TIMEOUT" "FAILED" $currentLoss
>>"%PSFILE%" echo             Write-Host "  Latest Ping: " -NoNewline
>>"%PSFILE%" echo             Write-Host "TIMEOUT" -ForegroundColor Red -NoNewline
>>"%PSFILE%" echo             Write-Host " (Host unreachable or blocking ICMP)" -ForegroundColor Gray
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if($LatencyHistory.Count -gt $HistoryLimit){
>>"%PSFILE%" echo             $LatencyHistory = $LatencyHistory[-$HistoryLimit..-1]
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         if($i %% 40 -eq 0 -and $i -ne 0){
>>"%PSFILE%" echo             Write-Host "`n  [Traceroute queued - results in log file]" -ForegroundColor DarkGray
>>"%PSFILE%" echo             RunTrace
>>"%PSFILE%" echo         }
>>"%PSFILE%" echo         Graph $LatencyHistory
>>"%PSFILE%" echo         $i++
>>"%PSFILE%" echo         Start-Sleep -Seconds $Interval
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     # Final dest summary
>>"%PSFILE%" echo     Clear-Host
>>"%PSFILE%" echo     Write-Host "`n  ============================================================" -ForegroundColor Green
>>"%PSFILE%" echo     Write-Host "              MONITORING COMPLETED" -ForegroundColor Green
>>"%PSFILE%" echo     Write-Host "  ============================================================" -ForegroundColor Green
>>"%PSFILE%" echo     Write-Host ""
>>"%PSFILE%" echo     Write-Host "  Target: $Target" -ForegroundColor White
>>"%PSFILE%" echo     Write-Host "  Duration: $([math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)) seconds" -ForegroundColor White
>>"%PSFILE%" echo     Write-Host "  Total Pings: $i" -ForegroundColor White
>>"%PSFILE%" echo     Write-Host "  Successful: $successCount" -ForegroundColor Green
>>"%PSFILE%" echo     Write-Host "  Timeouts: $timeoutCount" -ForegroundColor Red
>>"%PSFILE%" echo     if($i -gt 0){
>>"%PSFILE%" echo         $lossPercent = [math]::Round(($timeoutCount / $i) * 100, 2)
>>"%PSFILE%" echo         Write-Host "  Packet Loss: $lossPercent%%" -ForegroundColor $(if($lossPercent -lt 5){"Green"}elseif($lossPercent -lt 15){"Yellow"}else{"Red"})
>>"%PSFILE%" echo     }
>>"%PSFILE%" echo     if($LatencyHistory.Count -gt 0){ Graph $LatencyHistory 30 }
>>"%PSFILE%" echo }
>>"%PSFILE%" echo.
>>"%PSFILE%" echo "" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "Monitoring ended: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo "Results saved to: $logTxt, $logCsv" ^| Out-File $logTxt -Append
>>"%PSFILE%" echo if($Mode -eq 'path'){ "Graphs saved to: $fullLogGraphDir" ^| Out-File $logTxt -Append }

:: =========================================
:: Execute PowerShell script
:: =========================================
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%" -Target "%TARGET%" -Duration %SECONDS% -Interval %INTERVAL% -Mode "%MONITOR_MODE%"

:: Cleanup
del "%PSFILE%" >nul 2>&1

:: Ask if user wants to monitor another target
echo.
echo  Would you like to monitor another target? (Y/N)
set /p AGAIN=  Choice:

if /i "%AGAIN%"=="Y" goto START
if /i "%AGAIN%"=="YES" goto START

echo.
echo  Thank you for using Network Monitor Pro!
echo  Check the log files for detailed results.
timeout /t 3 >nul

endlocal
exit /b