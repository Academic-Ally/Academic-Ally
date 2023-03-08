import {
  StyleSheet,
  Text,
  View,
  SafeAreaView,
  Dimensions,
  StatusBar,
  Image,
  ScrollView,
  Alert,
} from 'react-native';
import {NavigationProp, ParamListBase} from '@react-navigation/native';
import React, {FC, useMemo, useEffect, useState} from 'react';
import LinearGradient from 'react-native-linear-gradient';
import {SIGNUPILLUSTRATION} from '../../../assets';
import {
  CustomBtn,
  NavBtn,
} from '../../../components/CustomFormComponents/CustomBtn';
import {CustomTextInput} from '../../../components/CustomFormComponents/CustomTextInput';
import Form from '../../../components/Forms/form';
import DropdownComponent from '../../../components/CustomFormComponents/Dropdown';
import {validationSchema} from '../../../utilis/validation';
import createStyles from './styles';
import {createUser} from '../../../Modules/auth/firebase/firebase';
import auth from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import {useDispatch} from 'react-redux';
import {setUsersData} from '../../../redux/reducers/usersData';
import CustomLoader from '../../../components/CustomLoader';

const screenWidth = Dimensions.get('screen').width;

interface IProps {
  navigation: NavigationProp<ParamListBase>;
}
const SignUpScreen: FC<IProps> = ({navigation}) => {
  const dispatch = useDispatch();

  const styles = useMemo(() => createStyles(), []);
  const [loading, setLoading] = useState(false);

  const initialValues = {
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    course: '',
    sem: '',
    branch: '',
    year: '',
    university: '',
    college: '',
  };
  const CourseData: any = [
    {label: 'B.E', value: 'BE'},
    {label: 'B.TECH', value: 'BTECH'},
  ];
  const SemData: any = [
    {label: '1', value: '1'},
    {label: '2', value: '2'},
    {label: '3', value: '3'},
    {label: '4', value: '4'},
    {label: '5', value: '5'},
    {label: '6', value: '6'},
    {label: '7', value: '7'},
    {label: '8', value: '8'},
  ];

  const YearData: any = [
    {label: '1', value: '1'},
    {label: '2', value: '2'},
    {label: '3', value: '3'},
    {label: '4', value: '4'},
  ];

  const BranchData: any = [
    {label: 'IT', value: 'IT'},
    {label: 'CSE', value: 'CSE'},
    {label: 'ECE', value: 'ECE'},
    {label: 'MECH', value: 'MECH'},
    {label: 'CIVIL', value: 'CIVIL'},
    {label: 'EEE', value: 'EEE'},
  ];

  const UniversityData: any = [{label: 'Osmania University', value: 'OU'}];

  const onSubmit = (email: string, password: string, initialValues: any) => {
    createUser(email, password, initialValues)
      .then(() => {
        firestore()
          .collection('Users')
          .doc(auth().currentUser?.uid)
          .get()
          .then(doc => {
            if (doc.exists) {
              dispatch(setUsersData(doc.data()));
            }
          });
      })
      .catch(error => {
        Alert.alert(error.message);
      });
  };

  return (
    <SafeAreaView style={[styles.container, {flex: 1}]}>
      <CustomLoader loading={loading} />
      <StatusBar
        animated={true}
        translucent={true}
        backgroundColor={'transparent'}
      />

      <LinearGradient
        colors={['#FF8181', '#6360ff']}
        start={{x: 0.5, y: 0.5}}
        end={{x: 0.5, y: 1}}
        style={styles.LinearGradient}>
        <ScrollView
          style={{flex: 1}}
          contentContainerStyle={{flexGrow: 1}}
          scrollEnabled={true}>
          <Image source={SIGNUPILLUSTRATION} style={styles.studyIcon} />
          <Text style={styles.welcomeText}> Hi there!</Text>
          <Text style={styles.loginText}>Let's Get Started</Text>
          <View style={styles.inputContainer}>
            <Form
              validationSchema={validationSchema}
              initialValues={initialValues}
              onSubmit={values => {
                setLoading(true);
                onSubmit(values.email, values.password, values);
              }}>
              <CustomTextInput
                leftIcon="user"
                placeholder="Full Name"
                name="name"
              />
              <CustomTextInput
                leftIcon="mail"
                placeholder="Email"
                name="email"
              />
              <CustomTextInput
                leftIcon="lock"
                placeholder="Password"
                name="password"
              />
              <CustomTextInput
                leftIcon="lock"
                placeholder="Confirm Password"
                handlePasswordVisibility
                name="confirmPassword"
              />
              <DropdownComponent
                name="university"
                data={UniversityData}
                placeholder={'Select the name of your university'}
                leftIcon="ellipsis1"
                width={screenWidth - 50}
              />
              <View
                style={{
                  flexDirection: 'row',
                  width: screenWidth - 50,
                  flex: 1,
                  justifyContent: 'space-between',
                }}>
                <DropdownComponent
                  name="course"
                  data={CourseData}
                  placeholder={'Course'}
                  leftIcon="Safety"
                  width={screenWidth / 2.5}
                />
                <DropdownComponent
                  name="branch"
                  data={BranchData}
                  placeholder={'Branch'}
                  leftIcon="bars"
                  width={screenWidth / 2.5}
                />
              </View>
              <View
                style={{
                  flexDirection: 'row',
                  width: screenWidth - 50,
                  flex: 1,
                  justifyContent: 'space-between',
                }}>
                <DropdownComponent
                  name="year"
                  data={YearData}
                  placeholder={'Studying year'}
                  leftIcon="bars"
                  width={screenWidth / 2.5}
                />
                <DropdownComponent
                  name="sem"
                  data={SemData}
                  placeholder={'Semester'}
                  leftIcon="ellipsis1"
                  width={screenWidth / 2.5}
                />
              </View>

              <CustomTextInput
                leftIcon="user"
                placeholder="College Name"
                name="college"
              />
              <View style={styles.SignupButton}>
                <CustomBtn title="Sign Up" color="#6360FF" />
              </View>
              <Text style={styles.orText}>Or</Text>
              <View style={styles.LoginButton}>
                <NavBtn
                  title="Log In"
                  onPress={() => {
                    navigation.navigate('LoginScreen');
                  }}
                  color="#FF8181"
                />
              </View>
            </Form>
          </View>
        </ScrollView>
      </LinearGradient>
    </SafeAreaView>
  );
};

export default SignUpScreen;
