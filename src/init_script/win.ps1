#ps1

$PASSWORD="1q2w3e4r!"

net user Administrator $PASSWORD

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-TCP" /v UserAuthentication /t REG_DWORD /d 0 -f
ipconfig > C:\result.txt

