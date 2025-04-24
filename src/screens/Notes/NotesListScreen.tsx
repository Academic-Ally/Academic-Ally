import { RouteProp, useIsFocused, useRoute } from '@react-navigation/native'
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Animated, StyleSheet, Text, TouchableOpacity, View, VirtualizedList, Dimensions, Platform } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';

import CustomLoader from '../../components/loaders/CustomLoader';
import NotesCard from '../../components/notes/notesCard';
import MainScreenLayout from '../../layouts/mainScreenLayout';
import RestrictedScreen from '../../layouts/restrictedScreen';
import { setCustomLoader, setResourceLoader } from "../../redux/reducers/userState";
import NavigationService from '../../services/NavigationService';
import UtilityService from '../../services/UtilityService';
import createStyles from './styles';

const { width, height } = Dimensions.get('window');

type Props = {};
type RootStackParamList = {
  NotesList: {
    userData: any;
    notesData: any;
    selected: string;
    subject: string;
  };
};

const NotesList = React.memo((props: Props) => {
  const theme = useSelector((state: any) => state.theme);
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
  const [uploadButtonVisible, setUploadButtonVisible] = useState(true);
  const components = ['subjectDetails', 'notesList']
  const fadeAnim = useRef(new Animated.Value(1)).current;
  let scroollPostion : number = 0;
  const [saveScroll, setScroll] = useState<number>(0);
  const listRef = useRef<VirtualizedList<any>>(null);
  const isFocused = useIsFocused();
  const dispatch = useDispatch()
  
  useEffect(() => { 
    const run = async () =>{
      if (listRef.current && saveScroll > 0) {
        await listRef.current.scrollToOffset({ offset: saveScroll, animated: false });
      }
    }
    if (isFocused) {
      saveScroll > 0 ? dispatch(setCustomLoader(true)) : null
      if (saveScroll > 0) {
        run().then(() => dispatch(setCustomLoader(false)));
      }
    }

    return () => {
      null
    };
  }, [isFocused]);
  
  const handleScroll = (event: any) => {
    // const offsetY = event.nativeEvent.contentOffset.y;
    // const contentHeight = event.nativeEvent.contentSize.height;
    // const windowHeight = event.nativeEvent.layoutMeasurement.height;
    scroollPostion = event.nativeEvent.contentOffset.y;

    // if (offsetY > 0) {
    //   Animated.timing(fadeAnim, {
    //     toValue: 0,
    //     duration: 500,
    //     useNativeDriver: true,
    //   }).start();
    //   setUploadButtonVisible(false);
    // } else if (offsetY + windowHeight < contentHeight) {
    //   Animated.timing(fadeAnim, {
    //     toValue: 1,
    //     duration: 500,
    //     useNativeDriver: true,
    //   }).start();
    //   setUploadButtonVisible(true);
    // } else {
    //   // User is at the end of the list
    //   setUploadButtonVisible(false);
    // }
  };


  const route = useRoute<RouteProp<RootStackParamList, 'NotesList'>>();
  const { userData } = route.params;
  const { notesData } = route.params;
  const { selected } = route.params;
  const { subject } = route.params;

  const subjectName: string = subject.length > 20 ? (UtilityService.generateAbbreviation(subject)).toUpperCase() : subject;

  const responsiveButtonSize = {
    width: width * 0.4,
    height: Platform.OS === 'ios' ? height * 0.06 : height * 0.07,
    borderRadius: width * 0.08,
    bottom: Platform.OS === 'ios' ? height * 0.05 : height * 0.04,
    right: width * 0.05,
  };

  return (
    <RestrictedScreen>
      <CustomLoader />
      <MainScreenLayout rightIconFalse={true} title={subjectName} handleScroll={()=>{}} name="SubjectList" >
        <VirtualizedList
          data={components}
          ref={listRef}
          renderItem={({ item, index }: any) => {
            switch (item) {
              case 'subjectDetails':
                return (
                  <View style={styles.notesListHeaderContainer} key={index + Math.random()}>
                    <View
                      style={{
                        width: '80%',
                        height: '100%',
                        justifyContent: 'center',
                        alignItems: 'flex-start',
                        paddingHorizontal: width * 0.02,
                      }}>
                      <Text style={[styles.notesListHeaderText, {
                        fontSize: Math.max(width * 0.04, 14),
                      }]}>
                        Results for {selected} of "{subject}"
                      </Text>
                    </View>
                    <View
                      style={{
                        width: '20%',
                        height: '100%',
                        justifyContent: 'center',
                        alignItems: 'flex-end',
                        paddingRight: width * 0.02,
                      }}>
                      <Text style={[styles.notesListValueText, {
                        fontSize: Math.max(width * 0.035, 12),
                      }]}>
                        Total {notesData.length}
                      </Text>
                    </View>
                  </View>
                );
              case 'notesList':
                return (
                  <View key={index} style={{ width: '100%' }}>
                    <VirtualizedList
                      data={notesData}
                      renderItem={({ item, index }: any) => {
                        return (
                          <View key={item.name} style={{ width: '100%', paddingHorizontal: width * 0.02 }}>
                            <NotesCard item={item} userData={userData} notesData={notesData} selected={selected} subject={subject} setScroll = {() => {
                              setScroll(scroollPostion)
                            }} />
                          </View>
                        );
                      }}
                      keyExtractor={(item: any) => item.name}
                      getItemCount={(data) => data.length}
                      getItem={(data, index) => data[index]}
                      initialNumToRender={6}
                      showsVerticalScrollIndicator={false}
                      showsHorizontalScrollIndicator={false}
                    />
                  </View>
                );

              default:
                return null;
            }
          }}
          keyExtractor={(item: any) => item}
          getItemCount={(data) => data.length}
          getItem={(data, index) => data[index]}
          initialNumToRender={2}
          showsVerticalScrollIndicator={false}
          showsHorizontalScrollIndicator={false}
          scrollEventThrottle={16}
          onScroll={handleScroll}
          ListFooterComponent={() => {
            return (
              <View style={{ height: height * 0.05 }} />
            )
          }}
        />
      </MainScreenLayout>
      {
        uploadButtonVisible && <Animated.View style={{ opacity: fadeAnim }}>
          <TouchableOpacity
            onPress={() => {
              NavigationService.navigate(NavigationService.screens.Upload, {
                userData: userData,
                notesData: notesData,
                selected: selected,
                subject: subject,
              });
            }}
            style={[styles.btn, responsiveButtonSize]}>
            <Text
              style={[styles.uploadBtnText, { fontSize: Math.max(width * 0.04, 14) }]}>
              Upload
            </Text>
          </TouchableOpacity>
        </Animated.View>
      }
    </RestrictedScreen>
  );
});

export default NotesList;

const styles = StyleSheet.create({});
