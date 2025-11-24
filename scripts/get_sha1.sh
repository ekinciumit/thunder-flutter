#!/bin/bash
# Bash script to get SHA-1 fingerprint for Firebase Console
# This is required for Firebase Auth reCAPTCHA verification on Android

echo "Getting SHA-1 fingerprint for Firebase Console..."
echo ""

# Find Java keytool
if [ -z "$JAVA_HOME" ]; then
    echo "JAVA_HOME not set. Trying to find Java..."
    JAVA_PATH=$(which java 2>/dev/null)
    if [ -n "$JAVA_PATH" ]; then
        JAVA_HOME=$(dirname $(dirname $(readlink -f $JAVA_PATH)))
    fi
fi

if [ -z "$JAVA_HOME" ]; then
    echo "ERROR: Java not found. Please install Java JDK or set JAVA_HOME environment variable."
    exit 1
fi

KEYTOOL_PATH="$JAVA_HOME/bin/keytool"

if [ ! -f "$KEYTOOL_PATH" ]; then
    echo "ERROR: keytool not found at $KEYTOOL_PATH"
    exit 1
fi

# Default debug keystore location (Linux/Mac)
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
DEFAULT_PASSWORD="android"

# Check if keystore exists, if not create it
if [ ! -f "$DEBUG_KEYSTORE" ]; then
    echo "Debug keystore not found at: $DEBUG_KEYSTORE"
    echo "Creating debug keystore..."
    
    # Create directory if it doesn't exist
    mkdir -p "$HOME/.android"
    
    # Create debug keystore
    $KEYTOOL_PATH -genkey -v -keystore "$DEBUG_KEYSTORE" -storepass "$DEFAULT_PASSWORD" -alias androiddebugkey -keypass "$DEFAULT_PASSWORD" -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create debug keystore"
        exit 1
    fi
fi

echo "Keystore location: $DEBUG_KEYSTORE"
echo ""
echo "SHA-1 Fingerprint:"
echo "=================="

# Get SHA-1 fingerprint
$KEYTOOL_PATH -list -v -keystore "$DEBUG_KEYSTORE" -storepass "$DEFAULT_PASSWORD" -alias androiddebugkey | grep SHA1

echo ""
echo "Next Steps:"
echo "1. Copy the SHA-1 fingerprint above (without colons or spaces)"
echo "2. Go to Firebase Console: https://console.firebase.google.com/"
echo "3. Select your project: thunder-52d2e"
echo "4. Go to Project Settings > Your apps > Android app"
echo "5. Click 'Add fingerprint' and paste the SHA-1"
echo "6. Download the updated google-services.json and replace android/app/google-services.json"
echo ""
echo "For Release builds, also add the release keystore SHA-1!"

