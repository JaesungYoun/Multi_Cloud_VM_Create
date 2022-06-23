
cmd /c where gcloud > gcloud_install_log.txt  


if (-not(Get-Content gcloud_install_log.txt)) {
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe") 
& $env:Temp\GoogleCloudSDKInstaller.exe /S
}

Remove-Item gcloud_install_log.txt


