import { useNavigation } from '@react-navigation/native';
import { Icon, IconButton } from 'native-base'
import React, { useMemo } from 'react';
import { ScrollView, StatusBar, StyleSheet, Text, View } from 'react-native';
import Ionicons from 'react-native-vector-icons/Ionicons';
import Octicons from 'react-native-vector-icons/Octicons';
import { useSelector } from 'react-redux';

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
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        <View style={{
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center',
          width: '100%',
          paddingHorizontal: 20,
        }} >
          <StatusBar
            translucent={true}
            backgroundColor={theme.colors.primary}
            barStyle={'light-content'}
          />
          <IconButton
            borderRadius={'full'}
            _hover={{
              bg: '#D3D3D3',
            }}
            _pressed={{
              bg: '#D3D3D3',
            }}
            onPress={() => { navigation.goBack() }}
            variant="ghost"
            icon={<Icon as={Ionicons} name="chevron-back-outline" size={'lg'} color={theme.colors.white} />}
            p={0}
          />
          {title && (
            <View style={styles.header}>
              <Text style={styles.headerText}>{title}</Text>
            </View>
          )}
          {!rightIconFalse && (
            <IconButton
              borderRadius={'full'}
              _hover={{
                bg: '#D3D3D3',
              }}
              _pressed={{
                bg: '#D3D3D3',
              }}
              onPress={handleShare}
              variant="ghost"
              icon={<Icon as={Ionicons} name="md-share-social-outline" size={'lg'} color={theme.colors.white} />}
              p={0}
            />
          )}
          {rightIconFalse && (
            // empty view
            <View style={{ width: 30 }} />
          )}
        </View>
      </View>
      <View style={styles.body}>
        <View style={styles.bodyContent}>
          <StatusBar barStyle="light-content" backgroundColor={theme.colors.primary} />
          <ScrollView
            onScroll={handleScroll}
            showsVerticalScrollIndicator={false}>
            {children}
          </ScrollView>
        </View>
      </View>
    </View>
  );
};

export default navigationLayout;

const styles = StyleSheet.create({});
