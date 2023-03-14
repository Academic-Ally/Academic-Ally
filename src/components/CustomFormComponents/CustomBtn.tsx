import {StyleSheet, Text, TouchableOpacity, Dimensions} from 'react-native';
import React from 'react';

import {useFormikContext} from 'formik';

type Props = {
  title: string;
  onPress?: () => any;
  color?: string;
};

const {width, height} = Dimensions.get('window');

export const CustomBtn = ({title, onPress, color}: Props) => {
  const {handleSubmit} = useFormikContext();
  return (
    <TouchableOpacity
      style={[styles.button, {backgroundColor: color}]}
      onPress={handleSubmit}
      onMagicTap={onPress}>
      <Text style={styles.buttonText}>{title}</Text>
    </TouchableOpacity>
  );
};

export const NavBtn = ({title, onPress, color}: Props) => {
  return (
    <TouchableOpacity
      style={[styles.button, {backgroundColor: color}]}
      onPress={onPress}
      onMagicTap={onPress}>
      <Text style={styles.buttonText}>{title}</Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    width: width - 50,
    height: height * 0.07,
    borderRadius: 10,
    elevation: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    fontWeight: '900',
    fontSize: 16,
    color: '#fff',
    lineHeight: 37,
  },
});
