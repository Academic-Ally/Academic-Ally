import AsyncStorage from '@react-native-async-storage/async-storage';
import auth from '@react-native-firebase/auth';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { AlertDialog, Avatar, Box, Button, Modal, Stack, Toast, VStack } from 'native-base';
import React, { useMemo, useState } from 'react';
import { Dimensions, Linking, ScrollView, Share, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Ionicons from 'react-native-vector-icons/Ionicons';
import { useDispatch, useSelector } from 'react-redux';

import { setUserProfile } from '../../redux/reducers/usersData';
import createStyles from './styles';

type MyStackParamList = {
  'UpdateInformation': undefined;
  'PrivacyPolicy': undefined;
  'TermsAndConditions': undefined;
  'AboutUs': undefined;
};
const height = Dimensions.get('screen').height;
const width = Dimensions.get('screen').width;

const Profile = () => {
  const theme = useSelector((state: any) => { return state.theme });
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
  const user = auth().currentUser;
  const [isOpen, setIsOpen] = React.useState(false);
  const [password, setPassword] = useState<string>('');
  const [logOutAlert, setLogOutAlert] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const userImage = useSelector((state: any) => {
    return state.usersData.userProfile;
  });
  const onClose = () => setIsOpen(false);
  const onCloseLogout = () => setLogOutAlert(false);
  const cancelRef = React.useRef(null);
  type MyScreenNavigationProp = StackNavigationProp<
    MyStackParamList,
    'UpdateInformation'
  >;
  const dispatch = useDispatch();
  const navigation = useNavigation<MyScreenNavigationProp>();
  const userFirestoreData = useSelector((state: any) => {
    return state.usersData;
  });

  return (
    <View style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.headerContainer}>
          <View
            style={{
              flexDirection: 'row',
            }}>
            {/* <Ionicons
            name="chevron-back-outline"
            size={20}
            color="#ffffff"
            onPress={() => {
              navigation.goBack();
            }}
          /> */}
            <Text style={styles.headerText}>Account</Text>
          </View>
          <VStack alignItems="center" space={0} marginY={theme.sizes.height * 0.023} width={"100%"} justifyContent={"center"} >
            <Avatar source={{
              uri: userImage || user?.photoURL
            }} size={theme.sizes.height * 0.16} alignSelf={'center'} />
          </VStack>
          <Text style={styles.name}>{userFirestoreData.usersData.name}</Text>
          <Text style={styles.email}>{userFirestoreData.usersData.email}</Text>
        </View>
        <View style={styles.body}>
          <View style={styles.bodyContent}>
            <View style={styles.menuContainer}>
              <VStack>
                <View>
                  <Text style={styles.settingsTitleText}>Account Settings</Text>
                </View>
                <TouchableOpacity
                  style={styles.settingsContainer}
                  onPress={() => {
                    navigation.navigate('UpdateInformation');
                  }}>
                  <Text style={styles.settingsText}>Update Profile</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.settingsContainer}
                  onPress={() => {
                    setLogOutAlert(!logOutAlert);
                  }}>
                  <Text style={styles.settingsText}>Log Out</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.settingsContainer}
                  onPress={() => setIsOpen(!isOpen)}>
                  <Text style={styles.settingsText}>Delete Account</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
              </VStack>
            </View>
            <View style={styles.menuContainer}>
              <VStack>
                <View>
                  <Text style={[styles.settingsTitleText, {
                    marginTop: 10,
                  }]}>Support</Text>
                </View>
                <TouchableOpacity
                  onPress={() => { navigation.navigate('AboutUs') }}
                  style={styles.settingsContainer}>
                  <Text style={styles.settingsText}>About Us</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => {
                    Share.share({
                      title: 'Academic Ally',
                      message: "Are you tired of spending hours searching for academic resources for your courses? Let Academic Ally make it easy for you! Our app provides a vast collection of notes, question papers, question banks, syllabi, and other resources for a wide range of courses, from BE to BTech and more incoming! With Academic Ally, you can access high-quality resources at your fingertips, bookmark your preferred notes, share resources with classmates, and even upload your own notes to help others. Say goodbye to the hassle of finding the right academic resources and download Academic Ally now! \n \nGet Your Ally Right Away!: https://play.google.com/store/apps/details?id=com.academically",
                    })
                  }}
                  style={styles.settingsContainer}>
                  <Text style={styles.settingsText}>Share Academic Ally</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => {
                    Linking.openURL('mailto:contact@getacademically.co')
                  }}
                  style={styles.settingsContainer}>
                  <Text style={styles.settingsText}>Get in Touch</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => {
                    navigation.navigate('PrivacyPolicy')
                  }}
                  style={styles.settingsContainer}>
                  <Text style={styles.settingsText}>Privacy Policy</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.settingsContainer} onPress={() => {
                    navigation.navigate('TermsAndConditions')
                  }} >
                  <Text style={styles.settingsText}>Terms & Conditions</Text>
                  <Ionicons
                    name="chevron-forward-outline"
                    size={20}
                    color="#91919F"
                  />
                </TouchableOpacity>

              </VStack>
            </View>
          </View>

        </View>
        <AlertDialog
          leastDestructiveRef={cancelRef}
          isOpen={isOpen}
          onClose={onClose}>
          <AlertDialog.Content>
            <AlertDialog.CloseButton />
            <AlertDialog.Header>Delete Account</AlertDialog.Header>
            <AlertDialog.Body>
              <Text style={{ color: '#91919F', fontSize: 16 }} >
                By proceeding with this action, you will be permanently deleting all account data. This action cannot be undone. Once the data is deleted, it cannot be recovered.
              </Text>
              <Text style={{ color: '#161719', fontSize: 16, marginTop: 10 }} >
                Are you sure you want to proceed?
              </Text>
              {/* <TextInput
              onChangeText={text => {
                setPassword(text);
              }}
              placeholder="Enter your password to confirm"
              style={{
                borderWidth: 1,
                borderRadius: 10,
                padding: 10,
                borderBottomColor: '#91919F',
                marginTop: 10,
                marginBottom: 10,
                alignSelf: 'center',
                color: '#91919F',
                width: width * 0.6,
              }}
            /> */}
            </AlertDialog.Body>
            <AlertDialog.Footer>
              <Button.Group space={2}>
                <Button
                  variant="unstyled"
                  colorScheme="coolGray"
                  onPress={onClose}
                  ref={cancelRef}>
                  Cancel
                </Button>
                <Button
                  colorScheme="danger"
                  onPress={() => {
                    auth()
                      ?.currentUser?.delete()
                      .then(() => {
                        AsyncStorage.clear();
                        Toast.show({
                          title: 'Account Deleted',
                          backgroundColor: '#F44336',
                          color: '#ffffff',
                        });
                      })
                      .catch(error => {
                        auth().signOut();
                        AsyncStorage.clear();
                        Toast.show({
                          title: 'Error',
                          description: error.message,
                          backgroundColor: '#F44336',
                          color: '#ffffff',
                        });
                      });
                  }}>
                  Delete
                </Button>
              </Button.Group>
            </AlertDialog.Footer>
          </AlertDialog.Content>
        </AlertDialog>
        <AlertDialog
          leastDestructiveRef={cancelRef}
          isOpen={logOutAlert}
          onClose={onCloseLogout}>
          <AlertDialog.Content>
            <AlertDialog.CloseButton />
            <AlertDialog.Header>Log Out</AlertDialog.Header>
            <AlertDialog.Body>
              <Text style={{ color: '#91919F', fontSize: 16 }} >
                Are you sure you want to log out?
              </Text>
              {/* <TextInput
              onChangeText={text => {
                setPassword(text);
              }}
              placeholder="Enter your password to confirm"
              style={{
                borderWidth: 1,
                borderRadius: 10,
                padding: 10,
                borderBottomColor: '#91919F',
                marginTop: 10,
                marginBottom: 10,
                alignSelf: 'center',
                color: '#91919F',
                width: width * 0.6,
              }}
            /> */}
            </AlertDialog.Body>
            <AlertDialog.Footer>
              <Button.Group space={2}>
                <Button
                  variant="unstyled"
                  colorScheme="coolGray"
                  onPress={onCloseLogout}
                  ref={cancelRef}>
                  Cancel
                </Button>
                <Button
                  colorScheme="danger"
                  onPress={() => {
                    auth().signOut();
                    AsyncStorage.clear();
                  }}>
                  Log Out
                </Button>
              </Button.Group>
            </AlertDialog.Footer>
          </AlertDialog.Content>
        </AlertDialog>
      </ScrollView>
    </View>
  );
};

export default Profile;

const styles = StyleSheet.create({});
