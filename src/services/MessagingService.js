import messaging from '@react-native-firebase/messaging';
import { Platform } from 'react-native';

class MessagingService {
  async requestUserPermission() {
    if (Platform.OS === 'ios') {
      const authStatus = await messaging().requestPermission();
      const enabled =
        authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
        authStatus === messaging.AuthorizationStatus.PROVISIONAL;

      if (enabled) {
        await this.registerDeviceForRemoteMessages();
      }

      return enabled;
    }
    return true;
  }

  async registerDeviceForRemoteMessages() {
    if (Platform.OS === 'ios') {
      await messaging().registerDeviceForRemoteMessages();
    }
  }

  async getToken() {
    try {
      if (Platform.OS === 'ios') {
        await this.registerDeviceForRemoteMessages();
      }
      return await messaging().getToken();
    } catch (error) {
      console.error('Error getting FCM token:', error);
      return null;
    }
  }

  async onMessage(callback) {
    return messaging().onMessage(callback);
  }

  async onNotificationOpenedApp(callback) {
    return messaging().onNotificationOpenedApp(callback);
  }

  async getInitialNotification() {
    return messaging().getInitialNotification();
  }
}

export default new MessagingService();