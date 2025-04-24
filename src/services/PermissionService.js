import { PermissionsAndroid, Platform } from 'react-native';
import { check, request, PERMISSIONS, RESULTS } from 'react-native-permissions';

class PermissionService {
  /**
   * Request storage permission for Android and iOS
   * @returns {Promise<boolean>} - Returns true if permission is granted
   */
  static async requestStoragePermission() {
    try {
      if (Platform.OS === 'android') {
        // Check Android version
        if (Platform.Version >= 33) {
          // For Android 13+ use the new permissions
          const imagePermission = await request(PERMISSIONS.ANDROID.READ_MEDIA_IMAGES);
          const videoPermission = await request(PERMISSIONS.ANDROID.READ_MEDIA_VIDEO);
          
          return (
            imagePermission === RESULTS.GRANTED &&
            videoPermission === RESULTS.GRANTED
          );
        } else if (Platform.Version >= 23) {
          // For Android 6.0 - 12.0
          const readPermission = await PermissionsAndroid.request(
            PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
            {
              title: 'Storage Permission',
              message: 'App needs access to your storage to save files.',
              buttonNeutral: 'Ask Me Later',
              buttonNegative: 'Cancel',
              buttonPositive: 'OK',
            }
          );

          const writePermission = await PermissionsAndroid.request(
            PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
            {
              title: 'Storage Permission',
              message: 'App needs access to your storage to save files.',
              buttonNeutral: 'Ask Me Later',
              buttonNegative: 'Cancel',
              buttonPositive: 'OK',
            }
          );

          return (
            readPermission === PermissionsAndroid.RESULTS.GRANTED &&
            writePermission === PermissionsAndroid.RESULTS.GRANTED
          );
        } else {
          // For older Android versions, permissions are granted at install time
          return true;
        }
      } else if (Platform.OS === 'ios') {
        // iOS doesn't have a specific storage permission
        // For iOS, you typically need photo library permission when saving images
        const photoPermission = await request(PERMISSIONS.IOS.PHOTO_LIBRARY);
        return photoPermission === RESULTS.GRANTED;
      }
      
      return false;
    } catch (error) {
      console.error('Error requesting storage permission:', error);
      return false;
    }
  }

  /**
   * Check if storage permission is granted
   * @returns {Promise<boolean>} - Returns true if permission is granted
   */
  static async hasStoragePermission() {
    try {
      if (Platform.OS === 'android') {
        if (Platform.Version >= 33) {
          // For Android 13+
          const imagePermission = await check(PERMISSIONS.ANDROID.READ_MEDIA_IMAGES);
          const videoPermission = await check(PERMISSIONS.ANDROID.READ_MEDIA_VIDEO);
          
          return (
            imagePermission === RESULTS.GRANTED &&
            videoPermission === RESULTS.GRANTED
          );
        } else {
          // For Android below 13
          const readPermission = await PermissionsAndroid.check(
            PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE
          );
          const writePermission = await PermissionsAndroid.check(
            PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
          );
          
          return readPermission && writePermission;
        }
      } else if (Platform.OS === 'ios') {
        const photoPermission = await check(PERMISSIONS.IOS.PHOTO_LIBRARY);
        return photoPermission === RESULTS.GRANTED;
      }
      
      return false;
    } catch (error) {
      console.error('Error checking storage permission:', error);
      return false;
    }
  }

  /**
   * Check and request storage permission if not granted
   * @returns {Promise<boolean>} - Returns true if permission is granted
   */
  static async checkAndRequestStoragePermission() {
    const hasPermission = await this.hasStoragePermission();
    
    if (hasPermission) {
      return true;
    }
    
    return await this.requestStoragePermission();
  }
}

export default PermissionService; 