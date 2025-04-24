import messaging from '@react-native-firebase/messaging';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';

const TOPIC_SUBSCRIPTIONS_KEY = '@notification_topics';
const FCM_TOKEN_KEY = '@fcm_token';

class NotificationService {
  constructor() {
    this.messaging = messaging();
    this.initialized = false;
  }

  async initialize() {
    if (this.initialized) return;

    try {
      // Request permission for iOS
      if (Platform.OS === 'ios') {
        const authStatus = await messaging().requestPermission();
        const enabled =
          authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
          authStatus === messaging.AuthorizationStatus.PROVISIONAL;

        if (!enabled) {
          console.log('User notification permissions denied');
          return;
        }
      }

      // Get FCM token but don't save to Firestore yet
      const fcmToken = await messaging().getToken();
      await AsyncStorage.setItem(FCM_TOKEN_KEY, fcmToken);

      // Set up message handlers
      this.setupMessageHandlers();

      this.initialized = true;
      return fcmToken;
    } catch (error) {
      console.error('Error initializing notification service:', error);
      throw error;
    }
  }

  async updateFCMToken() {
    try {
      const user = auth().currentUser;
      if (!user) {
        console.log('No authenticated user found');
        return null;
      }

      const fcmToken = await AsyncStorage.getItem(FCM_TOKEN_KEY) || await messaging().getToken();

      await firestore()
        .collection('users')
        .doc(user.uid)
        .set({
          fcmToken,
          lastTokenUpdate: firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      return fcmToken;
    } catch (error) {
      console.error('Error updating FCM token:', error);
      throw error;
    }
  }

  setupMessageHandlers() {
    // Handle foreground messages
    this.unsubscribeForeground = messaging().onMessage(async remoteMessage => {
      this.handleNotification(remoteMessage);
    });

    // Handle background/quit state messages
    messaging().setBackgroundMessageHandler(async remoteMessage => {
      this.handleNotification(remoteMessage);
    });

    // Handle token refresh
    messaging().onTokenRefresh(token => {
      this.updateFCMToken();
    });
  }

  async handleNotification(remoteMessage) {
    const { notification, data } = remoteMessage;

    // Handle different notification types
    switch (data?.type) {
      case 'RESOURCE_ACCEPTED':
        // Handle resource acceptance notification
        this.showResourceAcceptedNotification(notification, data);
        break;
      case 'YOUR_RESOURCE_ACCEPTED':
        // Handle uploader's resource acceptance notification
        this.showUploaderNotification(notification, data);
        break;
      default:
        // Handle other notification types
        this.showDefaultNotification(notification, data);
    }
  }

  async subscribeToTopic(topicId) {
    try {
      const user = auth().currentUser;
      if (!user) {
        console.log('No authenticated user found');
        return false;
      }

      // First subscribe to FCM topic
      await messaging().subscribeToTopic(topicId);
      
      // Store subscription locally
      const subscriptions = await this.getTopicSubscriptions();
      if (!subscriptions.includes(topicId)) {
        subscriptions.push(topicId);
        await AsyncStorage.setItem(TOPIC_SUBSCRIPTIONS_KEY, JSON.stringify(subscriptions));
      }
      
      // Update Firestore
      await firestore()
        .collection('users')
        .doc(user.uid)
        .set({
          topicSubscriptions: firestore.FieldValue.arrayUnion(topicId),
        }, { merge: true });

      return true;
    } catch (error) {
      console.error('Error subscribing to topic:', error);
      throw error;
    }
  }

  async unsubscribeFromTopic(topicId) {
    try {
      await messaging().unsubscribeFromTopic(topicId);
      
      // Remove subscription locally
      const subscriptions = await this.getTopicSubscriptions();
      const updatedSubscriptions = subscriptions.filter(topic => topic !== topicId);
      await AsyncStorage.setItem(TOPIC_SUBSCRIPTIONS_KEY, JSON.stringify(updatedSubscriptions));
      
      // Update user's subscriptions in Firestore
      const user = auth().currentUser;
      if (user) {
        await firestore()
          .collection('users')
          .doc(user.uid)
          .update({
            topicSubscriptions: firestore.FieldValue.arrayRemove(topicId),
          });
      }

      return true;
    } catch (error) {
      console.error('Error unsubscribing from topic:', error);
      return false;
    }
  }

  async getTopicSubscriptions() {
    try {
      const subscriptions = await AsyncStorage.getItem(TOPIC_SUBSCRIPTIONS_KEY);
      return subscriptions ? JSON.parse(subscriptions) : [];
    } catch (error) {
      console.error('Error getting topic subscriptions:', error);
      return [];
    }
  }

  showResourceAcceptedNotification(notification, data) {
    // Implement your notification UI here
    // You can use react-native-push-notification or other libraries
    console.log('Resource Accepted Notification:', { notification, data });
  }

  showUploaderNotification(notification, data) {
    // Implement your notification UI here
    console.log('Uploader Notification:', { notification, data });
  }

  showDefaultNotification(notification, data) {
    // Implement your notification UI here
    console.log('Default Notification:', { notification, data });
  }

  cleanup() {
    if (this.unsubscribeForeground) {
      this.unsubscribeForeground();
    }
  }
}

export default new NotificationService(); 