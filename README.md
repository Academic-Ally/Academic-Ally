# Academic Ally React Native Application

Academic Ally is your go-to source for academic resources, designed to make your academic journey easier and more efficient. Our app provides notes, question papers, question banks, and other helpful resources that are relevant to your studies.

This React Native application was created by a tiny team of engineering students who recognized the need for a centralized platform that students could rely on to access academic resources. Academic Ally is a one-stop-shop for all your academic needs.

## Features

- User-friendly interface for easy access to notes and resources
- Share and upload your own notes
- Comprehensive collection of high-quality, up-to-date resources
- Constantly evolving to meet the changing needs of students

## Installation

To install the Academic Ally React Native Application, follow these steps:

1. Clone the repository to your local machine
2. Install dependencies using 'npm install'
3. Run the application using 'npm start'

## Feedback
We welcome feedback from our users to help us improve the Academic Ally React Native Application. Please submit any suggestions or bug reports to our GitHub repository.

<!-- ## Contribution
We believe in the power of community and encourage contributions from our users. If you would like to contribute to the development of the Academic Ally React Native Application, please submit a pull request to our GitHub repository.

Thank you for using the Academic Ally React Native Application! We are committed to providing high-quality, up-to-date resources to make your academic journey as smooth as possible. -->

# Storage Permission Implementation for Academic-Ally

This document provides instructions on how to implement storage permission requests in your React Native app.

## Overview

The implementation includes:

1. Required Android permissions in AndroidManifest.xml
2. Required iOS permissions in Info.plist
3. A `PermissionService` utility class to handle permission requests
4. Storage-related methods in `UtilityService` class
5. A sample component demonstrating how to use the permission functionality

## Usage

To use the storage permission functionality in your app, import the `StoragePermissionExample` component in your screen:

```jsx
import React from 'react';
import { View, ScrollView } from 'react-native';
import StoragePermissionExample from '../components/StoragePermissionExample';

const YourScreen = () => {
  return (
    <ScrollView>
      <View style={{ flex: 1, padding: 20 }}>
        {/* Your existing screen content */}
        
        {/* Add the storage permission component */}
        <StoragePermissionExample />
        
        {/* More content */}
      </View>
    </ScrollView>
  );
};

export default YourScreen;
```

## Manual Integration (Alternative)

If you prefer to integrate the permission functionality directly without using the example component:

```jsx
import React from 'react';
import { View, Button, Alert } from 'react-native';
import UtilityService from '../services/UtilityService';

const YourScreen = () => {
  const handleDownload = async () => {
    // Example file URL and filename
    const fileUrl = 'https://example.com/your-document.pdf';
    const fileName = 'document.pdf';
    
    // Request permission and download file
    const filePath = await UtilityService.saveFileToDevice(fileUrl, fileName);
    if (filePath) {
      Alert.alert('Success', 'File downloaded successfully!');
    }
  };
  
  return (
    <View style={{ padding: 20 }}>
      <Button 
        title="Download Document" 
        onPress={handleDownload} 
      />
    </View>
  );
};
```

## Direct Permission Request

You can also request storage permission directly without downloading a file:

```jsx
import UtilityService from '../services/UtilityService';

// Somewhere in your component or function
const checkPermission = async () => {
  const hasPermission = await UtilityService.requestStoragePermission(
    () => {
      // Permission granted callback
      console.log('Permission granted');
    },
    () => {
      // Permission denied callback
      console.log('Permission denied');
    }
  );
  
  if (hasPermission) {
    // Do something that requires storage permission
  }
};
```

## Note on iOS Permissions

For iOS, the app will request photo library access, which is used for saving files to the user's photos.

## Note on Android Permissions

For Android 13 and above (API 33+), the app will request the new granular permissions:
- READ_MEDIA_IMAGES
- READ_MEDIA_VIDEO

For Android 6.0 to 12, the app will request:
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE

For older Android versions, permissions are granted at install time.
