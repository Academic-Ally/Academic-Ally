import { PermissionsAndroid, Platform } from 'react-native';
import { Toast } from 'native-base';

class PermissionsService {
  /**
   * Request storage permission for downloading files
   * Returns true if permission is granted, false otherwise
   */
  static async requestStoragePermission() {
    // iOS doesn't require explicit storage permissions
    if (Platform.OS === 'ios') {
      return true;
    }
    
    try {
      // For Android 13+ (API level 33+), we need to request specific permissions
      if (Platform.Version >= 33) {
        const permissions = [
          PermissionsAndroid.PERMISSIONS.READ_MEDIA_IMAGES,
          PermissionsAndroid.PERMISSIONS.READ_MEDIA_VIDEO,
          PermissionsAndroid.PERMISSIONS.READ_MEDIA_AUDIO
        ];
        
        const results = await PermissionsAndroid.requestMultiple(permissions);
        
        // Check if any permission was granted
        return (
          results[PermissionsAndroid.PERMISSIONS.READ_MEDIA_IMAGES] === 'granted' ||
          results[PermissionsAndroid.PERMISSIONS.READ_MEDIA_VIDEO] === 'granted' ||
          results[PermissionsAndroid.PERMISSIONS.READ_MEDIA_AUDIO] === 'granted'
        );
      } 
      // For Android 12 and below, we can use WRITE_EXTERNAL_STORAGE
      else {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
          {
            title: 'Storage Permission',
            message: 'Academic Ally needs access to your storage to download files',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
        
        return granted === PermissionsAndroid.RESULTS.GRANTED;
      }
    } catch (err) {
      console.error('Permission request error:', err);
      Toast.show({
        title: 'Permission request failed',
        duration: 3000,
        backgroundColor: '#d9534f',
      });
      return false;
    }
  }
}

export default PermissionsService; 