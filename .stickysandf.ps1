# Get the drive letter of the USB stick.
$usbDriveLetter = Get-Volume | Where-Object {$_.DriveType -eq "Removable"} | Select-Object -First 1 | Select-Object -ExpandProperty DriveLetter

# Create a Windows Sandbox configuration file.
$wsbFile = "WindowsSandbox.wsb"
$wsbContent = @"
<Configuration>
  <MappedFolders>
    <MappedFolder>
      <HostPath>\\?\Volume{$usbDriveLetter}\</HostPath>
      <SandboxPath>C:\WindowsSandbox\USB</SandboxPath>
      <ReadOnly>False</ReadOnly>
    </MappedFolder>
  </MappedFolders>
</Configuration>
"@

# Write the configuration file to disk.
Set-Content $wsbFile $wsbContent

# Start Windows Sandbox.
Start-Process "WindowsSandbox.exe"

# Scan the USB stick for malware.
$scanResults = Start-Process "WindowsDefender.exe" -ArgumentList "/Scan /Path \\?\Volume{$usbDriveLetter}\*"

# If the scan finds any malware, prompt the user to delete it.
if ($scanResults.ExitCode -eq 0) {
  $message = "The USB stick contains malware. Would you like to delete it?"
  $confirm = Read-Host -Prompt $message

  if ($confirm -eq "Y") {
    Remove-Item -Path \\?\Volume{$usbDriveLetter}\* -Force
  }
}

# Always ask the user before playing any .exe files from the USB stick.
function Play-File($path) {
  $message = "Would you like to play this file? (Y/N)"
  $confirm = Read-Host -Prompt $message

  if ($confirm -eq "Y") {
    Start-Process $path
  }
}

# Register a handler for .exe files.
Register-ScriptAction -ScriptBlock { Play-File $args } -Path *.exe
