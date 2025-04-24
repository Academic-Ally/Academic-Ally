import dynamicLinks from '@react-native-firebase/dynamic-links';
import { Toast } from 'native-base';
import { background } from 'native-base/lib/typescript/theme/styled-system';
import React, { useEffect, useMemo, useState } from 'react';
import { Image, ScrollView, Text, TouchableOpacity, useColorScheme, View, StatusBar, Animated, SafeAreaView, Dimensions, Platform } from 'react-native';
import FontAwesome5 from 'react-native-vector-icons/FontAwesome5';
import Ionicons from 'react-native-vector-icons/Ionicons';
import { useDispatch, useSelector } from 'react-redux';

import QuickAccess from '../../components/CustomFormComponents/QuickAccess/QuickAccess';
import RoundedDropdown from '../../components/CustomFormComponents/RoundedDropdown';
import CustomLoader from '../../components/loaders/CustomLoader';
import ResourceLoader from '../../components/loaders/ResourceLoader';
import ScreenLayout from '../../layouts/screenLayout';
import { setDarkTheme, setLightTheme } from '../../redux/reducers/theme';
import { setCustomLoader, setResourceLoader } from '../../redux/reducers/userState';
import Recommendation from '../../sections/Home/Recommendation/Recommendation';
import { getFcmToken } from '../../services/fetch';
import NavigationService from '../../services/NavigationService';
import UtilityService from '../../services/UtilityService';
import HomeAction from './homeAction';
import createStyles from './styles';

const { width, height } = Dimensions.get('window');

