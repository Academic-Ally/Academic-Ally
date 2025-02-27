import { useNavigation } from '@react-navigation/native';
import { Icon, IconButton } from 'native-base'
import React, { useMemo } from 'react';
import { Platform, SafeAreaView, ScrollView, StatusBar, StyleSheet, Text, View } from 'react-native';
import Ionicons from 'react-native-vector-icons/Ionicons';
import Octicons from 'react-native-vector-icons/Octicons';
import { useSelector } from 'react-redux';

import RestrictedScreen from './restrictedScreen';
import createStyles from './styles';

interface Props {
  children?: React.ReactNode;
  rightIconFalse: boolean;
  title: string;
  handleScroll?: (event: any) => void;
  handleShare?: () => void;
}

const navigationLayout = ({ children, rightIconFalse, title, handleScroll, handleShare }: Props) => {
  const navigation = useNavigation();
  const theme = useSelector((state: any) => state.theme);
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
  
  return (
    <RestrictedScreen>
      <SafeAreaView style={[styles.container, { backgroundColor: theme.colors.primary }]}>
        <View style={styles.headerContainer}>
          <View style={{
            flexDirection: 'row',
            justifyContent: 'space-between',
            alignItems: 'center',
            width: '100%',
            paddingHorizontal: 20,
            paddingTop: Platform.OS === 'ios' ? 10 : 20,
            paddingBottom: Platform.OS === 'ios' ? 10 : 0,
            minHeight: Platform.OS === 'ios' ? 44 : 56
          }}>
            <StatusBar
              translucent={Platform.OS === 'android'}
              backgroundColor={theme.colors.primary}
              barStyle={'light-content'}
            />
            <IconButton
              borderRadius={'full'}
              _hover={{
                bg: theme.colors.quaternary,
              }}
              _pressed={{
                bg: theme.colors.quaternary,
              }}
              onPress={() => navigation.goBack()}
              variant="ghost"
              icon={<Icon as={Ionicons} name="chevron-back-outline" size={'xl'} color={theme.colors.white} />}
              p={0}
            />
            {title && (
              <View style={styles.header}>
                <Text style={[styles.headerText, Platform.OS === 'ios' ? { fontWeight: '600' } : null]}>
                  {title}
                </Text>
              </View>
            )}
            {!rightIconFalse && (
              <IconButton
                borderRadius={'full'}
                _hover={{
                  bg: theme.colors.quaternary,
                }}
                _pressed={{
                  bg: theme.colors.quaternary,
                }}
                onPress={handleShare}
                variant="ghost"
                icon={<Icon as={Ionicons} name="md-share-social-outline" size={'lg'} color={theme.colors.white} />}
                p={0}
              />
            )}
            {rightIconFalse && (
              <View style={{ width: 30 }} />
            )}
          </View>
        </View>
        <View style={styles.body}>
          <View style={styles.bodyContent}>
            <ScrollView
              onScroll={handleScroll}
              showsVerticalScrollIndicator={false}>
              {children}
            </ScrollView>
          </View>
        </View>
      </SafeAreaView>
    </RestrictedScreen>
  );
};

export default navigationLayout;

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  headerContainer: {
    width: '100%',
    backgroundColor: 'transparent',
    zIndex: 1,
  },
  header: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerText: {
    fontSize: 18,
    color: '#FFFFFF',
    fontWeight: 'bold',
    textAlign: 'center',
  },
  body: {
    flex: 1,
    backgroundColor: '#F1F1FA',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    overflow: 'hidden',
  },
  bodyContent: {
    flex: 1,
    paddingTop: 10,
  },
});
