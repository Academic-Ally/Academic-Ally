import { Avatar, Icon } from 'native-base';
import React, { useMemo } from 'react';
import { Dimensions, Image, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
// import {listBase, list, QueryList, SubjectList} from '../../../Modules/auth/firebase/firebase';
// import { FontAwesome5 } from '../../../history';
import FontAwesome5 from 'react-native-vector-icons/FontAwesome5'
import Ionicons from 'react-native-vector-icons/Ionicons'
import { useSelector } from 'react-redux';

import { Notes, OtherRes, Qp, Syllabus } from '../../../assets/images/icons';
import NavigationService from '../../../services/NavigationService';
import createStyles from './styles';

type Props = {
  selected: string;
  setSelectedCategory: (selected: string) => void;
};

const QuickAccess = ({ selected, setSelectedCategory }: Props) => {
  const theme = useSelector((state: any) => {
    return state.theme;
  });
const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);


  return (
    <View style={styles.categories}>
      <TouchableOpacity style={styles.itemContainer} onPress={() => {
        NavigationService.navigate(NavigationService.screens.AllyBot);
      }}>
        <View style={styles.syllabusIconContainer}>
          {/* <Icon as={Ionicons} name="chatbubble-sharp" size="lg" color={theme.colors.white} /> */}
          <Avatar source={{
            uri: 'https://firebasestorage.googleapis.com/v0/b/academic-ally-app.appspot.com/o/logo%2FAlly Bot™.png?alt=media&token=d3b0a0ad-8dc7-4428-84de-4b952f0998ad'
          }} size={'sm'} />
        </View>
        <Text style={styles.iconLabel}>AllyBot</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.itemContainer} onPress={() => {
         NavigationService.navigate(NavigationService.screens.SeekHub)
      }} >
        <View style={styles.notesIconContainer}>
      <Icon as={FontAwesome5} name="hands-helping" size="lg" color={theme.colors.white} />
        </View>
        <Text style={styles.iconLabel}>SeekHub</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.itemContainer} onPress={() => {
          NavigationService.navigate(NavigationService.screens.Recents)
      }} >
        <View style={styles.questionsIconContainer}>
          {/* <Qp /> */}
        <Icon as={FontAwesome5} name="history" size="lg" color={theme.colors.white} />
        </View>
        <Text style={styles.iconLabel}>Recents</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.itemContainer} onPress={() => {
        NavigationService.navigate(NavigationService.screens.Download)
      }}>
        <View style={styles.otherResourcesIconContainer}>
          {/* <OtherRes /> */}
        <Icon as={Ionicons} name="download" size="2xl" color={theme.colors.white} />
        </View>
        <Text style={styles.iconLabel}>Downloads</Text>
      </TouchableOpacity>
    </View>
  );
};

export default QuickAccess;
