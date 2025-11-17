# PowerShell script to get SHA-1 fingerprint for Firebase Console
# This is required for Firebase Auth reCAPTCHA verification on Android

Write-Host "Getting SHA-1 fingerprint for Firebase Console..." -ForegroundColor Cyan
Write-Host ""

# Find Java keytool
$javaHome = $env:JAVA_HOME
if (-not $javaHome) {
    Write-Host "JAVA_HOME not set. Trying to find Java..." -ForegroundColor Yellow
    $javaPath = Get-Command java -ErrorAction SilentlyContinue
    if ($javaPath) {
        $javaHome = Split-Path (Split-Path $javaPath.Source)
    }
}

if (-not $javaHome) {
    Write-Host "ERROR: Java not found. Please install Java JDK or set JAVA_HOME environment variable." -ForegroundColor Red
    exit 1
}

$keytoolPath = Join-Path $javaHome "bin\keytool.exe"

if (-not (Test-Path $keytoolPath)) {
    Write-Host "ERROR: keytool not found at $keytoolPath" -ForegroundColor Red
    exit 1
}

# Default debug keystore location
$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"
$defaultPassword = "android"

if (-not (Test-Path $debugKeystore)) {
    Write-Host "Debug keystore not found at: $debugKeystore" -ForegroundColor Yellow
    Write-Host "Creating debug keystore..." -ForegroundColor Yellow
    
    # Create debug keystore
    & $keytoolPath -genkey -v -keystore $debugKeystore -storepass $defaultPassword -alias androiddebugkey -keypass $defaultPassword -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create debug keystore" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Keystore location: $debugKeystore" -ForegroundColor Green
Write-Host ""
Write-Host "SHA-1 Fingerprint:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Get SHA-1 fingerprint
& $keytoolPath -list -v -keystore $debugKeystore -storepass $defaultPassword -alias androiddebugkey | Select-String "SHA1"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy the SHA-1 fingerprint above (without colons or spaces)" -ForegroundColor White
Write-Host "2. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "3. Select your project: thunder-52d2e" -ForegroundColor White
Write-Host "4. Go to Project Settings > Your apps > Android app" -ForegroundColor White
Write-Host "5. Click 'Add fingerprint' and paste the SHA-1" -ForegroundColor White
Write-Host "6. Download the updated google-services.json and replace android/app/google-services.json" -ForegroundColor White
Write-Host ""
Write-Host "For Release builds, also add the release keystore SHA-1!" -ForegroundColor Yellow

