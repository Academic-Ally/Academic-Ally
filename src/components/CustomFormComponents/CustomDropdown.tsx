import { useFormikContext } from 'formik';
import React, { useEffect, useState } from 'react';
import { Dimensions, StyleSheet, Text, TextInput, TextProps, TouchableOpacity, View } from 'react-native';
import { Dropdown } from 'react-native-element-dropdown';
import Animated, { runOnUI, useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Feather from 'react-native-vector-icons/Feather';
import FontAwesome from 'react-native-vector-icons/FontAwesome';
import { useSelector } from 'react-redux';

type Props = {
  placeholder: string;
  name: string;
  data?: any;
  width?: any;
  handleOptions?: any;
  searchbar?: boolean;
  color: string;
  height?: any;
  mode?: any;
};

const { width, height } = Dimensions.get('window');
export const CustomDropdown = ({
  placeholder,
  name,
  data,
  width,
  handleOptions,
  searchbar,
  color,
  height,
  mode
}: Props) => {
  
  const theme = useSelector((state: any) => {
    return state.theme;
  });
  const [value, setValue] = useState(null);
  const [isFocus, setIsFocus] = useState(false);

  const dropdownHeight = (length: number) => {
    const h = theme.sizes.height * 0.053
    switch (length) {
      case 1:
        return h * (length + 1);
      case 2:
        return h * (length + 1);
      case 3:
        return h * (length + 1);
      case 4:
        return h * (length + 1);
      case 5:
        return h * (length + 1);
      default:
        return h * 6;
    }
  };

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
      <Animated.View style={{
        transform: [{scale: scaleValue}],
        elevation: elevationValue
      }}>
        <Dropdown
          style={[
            styles.input,
            { width: width, backgroundColor: theme.colors.quaternary, borderColor: color, height: height, borderRadius: 15, },
          ]}
          placeholderStyle={[
            styles.placeholderStyle,
            { color: color },
          ]}
          selectedTextStyle={[
            styles.selectedTextStyle,
            {
              width: 120,
              color: color,
              fontWeight:'600',
              flexWrap: 'nowrap'
            },
          ]}
          inputSearchStyle={styles.inputSearchStyle}
          iconStyle={styles.iconStyle}
          data={data}
          search={searchbar ? true : false}
          searchQuery={(res, res2) => {
            return (
              res.toLowerCase().includes(res2.toLowerCase()) ||
              res2.toLowerCase().includes(res.toLowerCase())
            );
          }}
          maxHeight={300}
          mode={mode ? mode : 'default' }
          labelField="label"
          valueField="value"
          placeholder={value ? value : placeholder}
          searchPlaceholder="Search..."
          value={value}
          showsVerticalScrollIndicator={false}
          onFocus={() => setIsFocus(true)}
          onBlur={() => {
            setIsFocus(false)
          }}
          onConfirmSelectItem={item => {
            handleOptions(item)
          }}
          dropdownPosition="auto"
          containerStyle={{
            borderRadius: 10,
            elevation: 3,
            height: dropdownHeight(data.length),
          }}
          itemContainerStyle={{
            borderBottomWidth: 1,
            borderBottomColor: '#e5e5e5',
            borderRadius: 10,
            marginHorizontal:5
          }}
          itemTextStyle={{
            fontSize: theme.sizes.height * 0.0155,
            color: theme.colors.terinaryText,
            fontWeight: '600'
          }}
          onChange={(item: any) => {
            handleOptions(item?.value);
            setValue(item?.value);
          }}
          renderRightIcon={() => (
            <Feather
              style={styles.icon}
              color={color}
              name={isFocus ? 'chevron-up' : 'chevron-down'}
              size={theme.sizes.height * 0.028}
            />
          )}
        />
      </Animated.View>
    </View>
  );
};

export default CustomDropdown;

const styles = StyleSheet.create({
  input: {
    backgroundColor: '#161719',
    height: height * 0.05,
    borderRadius: 5,
    paddingLeft: 20,
    alignItems: 'center',
    borderWidth:1,
  },
  textInput: {
    width: 250,
    fontSize: height * 0.0235,
    color: '#161719',
    // fontFamily: 'Poppins-Regular',
  },
  container: {
    marginTop: 1,
    color: '#161719',
  },
  dropdown: {
    borderColor: 'gray',
    borderWidth: 0.5,
    borderRadius: 10,
    paddingHorizontal: 0,
    fontSize: height * 0.0105,
    color: '#161719',
  },
  icon: {
    marginRight: 12,
  },
  label: {
    position: 'absolute',
    backgroundColor: '#6360FF',
    left: 22,
    top: 4,
    zIndex: 999,
    paddingHorizontal: 8,
    fontSize: height * 0.0185,
    borderRadius: 5,
    color: '#F1F1FA',
  },
  placeholderStyle: {
    fontSize: width * 0.035,
    fontWeight: '600'
  },
  selectedTextStyle: {
    fontSize: height * 0.014,
    flexWrap: 'nowrap',
  },
  iconStyle: {
    width: 25,
    height: 25,
    marginRight: 12,
  },
  inputSearchStyle: {
    height: 50,
    fontSize: height * 0.0205,
    color: '#161719',
    // fontFamily: 'Poppins-Regular',
    borderRadius: 10,
  },
});
