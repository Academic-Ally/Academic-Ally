import { NavigationContainer } from '@react-navigation/native';
import { extendTheme, NativeBaseProvider } from 'native-base';
import React from 'react';
import { Platform, StatusBar } from 'react-native';
import RNBootSplash from 'react-native-bootsplash';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NotifierWrapper } from 'react-native-notifier';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Provider } from 'react-redux';
import store from './src/redux/store';
import BootScreen from './src/screens/Boot/BootScreen';
import NavigationService from './src/services/NavigationService';

if (Platform.OS === 'android') {
  const AndroidBadge = require('react-native-android-badge');
  AndroidBadge.setBadge(5);
}

const theme = extendTheme({
  fonts: {
    heading: 'DMSans-Bold',
    body: 'DMSans-Regular',
    mono: 'DMSans-Regular',
  },
});

const App = () => {
  React.useEffect(() => {
    setTimeout(() => {
      RNBootSplash.hide();
    }, 500);
  }, []);

  const linking = {
    prefixes: ['academically://', 'https://app.getacademically.co/', 'https://getacademically.co'],
    config: {
      screens: {
        Recents: {
          path: 'Recents'
        }
      }
    }
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaView style={{ flex: 1 }}>
        <Provider store={store}>
          <NativeBaseProvider>
            <StatusBar
              backgroundColor={Platform.OS === 'android' ? '#6360FF' : 'transparent'}
              barStyle="light-content"
            />
            <NavigationContainer ref={NavigationService.navigationRef} linking={linking}>
              <NotifierWrapper>
                <BootScreen />
              </NotifierWrapper>
            </NavigationContainer>
          </NativeBaseProvider>
        </Provider>
      </SafeAreaView>
    </GestureHandlerRootView>
  );
};

export default App;