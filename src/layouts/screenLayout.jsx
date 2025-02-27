import React, { useEffect } from 'react';
import { Dimensions, Platform, SafeAreaView, StatusBar, StyleSheet, Text, View } from 'react-native';
import Orientation from 'react-native-orientation-locker';
import { useSelector } from 'react-redux';

import RestrictedScreen from './restrictedScreen';

const ScreenLayout = ({name = 'none', children}) => {
  const height = Dimensions.get('screen').height;
  const width = Dimensions.get('screen').width;
  const theme = useSelector(state => state.theme);
  const statusBarHeight = Platform.OS === 'ios' ? 44 : StatusBar.currentHeight;

  useEffect(() => {
    if (name === 'PdfViewer') {
      Orientation.unlockAllOrientations();
    } else {
      Orientation.lockToPortrait();
    }
  }, []);

  return (
    <RestrictedScreen>
      <SafeAreaView style={styles.safeArea}>
        <View
          style={[styles.container, {
            backgroundColor: theme.colors.primary,
          }]}>
          <StatusBar
            translucent={Platform.OS === 'android'}
            backgroundColor={theme.colors.primary}
            barStyle={'light-content'}
          />
          <View
            style={[styles.content, {
              backgroundColor: '#F1F1FA',
            }]}>
            {children}
          </View>
        </View>
      </SafeAreaView>
    </RestrictedScreen>
  );
};

export default ScreenLayout;

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Platform.OS === 'ios' ? '#F1F1FA' : 'transparent',
  },
  container: {
    flex: 1,
    width: '100%',
  },
  content: {
    flex: 1,
    width: '100%',
  },
});
