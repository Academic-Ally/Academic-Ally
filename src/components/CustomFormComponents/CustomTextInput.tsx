import { useFormikContext } from 'formik';
import React, { useEffect, useRef, useState } from 'react';
import { Dimensions, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import Animated, { runOnUI, useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import Feather from 'react-native-vector-icons/Feather';
import FontAwesome from 'react-native-vector-icons/FontAwesome';
import { useSelector } from 'react-redux';

type Props = {
  leftIcon: any;
  placeholder: string;
  handlePasswordVisibility?: any;
  name: any;
  securuty?: boolean;
  // errors?: any;
  other?: any;
  width?: any;
};

const Width = Dimensions.get('screen').width;
const Height = Dimensions.get('screen').height;

export const CustomTextInput = ({
  leftIcon,
  placeholder,
  handlePasswordVisibility,
  name,
  width,
  other
}: Props) => {
  const theme = useSelector((state: any) => { return state.theme });
  const [passwordVisibility, setPasswordVisibility] = useState(true);
  const { values, errors, touched, setFieldValue, setFieldTouched } =
    useFormikContext<any>();
  
    const scaleValue = useSharedValue(2);
    const elevationValue = useSharedValue(0);
    useEffect(() => {
      const startAnimations = () => {
        'worklet';
        scaleValue.value = withSpring(0.8, {
          damping: 5,
          mass: 0.1,
        });
  
        setTimeout(() => {
          scaleValue.value = withSpring(1, {
            damping: 80,
            mass: 0.1,
          });
        }, 1000);
      };
      startAnimations();
    }, []);
  
  return (
    <View style={styles.container}>
      <Animated.View
        style={[
          styles.input,
          {
            backgroundColor: theme.colors.quaternary,
            elevation: elevationValue
          },
          width ? {
            width: width,
          } : null,
          touched[name] && errors[name]
            ? {
              borderColor: '#FF2E00',
              borderWidth: 3,
            }
            : null,
            {
              transform: [{scale: scaleValue}]
            },

        ]}>
        {name === 'college' ? (
          <FontAwesome
            size={24}
            color={touched[name] && errors[name] ? '#FF2E00' : theme.colors.primaryText}
            style={{padding: 16}}
            name={'university'}
          />
        ) : (
          <Feather
            name={leftIcon}
            size={24}
            style={{padding: 16}}
            color={touched[name] && errors[name] ? '#FF2E00' : theme.colors.primaryText}
          />
        )}
        <TextInput
          placeholder={placeholder}
          value={values[name]}
          {...other}
          onChangeText={text => {
            setFieldValue(name, text);
          }}
          onBlur={() => setFieldTouched(name)}
          placeholderTextColor={
            touched[name] && errors[name] ? '#FF2E00' : '#808080'
          }
          style={[styles.textInput, { color: theme.colors.primaryText }]}
          maxLength={50}
          secureTextEntry={
            name === 'password' || name === 'confirmPassword'
              ? passwordVisibility
              : false
          }
        />
        {touched[name] &&
          errors[name] &&
          name !== 'password' &&
          name !== 'confirmPassword' ? (
          <Feather name="alert-circle" size={Height * 0.025} 
          style={{padding: 16}} color="#FF2E00" />
        ) : null}
        {name === 'password' || name === 'confirmPassword' ? (
          <TouchableOpacity
            onPress={() => setPasswordVisibility(!passwordVisibility)}
            style={{alignSelf: 'center' }}>
            <Feather
              name={passwordVisibility ? 'eye' : 'eye-off'}
              size={24}
              style={{padding: 16}}
              color={touched[name] && errors[name] ? '#FF2E00' : '#161719'}
            />
          </TouchableOpacity>
        ) : null}
      </Animated.View>
      {touched[name] && errors[name] ? (
        <Text
          style={{
            color: theme.colors.primaryText,
            fontSize: Height * 0.015,
            // fontFamily: 'Poppins-Regular',
            paddingLeft: 20,
            fontWeight: 'bold',
          }}>
          *{errors[name] + ''}
        </Text>
      ) : null}
    </View>
  );
};

export default CustomTextInput;

const styles = StyleSheet.create({
  input: {
    width: Width - 50,
    height: Height * 0.07,
    borderRadius: 10,
    marginTop: 10,
    alignItems: 'center',
    flexDirection: 'row',
  },
  container: {
    marginTop: 1,
  },
  textInput: {
    height: Height * 0.07,
    fontSize: Height * 0.018,
    // fontFamily: 'Poppins-Regular',
    alignItems: 'flex-start',
    textAlign:'left',
    flex:1
  },
});
