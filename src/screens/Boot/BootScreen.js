import AsyncStorage from '@react-native-async-storage/async-storage';
import messaging from '@react-native-firebase/messaging';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createDrawerNavigator, DrawerActions } from '@react-navigation/drawer';
import { createStackNavigator } from '@react-navigation/stack';
import { Avatar } from 'native-base';
import React, { useEffect, useState } from 'react';
import { Alert, Dimensions, Linking, Pressable, StatusBar, Text, View } from 'react-native';
import Feather from "react-native-vector-icons/Feather";
import Fontisto from "react-native-vector-icons/Fontisto";
import Ionicons from "react-native-vector-icons/Ionicons";
import MaterialCommunityIcons from "react-native-vector-icons/MaterialCommunityIcons";
import { useDispatch, useSelector } from 'react-redux';

import { version as app_version } from '../../../package.json';
import { getCurrentUser } from '../../Modules/auth/firebase/firebase';
import UserRequestsPdfViewer from '../../sections/UserRequests/UserRequestsPdfViewer';
import NavigationService from '../../services/NavigationService';
import { useAuthentication } from '../../utilis/hooks/useAuthentication';
import AllyBotScreen from '../AllyBot/AllyBotScreen';
import AuthScreen from '../AuthenticationScreens/authScreen'
import Bookmark from '../Bookmark/Bookmark';
import DownloadScreen from '../Downloads/DownloadScreen';
import HomeScreen from '../Home/homeScreen';
import NotesList from '../Notes/NotesListScreen';
import UploadScreen from '../Notes/uploadScreen';
import OnBoardingScreen from '../OnBoardingScreen/OnBoardingScreen';
import PdfViewer from '../PdfViewer/pdfViewerScreen';
import UpdateInformation from '../Profile/AccountSettings/UpdateInformation';
import Profile from '../Profile/profile';
import AboutUs from '../Profile/Support/AboutUs';
import PrivacyPolicy from '../Profile/Support/PrivacyPolicy';
import TermsAndConditions from '../Profile/Support/Terms&Conditions';
import RecentScreen from '../Recents/RecentScreen';
import Search from '../Search/searchScreen';
import SeekHubScreen from '../SeekHub/SeekHubScreen';
import SubjectResources from '../SubjectResources/SubjectResourcesScreen';
import Upload from '../Upload/uploadScreen';
import UserRequestsScreen from '../UserRequests/UserRequestsScreen';
import BootActions from './BootAction';
import SeekHubRequestsScreen from '../SeekHub/SeekHubRequest';
import UserUploadRequestsScreen from '../Upload/UserUploadRequest';

const { height, width } = Dimensions.get("screen");
const Drawer = createDrawerNavigator();
const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const DrawerScreen = ({ navigation }) => {
    return (
        <Drawer.Navigator>
            <Drawer.Screen
                name="Home"
                component={HomeScreen}
                options={{
                    headerShown: false,
                    headerStyle: {
                        backgroundColor: '#6360FF',
                        elevation: 0,
                    },
                    headerLeft: ({ props }) => (
                        <View style={{ flexDirection: 'row', marginLeft: 20 }}>
                            <Pressable onPress={() => navigation.dispatch(DrawerActions.openDrawer())}>
                                <Feather name='menu' color={"#ffffff"} size={20} />
                            </Pressable>
                        </View>
                    ),
                    headerRight: () => (
                        <View style={{ flexDirection: 'row', marginRight: 20 }}>
                            <Pressable onPress={() => navigation.navigate('Notes')}>
                                <Ionicons name='ios-notifications-outline' color={"#ffffff"} size={20} />
                            </Pressable>
                        </View>
                    ),
                }}
            />
        </Drawer.Navigator>
    );
};

