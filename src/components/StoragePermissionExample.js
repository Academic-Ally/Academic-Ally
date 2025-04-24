import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import UtilityService from '../services/UtilityService';

const StoragePermissionExample = () => {
  // Function to handle downloading a sample PDF
  const handleDownloadFile = async () => {
    try {
      // Sample PDF URL - replace with your actual file URL
      const fileUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
      const fileName = 'sample-document.pdf';
      
      // Request permission and save file if granted
      const filePath = await UtilityService.saveFileToDevice(fileUrl, fileName);
      
      if (filePath) {
        console.log('File saved successfully to:', filePath);
      } else {
        console.log('File save failed or permission denied');
      }
    } catch (error) {
      console.error('Error downloading file:', error);
      Alert.alert('Error', 'Failed to download file. Please try again.');
    }
  };

  // Function to just check and request permission without downloading
  const checkPermission = async () => {
    const granted = await UtilityService.requestStoragePermission(
      () => Alert.alert('Success', 'Storage permission granted!'),
      () => Alert.alert('Error', 'Storage permission denied. Some features may not work.')
    );
    
    console.log('Permission granted:', granted);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Storage Permission Example</Text>
      
      <TouchableOpacity
        style={styles.button}
        onPress={checkPermission}
      >
        <Text style={styles.buttonText}>Request Permission</Text>
      </TouchableOpacity>
      
      <TouchableOpacity
        style={styles.button}
        onPress={handleDownloadFile}
      >
        <Text style={styles.buttonText}>Download Sample PDF</Text>
      </TouchableOpacity>
      
      <Text style={styles.note}>
        Note: The downloaded file will be saved to your device's Downloads folder on Android 
        or Documents folder on iOS.
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 20,
    backgroundColor: '#f5f5f5',
    borderRadius: 10,
    margin: 10,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#333',
  },
  button: {
    backgroundColor: '#4a90e2',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginBottom: 15,
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  note: {
    fontSize: 12,
    color: '#666',
    marginTop: 10,
    fontStyle: 'italic',
  }
});

export default StoragePermissionExample; 