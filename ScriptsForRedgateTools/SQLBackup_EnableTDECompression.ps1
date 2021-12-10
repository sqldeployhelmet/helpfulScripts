<#
    This script will use DBATools to determine the SQL instances running on server
    and update Registry Settings to enable SQL Backup to properly compress databases 
    using native TDE.

    Author:     josh smith
    Created:    2021-11-08

#>
$Server = ''
$RestartFlag = 0 # bit flag for rebooting server: RegKey changes will not take effect until restarted.
$Instances = Get-DbaService -ComputerName $server | Where-Object { $_.ServiceType -eq 'Engine' }

$Path = 'HKLM:SOFTWARE\Red Gate\SQL Backup\BackupSettingsGlobal'

foreach ($i in $Instances) {
    $InstanceName = $i.InstanceName

    $KeyPath = $Path + '\' + $InstanceName

    Write-Output "Setting key value on $Server for instance $InstanceName..."
    $codeBloc = {
        $key = try {
            Get-Item -Path $using:keyPath -ErrorAction Stop
        }
        catch {
            New-Item -Path $using:keyPath -Force
        }

        try { 
            New-ItemProperty -Path $key.PSPath -Name 'FORCETDECOMPRESSION' -Value 1
            Write-Output "Success TDE Compression enabled for $using:instanceName!"

            if($using:RestartFlag -eq 1) { Restart-Computer }
        }
        catch {
            Write-Output "An error has occurred: TDE Flag not set for $using:instanceName!"
        }
    }

    Invoke-Command -ComputerName $Server -ScriptBlock $codeBloc    
}