const BottomTabBar = () => {
    const theme = useSelector((state) => state.theme);
    const customClaims = useSelector((state) => state.bootReducer.customClaims);
    
  const {photoURL} = useSelector((state) => state.bootReducer.userInfo)|| "";

    const TabIcon = ({ focused, iconName, labelText }) => (
        <View style={{ 
            alignItems: 'center', 
            justifyContent: 'center', 
            width: width * 0.18,
            paddingVertical: 8
        }}>
            <Feather 
                name={iconName} 
                size={theme.sizes.iconMedium} 
                color={focused ? '#FF8181' : theme.colors.primaryText} 
                style={{ marginBottom: focused ? 4 : 0 }} 
            />
            {focused ? (
                <Text style={{ 
                    color: '#FF8181', 
                    fontSize: theme.sizes.textSmall, 
                    fontWeight: '500',
                    textAlign: "center",
                    marginTop: 2
                }}>
                    {labelText}
                </Text>
            ) : null}
        </View>
    );

    return (
        <>
            <StatusBar barStyle="light-content" />
            <Tab.Navigator
                screenOptions={{
                    tabBarHideOnKeyboard: false,
                    tabBarShowLabel: false,
                    headerShown: false,
                    tabBarStyle: {
                        position: "absolute",
                        height: height * 0.09,
                        backgroundColor: theme.colors.quaternary,
                        borderTopLeftRadius: 30,
                        borderTopRightRadius: 30,
                        elevation: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        overflow: "hidden",
                        borderTopWidth: 0,
                        paddingBottom: Platform.OS === 'ios' ? 20 : 8,
                        paddingTop: 8,
                        shadowColor: '#000',
                        shadowOffset: {
                            width: 0,
                            height: -2,
                        },
                        shadowOpacity: 0.1,
                        shadowRadius: 3,
                    },
                }}
            >
                <Tab.Screen
                    name={NavigationService.screens.Home}
                    options={{
                        tabBarIcon: ({ focused }) => (
                            <TabIcon focused={focused} iconName="home" labelText="Home" />
                        ),
                    }}
                    component={HomeScreen}
                />
                <Tab.Screen
                    name={NavigationService.screens.Search}
                    options={{
                        tabBarIcon: ({ focused }) => (
                            <TabIcon focused={focused} iconName="search" labelText="Search" />
                        ),
                    }}
                    component={Search}
                />
                <Tab.Screen
                    name={NavigationService.screens.UploadScreen}
                    options={{
                        tabBarIcon: ({ focused }) => (
                            <TabIcon focused={focused} iconName="upload" labelText="Upload" />
                        ),
                    }}
                    component={Upload}
                />
                <Tab.Screen
                    name={NavigationService.screens.Bookmark}
                    options={{
                        tabBarIcon: ({ focused }) => (
                            <View style={{ alignItems: 'center', justifyContent: 'center', width: width * 0.23 }}>
                                <Fontisto name={focused ? 'bookmark-alt' : 'bookmark'} size={theme.sizes.iconMedium} color={focused ? '#FF8181' : theme.colors.primaryText} style={{
                                    bottom: focused ? 3 : 0,
                                }} />
                                {
                                    focused ? <Text style={{ color: '#FF8181', fontSize: 10, fontWeight: '400', textAlign: "center", bottom: 0 }}>Saved</Text> : null
                                }
                            </View>
                        ),
                    }}
                    component={Bookmark}
                />
                {
                    (customClaims?.admin === true) || (customClaims?.moderator === true) ?
                        <Tab.Screen
                            name="Admin"
                            options={{
                                tabBarIcon: ({ focused }) => (
                                    <View style={{ alignItems: 'center', justifyContent: 'center', width: width * 0.23 }}>
                                        <MaterialCommunityIcons name={"clipboard-edit-outline"} size={theme.sizes.iconMedium} color={focused ? '#FF8181' : theme.colors.primaryText} style={{ bottom: focused ? 3 : 0 }} />
                                        {focused ? <Text style={{ color: '#FF8181', fontSize: theme.sizes.textSmall, fontWeight: '400', textAlign: "center", bottom: 0 }}>Requests</Text> : null}
                                    </View>
                                ),
                            }}
                            component={UserRequestsScreen}
                        /> 
                        
                        : null
                }
                <Tab.Screen
                    name={NavigationService.screens.Profile}
                    options={{
                        tabBarIcon: ({ focused }) => (
                            <View style={{ alignItems: 'center', justifyContent: 'center', width: width * 0.23 }}>
                                <Avatar style={{ bottom: focused ? 3 : 0 }} source={{
                                  uri: photoURL
                                }} size={theme.sizes.iconMedium} alignSelf={'center'} />
                                {focused ? <Text style={{ color: '#FF8181', fontSize: theme.sizes.textSmall, fontWeight: '400', textAlign: "center", bottom: 0 }}>Account</Text> : null}
                            </View>
                        ),
                    }}
                    component={Profile}
                />
            </Tab.Navigator>
        </>
    );
};

const AppStack = () => {
    const customClaims = useSelector((state) => state.bootReducer.customClaims);
    return (
        <Stack.Navigator initialRouteName={NavigationService.screens.BottomTabNavigator} screenOptions={{ headerShown: false, animationEnabled: false }}>
            <Stack.Screen name={NavigationService.screens.BottomTabNavigator} component={BottomTabBar} />
            <Stack.Screen name={NavigationService.screens.SubjectResourcesScreen} component={SubjectResources} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.Resources} component={NotesList} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.Upload} component={UploadScreen} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.PdfViewer} component={PdfViewer} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.UpdateProfile} component={UpdateInformation} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.PrivacyPolicy} component={PrivacyPolicy} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.TermsAndConditions} component={TermsAndConditions} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.AboutUs} component={AboutUs} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.UserRequestsPdfViewer} component={UserRequestsPdfViewer} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.Download} component={DownloadScreen} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.AllyBot} component={AllyBotScreen} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.SeekHub} component={SeekHubScreen} options={{ headerShown: false }} />
            <Stack.Screen name={NavigationService.screens.Recents} component={RecentScreen} options={{ headerShown: false }} />
            {
                (customClaims?.admin === true) || (customClaims?.moderator === true) ?
                <>
                 <Stack.Screen name={NavigationService.screens.SeekHubRequests} component={SeekHubRequestsScreen} options={{ headerShown: false }} />
                 <Stack.Screen name={NavigationService.screens.UserUploadsRequest} component={UserUploadRequestsScreen} options={{ headerShown: false }} />
                </>
                : null 
            }
        </Stack.Navigator>
    );
};

