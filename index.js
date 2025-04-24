import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';
import messaging from '@react-native-firebase/messaging';
import 'react-native-gesture-handler';
import FirebaseService from "./src/services/FirebaseService";

// Initialize Firebase messaging
FirebaseService.requestUserPermission();
// Handle background messages
messaging().setBackgroundMessageHandler(async remoteMessage => {
    return Promise.resolve();
});
AppRegistry.registerComponent(appName, () => App);