const HomeScreen = () => {
  const colorScheme = useColorScheme();
  const theme = useSelector((state: any) => state.theme);
  const dispatch: any = useDispatch();
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const usersProfileData = useSelector((state: any) => state.usersData);
  const [listData, setListData] = useState([]);
  const bookmarkList = useSelector((state: any) => state.userBookmarkManagement).userBookMarks;
  const {uid, photoURL}: any = useSelector((state: any) => state.bootReducer.userInfo);
  const scrollY = React.useRef(new Animated.Value(0)).current;

  useEffect(() => {
    colorScheme === 'dark' ? dispatch(setDarkTheme()) : dispatch(setLightTheme());
  }, [colorScheme]);

  useEffect(() => {
    if(uid !== null){
      dispatch(HomeAction.loadUserData(uid));
      dispatch(HomeAction.loadBoomarks(bookmarkList, setListData, uid));
      getFcmToken();
    }
  }, []);

  const handleDynamicLink = (link: string) => {
    if (link && link !== null && link !== undefined) {
      // dispatch(setCustomLoader(true));
      const { userData, notesData, screen } = UtilityService.getDynamicLinkData(link);
      if (userData && notesData) {
        if (screen === 'SubjectResources') {
          dispatch(setCustomLoader(false));
          dispatch(HomeAction.getSubjectResources(userData, { subject: notesData.subject, subjectName: notesData.subject }));
        } 
        else if (screen === 'viewPdf') {
          dispatch(setCustomLoader(false));
          NavigationService.navigate(NavigationService.screens.PdfViewer, {
            userData,
            notesData,
          });
        }
        else {
          dispatch(setCustomLoader(false));
          Toast.show({
            title: 'Link Expired',
            description: 'The link you tried to access has expired.',
            background: '#FF0000'
          })
        } 
      }
    }
  };

  useEffect(() => {
    dynamicLinks()
      .getInitialLink()
      .then((link: any) => {
        handleDynamicLink(link);
      })
      .catch((error: any) => {
        dispatch(setCustomLoader(false));
        if (error?.code === 'dynamicLinks/initial-link-error') {
          return;
        }
      });
  }, []);

  useEffect(() => {
    const unsubscribe = dynamicLinks().onLink((link: any) => handleDynamicLink(link));
    return () => unsubscribe();
  }, []);
  
  // Calculate header opacity for scroll effect
  const headerOpacity = scrollY.interpolate({
    inputRange: [0, 100],
    outputRange: [1, 0.95],
    extrapolate: 'clamp',
  });

  const responsiveIconSize = Math.min(width * 0.055, theme.sizes.iconMedium);
  const avatarSize = Math.min(width * 0.09, 36);
  
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#6360FF' }}>
      <StatusBar backgroundColor="#6360FF" barStyle="light-content" />
      <ScreenLayout name="Home">
        <ResourceLoader />
        <CustomLoader />
        <Animated.ScrollView
          showsVerticalScrollIndicator={false}
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true }
          )}
          scrollEventThrottle={16}
          style={{
            flex: 1,
            backgroundColor: theme.colors.primary,
          }}>
          <Animated.View style={[styles.header, { opacity: headerOpacity }]}>
            <View>
              <View style={styles.userInfo}>
                <View
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                  }}>
                  <TouchableOpacity
                    style={[styles.userImgContainer, { width: avatarSize, height: avatarSize, borderRadius: avatarSize / 2 }]}
                    onPress={() => {
                      NavigationService.navigate(NavigationService.screens.Profile);
                    }}>
                    <Image
                      source={{
                        uri: usersProfileData.userProfile || photoURL,
                      }}
                      style={[styles.userImg, { width: avatarSize - 2, height: avatarSize - 2, borderRadius: (avatarSize - 2) / 2 }]}
                    />
                  </TouchableOpacity>
                  <View
                    style={{
                      marginLeft: width * 0.025,
                    }}>
                    <Text style={[styles.salutation, { fontSize: Math.max(width * 0.03, 12) }]}>Welcome back</Text>
                    <Text style={[styles.userName, { fontSize: Math.max(width * 0.045, 16) }]}>{usersProfileData.usersData?.name}</Text>
                  </View>
                </View>
                <TouchableOpacity 
                  style={{
                    width: avatarSize,
                    height: avatarSize,
                    borderRadius: avatarSize / 2,
                    backgroundColor: 'rgba(255,255,255,0.15)',
                    justifyContent: 'center',
                    alignItems: 'center',
                  }}>
                  {theme.theme === 'light' ? (
                    <FontAwesome5
                      onPress={() => {
                        dispatch(setDarkTheme());
                      }}
                      name="cloud-moon"
                      color={'#ffffff'}
                      size={responsiveIconSize}
                    />
                  ) : (
                    <Ionicons
                      onPress={() => {
                        dispatch(setLightTheme());
                      }}
                      name="md-sunny"
                      color={'#ffffff'}
                      size={responsiveIconSize}
                    />
                  )}
                </TouchableOpacity>
              </View>
            </View>
          </Animated.View>
          <QuickAccess
            selected={selectedCategory}
            setSelectedCategory={(option) => {
              setSelectedCategory(option);
            }}
          />
          <View style={styles.recommendedContainer}>
            <View style={styles.subContainer}>
              <Text style={styles.recommendedText}>Recommended</Text>
              <RoundedDropdown 
                name='drop' 
                width={width * 0.4} 
                data={[
                  { label: 'All', value: 'All' },
                  { label: 'Notes', value: 'Notes' },
                  { label: 'Syllabus', value: 'Syllabus' },
                  { label: 'Question Papers', value: 'QuestionPapers' },
                  { label: 'Other Resources', value: 'OtherResources' },
                ]} 
                placeholder='Resource Type' 
                searchbar={false} 
                color={theme.colors.tertiary}
                handleOptions={(item: any)=>{
                  setSelectedCategory(item)
                }}
              />
            </View>
            <View>
              <Recommendation
                selected={selectedCategory}
                setResourcesLoaded={(option: boolean) => {
                  dispatch(setResourceLoader(option));
                }}
              />
            </View>
          </View>
        </Animated.ScrollView>
      </ScreenLayout>
    </SafeAreaView>
  );
};

export default HomeScreen;