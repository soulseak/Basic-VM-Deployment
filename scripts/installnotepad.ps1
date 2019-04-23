Start-BitsTransfer https://bsflocorefiles.blob.core.windows.net/installer/Notepad++7.6.5.msi

$file = Get-ChildItem | Where-Object {$_.Name -like "Notepad*"}
$file.FullName
$arguments = '/I "' + $file.FullName + '" /quiet'
Start-Process msiexec.exe -Wait -ArgumentList $arguments

Remove-Item $file