const AuthStack = () => {
    const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);

    useEffect(() => {
        checkOnboardingStatus();
    }, []);

    const checkOnboardingStatus = async () => {
        const completed = await AsyncStorage.getItem('hasCompletedOnboarding');
        if (completed === 'true') {
            setHasCompletedOnboarding(true);
        }
    };

    const screenOptions = {
        headerShown: false,
        animationEnabled: false,
    };

    return (
        <Stack.Navigator initialRouteName={!hasCompletedOnboarding ? NavigationService.screens.Intro : NavigationService.screens.Intro} screenOptions={screenOptions}>
            {!hasCompletedOnboarding ? (
                <Stack.Screen name={NavigationService.screens.Intro} component={OnBoardingScreen} options={screenOptions} />
                ) : null}
                <Stack.Screen name={NavigationService.screens.Auth} component={AuthScreen} options={screenOptions} />
        </Stack.Navigator>
    );
};

const BootScreen = () => {
    const requiredVersion = useSelector((state) => state.bootReducer.requiredVersion);
    const currentUser = getCurrentUser();
    const { user } = useAuthentication();
    const dispatch = useDispatch();
    const [compatible, setCompatible] = useState(true);
    const [initializing, setInitializing] = useState(true)
    const currentVersion = app_version;
    const userInfo = useSelector((state)=> state.bootReducer.userInfo)

    const convertToNumber = (version) => {
        const versionParts = version.split(".");
        let number = 0;

        for (let i = 0; i < versionParts.length; i++) {
            const part = versionParts[i];
            number += parseInt(part) / Math.pow(10, i + 1);
        }

        return number;
    };

    useEffect(() => {
        try {
            dispatch(BootActions.loadUtils(currentUser));
            dispatch(BootActions.loadUserCustomClaims(currentUser));
            dispatch(BootActions.loadProtectedUtils())
        }
        catch (e) {
            console.log('Initialization error', e)
        }
        finally {
            setInitializing(false)
        }
    }, [currentUser, user]);

    useEffect(() => {
        if (requiredVersion !== null) {
            if (convertToNumber(currentVersion) < convertToNumber(requiredVersion)) {
                setCompatible(false);
            }
        }
    }, [requiredVersion, currentVersion, currentUser, user]);

    useEffect(() => {
        if (compatible === false) {
            Alert.alert(
                "Update Required",
                "Please update the app to continue using it.",
                [
                    {
                        text: "Update",
                        onPress: () => {
                            Linking.openURL("https://play.google.com/store/apps/details?id=com.academically");
                            setCompatible(false);
                        },
                    },
                ],
                { cancelable: false },
            );
        }
    }, [compatible]);

    const handleNotification = async (messageObj) => {
        const channelId = messageObj?.notification?.android?.channelId;
        switch (channelId) {
            case 'Notes':
                Linking.openURL(`https://academicallyapp.page.link/${messageObj?.data.notesId}`);
                break;
            case 'UserProfile':
                Linking.openURL(`https://academicallyapp.page.link/${messageObj?.data.userId}`);
                break;
            case 'SeekHub':
                NavigationService.navigate(NavigationService.screens.SeekHub)
                break;
            case 'Recents':
                NavigationService.navigate(NavigationService.screens.Recents)
                break;
            case 'UserRequestsPdfViewer':
                Linking.openURL("https://academicallyapp.page.link/UserRequestsPdfViewer");
                break;
            case 'AboutUs':
                NavigationService.navigate(NavigationService.screens.AboutUs)
                break;
            case 'UpdateProfile':
                NavigationService.navigate(NavigationService.screens.Profile)
                break;
            case 'PdfViewer':
                Linking.openURL("https://academicallyapp.page.link/PdfViewer");
                break;
            case 'Profile':
                Linking.openURL("https://academicallyapp.page.link/Profile");
                break;
            case 'UploadScreen':
                NavigationService.navigate(NavigationService.screens.UploadScreen)
                break;
            case 'Search':
                NavigationService.navigate(NavigationService.screens.Search)
                break;
            case 'Bookmark':
                NavigationService.navigate(NavigationService.screens.Bookmark)
                break;
            default:
                break;
        }
    };
    

    useEffect(() => {
        // Handle foreground messages
        const messageListener = messaging().onMessage(async messageObj => {
            handleNotification(messageObj);
        });

        // Handle initial notification when app is opened from quit state
        messaging().getInitialNotification().then(async messageObj => {
            if (messageObj?.data?.notesId) {
                handleNotification(messageObj);
            }
        });

        return () => {
            messageListener();
        };
    }, []);

    if (initializing) {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                <Text>Loading...</Text>
            </View>
        );
    }

    else {
        return (userInfo !== null) ? <AppStack /> : <AuthStack />;
    }

};

export default BootScreen;
