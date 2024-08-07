import { NavigationProp, ParamListBase } from '@react-navigation/native';
import { Toast } from 'native-base';
import React, { FC, useEffect, useMemo, useRef, useState } from 'react';
import { Dimensions, Text, View } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { CustomBtn, NavBtn } from '../../../components/CustomFormComponents/CustomBtn';
import { CustomTextInput } from '../../../components/CustomFormComponents/CustomTextInput';
import DropdownComponent from '../../../components/CustomFormComponents/Dropdown';
import Form from '../../../components/Forms/form';
import { setCustomLoader } from '../../../redux/reducers/userState';
import { validationSchema } from '../../../utilis/validation';
import AuthAction from '../authActions';
import createStyles from './styles';

const screenWidth = Dimensions.get('screen').width;

type props = {
  onPress: any
}

const SignUpScreen = ({onPress}: props) => {
  const dispatch: any = useDispatch();
  const styles = useMemo(() => createStyles(), []);
  const formRef: any = useRef();
  const [selectedYear, setSelectedYear] = useState<any>(null);
  const [BranchData, setBranchData] = useState<any>([]);
  const [selectedBranch, setSelectedBranch] = useState<any>(null);
  const [selectedUniversity, setSelectedUniversity] = useState<any>(null);
  const [SemList, setSemList] = useState<any>([]);
  const [selectedSem, setSelectedSem] = useState<any>(null);
  const [course, setCourse] = useState<any>(null);
  const [selectedCourse, setSelectedCourse] = useState<{ label: string; value: string; }[]>([]);
  const UniversityData = useSelector((state: any) => state?.bootReducer?.utilis?.universities);
  const apiResponse = useSelector((state: any) => state?.bootReducer?.utilis?.courses);

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

  const courses: any = {};


  // useEffect(()=>{

    if(apiResponse){
      Object?.keys(apiResponse).forEach((university: any) => {
        const universityCourses = Object.keys(apiResponse[university]).map((course) => ({
          label: course,
          value: course
        }));
    
        courses[university] = universityCourses;
      });
    }

  // },[])

  const YearData: any = [
    { label: '1', value: '1' },
    { label: '2', value: '2' },
    { label: '3', value: '3' },
    { label: '4', value: '4' },
  ];

  useEffect(() => {
    if (course && selectedUniversity) {
      const branches = Object.keys(apiResponse[selectedUniversity][course])
        .map((branch) => ({
          label: branch,
          value: branch
        }));
      setBranchData(branches);
    }
    if (course && selectedUniversity && selectedBranch) {
      const semesters = apiResponse[selectedUniversity][course][selectedBranch]?.sem.map((value: any, index: any) => {
        return {
          label: (index + 1).toString(),
          value: (index + 1).toString(),
          status: value
        };
      }).filter((value: any) => value.status === true);
      setSemList(semesters);
    }
  }, [selectedUniversity, course, selectedBranch]);

  const handleYearChange = (event: any) => {
    if (event?.value === '' || event?.value === undefined || event?.value === null) {
      return;
    }
    const yearValue = event?.value;
    setSelectedYear(yearValue);

    setSelectedSem(null);
    formRef.current?.setFieldValue('sem', '');
  };

  const handleSemChange = (event: any) => {
    if (formRef.current?.values?.course === '' && formRef.current?.values?.university === '') {
      Toast.show({
        title: 'Please Select a branch first',
        duration: 4000,
        backgroundColor: '#FF0101',
      })
    }
    if (event?.value === '' || event?.value === undefined || event?.value === null) {
      return;
    }
    const semValue = event?.value;
    setSelectedSem(semValue);
    if (!selectedYear) {
      if (semValue <= 2) {
        setSelectedYear('1');
      } else if (semValue <= 4) {
        setSelectedYear('2');
      } else if (semValue <= 6) {
        setSelectedYear('3');
      } else {
        setSelectedYear('4');
      }
    }
  };

  const filteredSemList = SemList.filter((sem: any) => {
    if (selectedYear === '1') {
      return sem.value === '1' || sem.value === '2';
    } else if (selectedYear === '2') {
      return sem.value === '3' || sem.value === '4';
    } else if (selectedYear === '3') {
      return sem.value === '5' || sem.value === '6';
    } else if (selectedYear === '4') {
      return sem.value === '7' || sem.value === '8';
    } else {
      return true;
    }
  });

  const onSubmit = (email: string, password: string, initialValues: any) => {
    dispatch(AuthAction.signUp(email, password, initialValues));
  };

  return (
    <View style={{
      flexDirection: 'row',
      width: screenWidth - 50,
      flexWrap: 'wrap',
      justifyContent: 'space-between',
    }}>
      <Text style={styles.loginText}> Create Your Account.</Text>
      {/* <Text style={styles.loginText}>Create Your Account</Text> */}
      <Form
        innerRef={formRef}
        validationSchema={validationSchema}
        initialValues={initialValues}
        onSubmit={values => {
          dispatch(setCustomLoader(true));
          onSubmit(values?.email, values?.password, values);
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
          handleOptions={(item: any) => {
            if (item?.value) {
              formRef.current?.setFieldValue('course', '');
              formRef.current?.setFieldValue('branch', '');
              formRef.current?.setFieldValue('year', '');
              formRef.current?.setFieldValue('sem', '');
              setCourse(null);
              setSelectedBranch(null);
              setSelectedYear(null);
              setSelectedSem(null);
              setSelectedUniversity(item?.value)
              setSelectedCourse(courses[item?.value])
            }
          }}
        />
          <DropdownComponent
            name="course"
            data={selectedCourse}
            placeholder={'Course'}
            leftIcon="Safety"
            width={screenWidth / 2.5}
            handleOptions={(item: any) => {
              if (item?.value) {
                setCourse(item.value)
                formRef.current?.setFieldValue('branch', '');
                formRef.current?.setFieldValue('year', '');
                formRef.current?.setFieldValue('sem', '');
              }
              if (formRef.current?.values?.course === '' && formRef.current?.values?.university === '') {
                Toast.show({
                  title: 'Please Select a university first',
                  duration: 4000,
                  backgroundColor: '#FF0101',
                })
              }
            }}
          />
          <DropdownComponent
            name="branch"
            data={BranchData}
            placeholder={'Branch'}
            leftIcon="bars"
            width={screenWidth / 2.5}
            handleOptions={(item: any) => {
              if (item?.value) {
                setSelectedBranch(item?.value)
                setSemList([])
                formRef.current?.setFieldValue('year', '');
                formRef.current?.setFieldValue('sem', '');
              }
              if (formRef.current?.values?.course === '' && formRef.current?.values?.university === '') {
                Toast.show({
                  title: 'Please Select a course first',
                  duration: 4000,
                  backgroundColor: '#FF0101',
                })
              }
            }}
          />
          <DropdownComponent
            name="year"
            data={YearData}
            placeholder={'Studying year'}
            leftIcon="bars"
            width={screenWidth / 2.5}
            handleOptions={handleYearChange}
          />
          <DropdownComponent
            name="sem"
            data={filteredSemList}
            placeholder={'Semester'}
            leftIcon="ellipsis1"
            width={screenWidth / 2.5}
            handleOptions={handleSemChange}
            />
            <CustomTextInput
              leftIcon="user"
              placeholder="College Name"
              name="college"
            />
        <View style={styles.SignupButton}>
          <CustomBtn title="Sign Up" color="#6360FF" />
        </View>
        <View style={styles.LoginButton}>
          <NavBtn
            title="Log In"
            onPress={() => {
              // NavigationService.navigate(NavigationService.screens.Login);
              onPress()
            }}
            color="#FF8181"
            />
        </View>
      </Form>
    </View>
  );
};

export default SignUpScreen;
