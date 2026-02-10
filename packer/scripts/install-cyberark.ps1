Enable-PSRemoting -Force

$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"

New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force

Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP Action Allow

Restart-Service WinRM
