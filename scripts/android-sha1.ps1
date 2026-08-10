# Print SHA-1 / SHA-256 for Google Cloud Console (Android OAuth client).
param(
  [string]$Keystore = "$env:USERPROFILE\.android\debug.keystore",
  [string]$Alias = "androiddebugkey",
  [string]$StorePass = "android",
  [string]$KeyPass = "android"
)

Write-Host "Package name: com.internsafe.internsfe"
Write-Host "Keystore: $Keystore"
Write-Host ""
keytool -list -v -keystore $Keystore -alias $Alias -storepass $StorePass -keypass $KeyPass |
  Select-String -Pattern "SHA1:|SHA256:"
