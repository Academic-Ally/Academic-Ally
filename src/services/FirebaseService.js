import messaging from '@react-native-firebase/messaging';

class FirebaseService {
    constructor() { }

    static parseMessage(message) {
        if (message) {
            console.log(message);
        }
    }

    static async requestUserPermission() {
        try {
            const authStatus = await messaging().requestPermission();
            const enabled =
                authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
                authStatus === messaging.AuthorizationStatus.PROVISIONAL;
            
            return enabled;
        } catch (error) {
            console.error('Error requesting permission:', error);
            return false;
        }
    }
}
export default FirebaseService;
