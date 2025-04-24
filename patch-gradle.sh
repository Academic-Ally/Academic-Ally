#!/bin/bash

# Make the script executable
chmod +x patch-gradle.sh

# Create backup files
find ../node_modules/@react-native/gradle-plugin -name "*.gradle.kts" -exec cp {} {}.backup \;

# Fix the Kotlin compiler options by replacing allWarningsAsErrors with .set()
find ../node_modules/@react-native/gradle-plugin -name "*.gradle.kts" -exec sed -i '.patched' 's/allWarningsAsErrors =/allWarningsAsErrors.set(/' {} \;
find ../node_modules/@react-native/gradle-plugin -name "*.gradle.kts" -exec sed -i '.patched' 's/project.properties\["enableWarningsAsErrors"\]?.toString()?.toBoolean() ?: false/project.properties\["enableWarningsAsErrors"\]?.toString()?.toBoolean() ?: false)/' {} \;

echo "Gradle plugin patched successfully!" 