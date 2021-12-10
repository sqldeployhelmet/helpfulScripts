<#
    This script will update the software registry settings for SQL Backup to allow it
    to successfully compress backups of databases using native TDE.

    Author:     josh smith
    Created:    2021-11-09
#>
$server = ''

if ($server.Length -lt 1) { throw 'Invalid server name!' }

$instances = Get-DbaService -ComputerName $server | Where-Object { $_.ServiceType -eq 'Engine' }

if ($null -eq $instances) { 
    Write-Output 'No SQL instances were detected!' 
    return
}

$path = 'HKLM:SOFTWARE\Red Gate\SQL Backup\BackupSettingsGlobal'
foreach ($i in $instances) {
    $instanceName = $i.InstanceName

    $keyPath = $path + '\' + $instanceName

    Write-Output "Setting key value on $server for instance $instanceName..."
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
        }
        catch {
            Write-Output "An error has occurred: TDE Flag not set for $using:instanceName!"
        }
    }

    Invoke-Command -ComputerName $server -ScriptBlock $codeBloc    
}
