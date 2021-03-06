###########################################################################
#
# NAME: 
#
# AUTHOR:  David Johnson
#
# COMMENT: 
#
# VERSION HISTORY:
# 1.0 17-Sep-2012 - Initial release
#
###########################################################################
function Get-SubNetItems 
{ 
<#  
    .SYNOPSIS  
        Scan subnet machines 
         
    .DESCRIPTION  
        Use Get-SubNetItems to receive list of machines in specific IP range. 
 
    .PARAMETER StartScanIP  
        Specify start of IP range. 
 
    .PARAMETER EndScanIP 
        Specify end of IP range. 
 
    .PARAMETER Ports 
        Specify ports numbers to scan if open or not. 
         
    .PARAMETER MaxJobs 
        Specify number of threads to scan. 
         
    .PARAMETER ShowAll 
        Show even adress is inactive. 
     
    .PARAMETER ShowInstantly  
        Show active status of scaned IP address instanly.  
     
    .PARAMETER SleepTime   
        Wait time to check if threads are completed. 
  
    .PARAMETER TimeOut  
        Time out when script will be break. 
 
    .EXAMPLE  
        PS C:\>$Result = Get-SubNetItems -StartScanIP 10.10.10.1 -EndScanIP 10.10.10.10 -ShowInstantly -ShowAll 
        10.10.10.7 is active. 
        10.10.10.10 is active. 
        10.10.10.9 is active. 
        10.10.10.1 is inactive. 
        10.10.10.6 is active. 
        10.10.10.4 is active. 
        10.10.10.3 is inactive. 
        10.10.10.2 is active. 
        10.10.10.5 is active. 
        10.10.10.8 is inactive. 
 
        PS C:\> $Result | Format-Table IP, Active, WMI, WinRM, Host, OS_Name -AutoSize 
 
        IP           Active   WMI WinRM Host              OS_Name 
        --           ------   --- ----- ----              ------- 
        10.10.10.1    False False False 
        10.10.10.2     True  True  True pc02.mydomain.com Microsoft Windows Server 2008 R2 Enterprise 
        10.10.10.3    False False False 
        10.10.10.4     True  True  True pc05.mydomain.com Microsoft Windows Server 2008 R2 Enterprise 
        10.10.10.5     True  True  True pc06.mydomain.com Microsoft Windows Server 2008 R2 Enterprise 
        10.10.10.6     True  True  True pc07.mydomain.com Microsoft(R) Windows(R) Server 2003, Standard Edition 
        10.10.10.7     True False False 
        10.10.10.8    False False False 
        10.10.10.9     True  True False pc09.mydomain.com Microsoft Windows Server 2008 R2 Enterprise 
        10.10.10.10    True  True False pc10.mydomain.com Microsoft Windows XP Professional 
 
    .EXAMPLE  
        PS C:\> Get-SubNetItems -StartScanIP 10.10.10.2 -Verbose 
        VERBOSE: Creating own list class. 
        VERBOSE: Start scaning... 
        VERBOSE: Starting job (1/20) for 10.10.10.2. 
        VERBOSE: Trying get part of data. 
        VERBOSE: Trying get last part of data. 
        VERBOSE: All jobs is not completed (1/20), please wait... (0) 
        VERBOSE: Trying get last part of data. 
        VERBOSE: All jobs is not completed (1/20), please wait... (5) 
        VERBOSE: Trying get last part of data. 
        VERBOSE: All jobs is not completed (1/20), please wait... (10) 
        VERBOSE: Trying get last part of data. 
        VERBOSE: Geting job 10.10.10.2 result. 
        VERBOSE: Removing job 10.10.10.2. 
        VERBOSE: Scan finished. 
 
 
        RunspaceId : d2882105-df8c-4c0a-b92c-0d078bcde752 
        Active     : True 
        Host       : pc02.mydomain.com 
        IP         : 10.10.10.2 
        OS_Name    : Microsoft Windows Server 2008 R2 Enterprise 
        OS_Ver     : 6.1.7601 Service Pack 1 
        WMI        : True 
        WinRM      : True 
         
    .EXAMPLE      
        PS C:\> $Result = Get-SubNetItems -StartScanIP 10.10.10.1 -EndScanIP 10.10.10.25 -Ports 80,3389,5900     
 
        PS C:\> $Result | Select-Object IP, Host, MAC, @{l="Ports";e={[string]::join(", ",($_.Ports | Select-Object @{Label="Ports";Expression={"$($_.Port)-$($_.Status)"}} | Select-Object -ExpandProperty Ports))}} | Format-Table * -AutoSize 
         
        IP          Host              MAC               Ports 
        --          ----              ---               ----- 
        10.10.10.1                                      80-False, 3389-False, 5900-False 
        10.10.10.2  pc02.mydomain.com 00-15-AD-0C-82-20 80-True, 3389-False, 5900-False 
        10.10.10.5  pc05.mydomain.com 00-15-5D-1C-80-25 80-True, 3389-False, 5900-False 
        10.10.10.7  pc07.mydomain.com 00-15-4D-0C-81-04 80-True, 3389-True, 5900-False 
        10.10.10.9  pc09.mydomain.com 00-15-4A-0C-80-31 80-True, 3389-True, 5900-False 
        10.10.10.10 pc10.mydomain.com 00-15-5D-02-1F-1C 80-False, 3389-True, 5900-False 
 
    .NOTES  
        Author: Michal Gajda 
         
        ChangeLog: 
        v1.3 
        -Scan items in subnet for MAC 
        -Basic port scan on items in subnet 
        -Fixed some small spelling bug 
         
        v1.2 
        -IP Range Ganerator upgrade 
         
        v1.1 
        -ProgressBar upgrade 
         
        v1.0: 
        -Scan subnet for items 
        -Scan items in subnet for WMI Access 
        -Scan items in subnet for WinRM Access 
#> 
 
    [CmdletBinding( 
        SupportsShouldProcess=$True, 
        ConfirmImpact="Low"  
    )]     
    param( 
        [parameter(Mandatory=$true)] 
        [System.Net.IPAddress]$StartScanIP, 
        [System.Net.IPAddress]$EndScanIP, 
        [Int]$MaxJobs = 20, 
        [Int[]]$Ports, 
        [Switch]$ShowAll, 
        [Switch]$ShowInstantly, 
        [Int]$SleepTime = 5, 
        [Int]$TimeOut = 90 
    ) 
 
    Begin{} 
 
    Process 
    { 
        if ($pscmdlet.ShouldProcess("$StartScanIP $EndScanIP" ,"Scan IP range for active machines")) 
        { 
            if(Get-Job -name *.*.*.*) 
            { 
                Write-Verbose "Removing old jobs." 
                Get-Job -name *.*.*.* | Remove-Job -Force 
            } 
             
            $ScanIPRange = @() 
            if($EndScanIP -ne $null) 
            { 
                Write-Verbose "Generating IP range list." 
                # Many thanks to Dr. Tobias Weltner, MVP PowerShell and Grant Ward for IP range generator 
                $StartIP = $StartScanIP -split '\.' 
                  [Array]::Reverse($StartIP)   
                  $StartIP = ([System.Net.IPAddress]($StartIP -join '.')).Address  
                 
                $EndIP = $EndScanIP -split '\.' 
                  [Array]::Reverse($EndIP)   
                  $EndIP = ([System.Net.IPAddress]($EndIP -join '.')).Address  
                 
                For ($x=$StartIP; $x -le $EndIP; $x++) {     
                    $IP = [System.Net.IPAddress]$x -split '\.' 
                    [Array]::Reverse($IP)    
                    $ScanIPRange += $IP -join '.'  
                } 
             
            } 
            else 
            { 
                $ScanIPRange = $StartScanIP 
            } 
 
            Write-Verbose "Creating own list class." 
            $Class = @" 
            public class SubNetItem { 
                public bool Active; 
                public string Host; 
                public System.Net.IPAddress IP; 
                public string MAC; 
                public System.Object Ports; 
                public string OS_Name; 
                public string OS_Ver; 
                public bool WMI; 
                public bool WinRM; 
            } 
"@         
 
            Write-Verbose "Start scaning..."     
            $ScanResult = @() 
            $ScanCount = 0 
            Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete (0) 
            Foreach($IP in $ScanIPRange) 
            { 
                 Write-Verbose "Starting job ($((Get-Job -name *.*.*.* | Measure-Object).Count+1)/$MaxJobs) for $IP." 
                Start-Job -Name $IP -ArgumentList $IP,$Ports,$Class -ScriptBlock{  
                 
                    param 
                    ( 
                    [System.Net.IPAddress]$IP = $IP, 
                    [Int[]]$Ports = $Ports, 
                    $Class = $Class  
                    ) 
                     
                    Add-Type -TypeDefinition $Class 
                     
                    if(Test-Connection -ComputerName $IP -Quiet) 
                    { 
                        #Get Hostname 
                        Try 
                        { 
                            $HostName = [System.Net.Dns]::GetHostbyAddress($IP).HostName 
                        } 
                        Catch 
                        { 
                            $HostName = $null 
                        } 
                         
                        #Get WMI Access, OS Name and version via WMI 
                        Try 
                        { 
                            #I don't use Get-WMIObject because it havent TimeOut options.  
                            $WMIObj = [WMISearcher]''   
                            $WMIObj.options.timeout = '0:0:10'  
                            $WMIObj.scope.path = "\\$IP\root\cimv2"   
                            $WMIObj.query = "SELECT * FROM Win32_OperatingSystem"   
                            $Result = $WMIObj.get()   
 
                            if($Result -ne $null) 
                            { 
                                $OS_Name = $Result | Select-Object -ExpandProperty Caption 
                                $OS_Ver = $Result | Select-Object -ExpandProperty Version 
                                $OS_CSDVer = $Result | Select-Object -ExpandProperty CSDVersion 
                                $OS_Ver += " $OS_CSDVer" 
                                $WMIAccess = $true                     
                            } 
                            else 
                            { 
                                $WMIAccess = $false     
                            } 
                        }     
                        catch 
                        { 
                            $WMIAccess = $false                     
                        } 
                         
                        #Get WinRM Access, OS Name and version via WinRM 
                        if($HostName) 
                        { 
                            $Result = Invoke-Command -ComputerName $HostName -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue  
                        } 
                        else 
                        { 
                            $Result = Invoke-Command -ComputerName $IP -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue  
                        } 
                         
                        if($Result -ne $null) 
                        { 
                            if($OS_Name -eq $null) 
                            { 
                                $OS_Name = ($Result[2..3] -split ":\s+")[1] 
                                $OS_Ver = ($Result[2..3] -split ":\s+")[3] 
                            }     
                            $WinRMAccess = $true 
                        } 
                        else 
                        { 
                            $WinRMAccess = $false 
                        } 
                         
                        #Get MAC Address 
                        Try 
                        { 
                            $result= nbtstat -A $IP | select-string "MAC" 
                            $MAC = [string]([Regex]::Matches($result, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])")) 
                        } 
                        Catch 
                        { 
                            $MAC = $null 
                        } 
                         
                        #Get ports status 
                        $PortsStatus = @() 
                        ForEach($Port in $Ports) 
                        { 
                            Try 
                            {                             
                                $TCPClient = new-object Net.Sockets.TcpClient 
                                $TCPClient.Connect($IP, $Port) 
                                $TCPClient.Close() 
                                 
                                $PortStatus = New-Object PSObject -Property @{             
                                    Port        = $Port 
                                    Status      = $true 
                                } 
                                $PortsStatus += $PortStatus 
                            }     
                            Catch 
                            { 
                                $PortStatus = New-Object PSObject -Property @{             
                                    Port        = $Port 
                                    Status      = $false 
                                }     
                                $PortsStatus += $PortStatus 
                            } 
                        } 
 
                         
                        $HostObj = New-Object SubNetItem -Property @{             
                                    Active        = $true 
                                    Host        = $HostName 
                                    IP          = $IP  
                                    MAC         = $MAC 
                                    Ports       = $PortsStatus 
                                    OS_Name     = $OS_Name 
                                    OS_Ver      = $OS_Ver                
                                    WMI         = $WMIAccess       
                                    WinRM       = $WinRMAccess       
                        } 
                        $HostObj 
                    } 
                    else 
                    { 
                        $HostObj = New-Object SubNetItem -Property @{             
                                    Active        = $false 
                                    Host        = $null 
                                    IP          = $IP   
                                    MAC         = $null 
                                    Ports       = $null 
                                    OS_Name     = $null 
                                    OS_Ver      = $null                
                                    WMI         = $null       
                                    WinRM       = $null       
                        } 
                        $HostObj 
                    } 
                } | Out-Null 
                $ScanCount++ 
                Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50)) 
                 
                do 
                { 
                    Write-Verbose "Trying get part of data." 
                    Get-Job -State Completed | Foreach { 
                        Write-Verbose "Geting job $($_.Name) result." 
                        $JobResult = Receive-Job -Id ($_.Id) 
 
                        if($ShowAll) 
                        { 
                            if($ShowInstantly) 
                            { 
                                if($JobResult.Active -eq $true) 
                                { 
                                    Write-Host "$($JobResult.IP) is active." -ForegroundColor Green 
                                } 
                                else 
                                { 
                                    Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red 
                                } 
                            } 
                             
                            $ScanResult += $JobResult     
                        } 
                        else 
                        { 
                            if($JobResult.Active -eq $true) 
                            { 
                                if($ShowInstantly) 
                                { 
                                    Write-Host "$($JobResult.IP) is active." -ForegroundColor Green 
                                } 
                                $ScanResult += $JobResult 
                            } 
                        } 
                        Write-Verbose "Removing job $($_.Name)." 
                        Remove-Job -Id ($_.Id) 
                        Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50)) 
                    } 
                     
                    if((Get-Job -name *.*.*.*).Count -eq $MaxJobs) 
                    { 
                        Write-Verbose "Jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait..." 
                        Sleep $SleepTime 
                    } 
                } 
                while((Get-Job -name *.*.*.*).Count -eq $MaxJobs) 
            } 
             
            $timeOutCounter = 0 
            do 
            { 
                Write-Verbose "Trying get last part of data." 
                Get-Job -State Completed | Foreach { 
                    Write-Verbose "Geting job $($_.Name) result." 
                    $JobResult = Receive-Job -Id ($_.Id) 
 
                    if($ShowAll) 
                    { 
                        if($ShowInstantly) 
                        { 
                            if($JobResult.Active -eq $true) 
                            { 
                                Write-Host "$($JobResult.IP) is active." -ForegroundColor Green 
                            } 
                            else 
                            { 
                                Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red 
                            } 
                        } 
                         
                        $ScanResult += $JobResult     
                    } 
                    else 
                    { 
                        if($JobResult.Active -eq $true) 
                        { 
                            if($ShowInstantly) 
                            { 
                                Write-Host "$($JobResult.IP) is active." -ForegroundColor Green 
                            } 
                            $ScanResult += $JobResult 
                        } 
                    } 
                    Write-Verbose "Removing job $($_.Name)." 
                    Remove-Job -Id ($_.Id) 
                    Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50)) 
                } 
                 
                if(Get-Job -name *.*.*.*) 
                { 
                    Write-Verbose "All jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait... ($timeOutCounter)" 
                    Sleep $SleepTime 
                    $timeOutCounter += $SleepTime                 
 
                    if($timeOutCounter -ge $TimeOut) 
                    { 
                        Write-Verbose "Time out... $TimeOut. Can't finish some jobs  ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs) try remove it manualy." 
                        Break 
                    } 
                } 
            } 
            while(Get-Job -name *.*.*.*) 
             
            Write-Verbose "Scan finished." 
            Return $ScanResult | Sort-Object {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]([string]$_.IP).split('.'))} 
        } 
    } 
     
    End{} 
} 
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7NOLCLHrRQhOpRX7hlpaYeLP
# H06gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGS9T7rBWri9FpNl
# fV6n8mVAIdVMMA0GCSqGSIb3DQEBAQUABIIBAFGALJ1hsGGPdRmjNJuxXZmbQGVw
# H2pj1McFyPgAl8cRu5hw2/agjOtOp/xLv7R/ixcmZ51FvtzN3t9O+ccIxQsxudLZ
# rmjf2YjMUkO7VZdjLpnZlxd7bntOKZyt2AFvcyXvJTxm/mDUBVLBu1zCLGoxM28B
# w0TqZIhyMF2woa5GfHBn/L6tdC8uDRx2u8DKaGp5yj6JIweXxGStGrmg+sDq+cA+
# rWi+bbtcJztWwrL+Whg6f6O5J+iVMZ3ZFKZ7cMwe0gZosZSTaI6AijQeclXf9SB+
# EqJQ8w2yrfH8410ImLkt81/RKp/G3WKyOn8dOlsSHz25No9l6Cg5yXC+gm4=
# SIG # End signature block
