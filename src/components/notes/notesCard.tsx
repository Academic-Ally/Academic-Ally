import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Actionsheet, Box, Card, Center, Checkbox, Icon, Modal, Stack, Text, Toast, useDisclose } from 'native-base';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Animated, Linking, Share, StyleSheet, TouchableOpacity, View } from 'react-native';
import SwipeableRating from 'react-native-swipeable-rating';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Entypo from 'react-native-vector-icons/Entypo';
import FontAwesome from 'react-native-vector-icons/FontAwesome';
import Ionicons from 'react-native-vector-icons/Ionicons';
import { useDispatch, useSelector } from 'react-redux';

import { ShareIcon } from '../../assets/images/icons';
import { ReportIconBlack, ReportIconWhite } from '../../assets/images/images';
import { userAddBookMarks, userRemoveBookMarks } from '../../redux/reducers/userBookmarkManagement';
import PdfViewerAction from '../../screens/PdfViewer/pdfViewerAction';
import { ratedResourcesList, submitRating, submitReport, ViewCount } from '../../services/fetch';
import NavigationService from '../../services/NavigationService';
import createStyles from './styles';

type Props = {
  item: any;
  userData: any;
  notesData: any;
  selected: string;
  subject: string;
  setScroll: any;
};
type RootStackParamList = {
  NotesList: {
    userData: {
      Course: string;
      Branch: string;
      Sem: string;
    };
    notesData: any;
    selected: string;
    subject: string;
  };
};
type MyStackParamList = {
  NotesList: {
    userData: {
      Course: string;
      Branch: string;
      Sem: string;
    };
    notesData: string;
    selected: string;
    subject: string;
  };
  PdfViewer: {
    userData: {
      Course: string;
      Branch: string;
      Sem: string;
    };
    notesData: string;
    selected: string;
    subject: string;
  };
  UploadScreen: {
    userData: {
      Course: string;
      Branch: string;
      Sem: string;
    };
    notesData: string;
    selected: string;
    subject: string;
  };
};

type pdfViewer = StackNavigationProp<MyStackParamList, 'PdfViewer'>;

function remove(filename: string) {
  if (filename.endsWith(".pdf")) {
    filename = filename.slice(0, -4);
    if (filename.length > 15) {
      return filename.substring(0, 20);
    }
    return filename;
  }
}

function KbsToMB(bits: any) {
  const megabytes = bits / 1024;
  return megabytes.toFixed(2) + " MB";
}

const NotesCard = React.memo(({ item, userData, notesData, selected, subject, setScroll }: Props) => {
  const { isOpen, onOpen, onClose } = useDisclose();
  const theme = useSelector((state: any) => state.theme);
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
  const navigation = useNavigation<pdfViewer>();
  const [bookmarked, setBookmarked] = useState<boolean>(false);
  const dispatch = useDispatch();
  const fadeAnim = useRef(new Animated.Value(1)).current;
  const [saved, setSaved] = useState(false);
  const [modalVisible, setModalVisible] = React.useState(false);
  const [ratingCount, setRatingCount] = useState(0);
  const [checked1, setChecked1] = useState(false);
  const [checked2, setChecked2] = useState(false);
  const [checked3, setChecked3] = useState(false);
  const userFirestoreData = useSelector((state: any) => state.usersData);
  const [ratedList, setRatedList] = useState<any>([]);
  const [submitted, setSubmitted] = useState(false);
  const dynamicLink = useSelector((state: any) => state?.bootReducer?.utilis?.dynamicLink);
  const {uid}: any = useSelector((state: any) => state.bootReducer.userInfo);

  const userBookmarks = useSelector(
    (state: any) => state.userBookmarkManagement,
  ).userBookMarks;

  useEffect(() => {
    async function getRatedList() {
      const ratedList: any = await ratedResourcesList();
      setRatedList(ratedList);
    }
    getRatedList();
  }, []);

  const BookmarkStatus = (item: any) => {
    if (userBookmarks?.some((bookmark: any) => bookmark.did === item)) {
      return true;
    } else {
      return false;
    }
  };
  const RatedStatus = (item: any) => {
    if (ratedList?.some((rate: any) => rate === item)) {
      return true;
    } else {
      return false;
    }
  };

  function formatViewCount(count: any) {
    if (count >= 1000) {
      count = Math.floor(count / 1000) + "K";
    }
    return count;
  }

  function submitRatingCount() {
    setModalVisible(false);
    submitRating({
      university: userData.University,
      branch: userData.Branch,
      course: userData.Course,
      sem: userData.Sem,
      type: selected.charAt(0).toUpperCase() + selected.slice(1),
      subjectName: subject,
      id: item.id,
      rating: item.rating,
      ...item
    },
      ratingCount
    )
  }

  async function mail() {
    Linking.openURL(`mailto:academicly.app@gmail.com?body=Report for notes Id : ${item.id}, ${userData.Course} ${userData.Branch}, Semester ${item.sem} ${selected.charAt(0).toUpperCase() + selected.slice(1)} of ${subject}  `)
  }

  const handleSharePdf = async () => {
    try {
      await PdfViewerAction.sharePdf({ ...item, subject: item?.subject }, dynamicLink).then((link: any) => {
        Share.share({
          title: `${subject}`,
          message: `If you're studying ${subject}, you might find these ${item.category} on Academic Ally helpfull. I did! Check them out:${link}`
        });
      }).catch((error: any) => {
        console.log(error);
        Toast.show({
          title: 'Something went wrong',
          placement: 'bottom',
          duration: 3000,
        })
      })
    } catch (error) {
      console.log(error);
      Toast.show({
        title: 'Something went wrong',
        placement: 'bottom',
        duration: 3000,
      })
    }
  };


  const handleOnPress = () => {
    ViewCount({
      university: userFirestoreData.usersData.university,
      branch: userData.Branch || item.branch,
      course: userData.Course || userData.course,
      sem: userData.Sem || item.sem,
      type: selected.charAt(0).toUpperCase() + selected.slice(1),
      subjectName: subject,
      id: item.id,
    })
    setScroll()
    NavigationService.navigate(NavigationService.screens.PdfViewer, {
      userData: {
        Course: userData.Course,
        Branch: userData.Branch,
        Sem: userData.Sem,
      },
      notesData: item,
      selected: selected,
      subject: subject,
    });
  }

  return (
    <View style={styles.notesContainer}>
      <View style={styles.reccomendationStyle}>
        <TouchableOpacity
          style={styles.subjectContainer}
          onPress={handleOnPress}>
          <View style={styles.containerBox}>
            <View style={styles.containerText}>

            </View>
          </View>
          <View
            style={{
              width: '65%',
              height: '90%',
              justifyContent: 'space-evenly',
              alignItems: 'flex-start',
              paddingTop: theme.sizes.height * 0.01,
              paddingLeft: theme.sizes.width * 0.02,
            }}>
            <Text style={styles.subjectName}>
              {remove(item.name)}
            </Text>
            <Text
              style={{
                fontSize: theme.sizes.subtitle,
                color: theme.colors.primaryText,
                fontWeight: '400',
              }}>
              {selected.charAt(0).toUpperCase() + selected.slice(1)}
            </Text>
            <Text
              style={{
                fontSize: theme.sizes.subtitle,
                color: item.units === "" ? theme.colors.textSecondary : theme.colors.primaryText,
                fontWeight: '400',
              }}>
              {item.units === "" ? "Units: Unknown" : item.units + " Units"}
            </Text>
            <View
              style={{
                width: '100%',
                flexDirection: 'row',
                alignItems: 'center',
                paddingRight: theme.sizes.width * 0.02,
                maxWidth: '100%',
              }}>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginRight: theme.sizes.width * 0.02,
                }}>
                <Ionicons name="md-eye-outline" size={theme.sizes.iconMini} color={theme.colors.primaryText} style={{
                  paddingTop: theme.sizes.height * 0.002,
                }} />
                <Text
                  style={{
                    fontSize: theme.sizes.subtitle,
                    color: theme.colors.primaryText,
                    fontWeight: '600',
                    paddingLeft: theme.sizes.width * 0.005,
                  }}>{
                    item?.views ? formatViewCount(item.views) : 0
                  }
                </Text>
              </View>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  paddingHorizontal: theme.sizes.width * 0.001,
                }}>
                <AntDesign name="star" size={theme.sizes.iconMini} color={theme.colors.yellowWarning} />
                <Text
                  style={{
                    fontSize: 14,
                    color: item.rating < 1 ? theme.colors.textSecondary : theme.colors.primaryText,
                    fontWeight: '600',
                    paddingLeft: theme.sizes.width * 0.01,
                  }}>
                  {item.rating < 1 ? "Unrated" : item.rating}
                </Text>
              </View>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  paddingHorizontal: theme.sizes.width * 0.01,
                }}>
                <Entypo name="dot-single" size={20} color="#91919F" style={{
                  paddingTop: 2,
                }} />
                <Text
                  style={{
                    fontSize: 14,
                    color: theme.colors.textSecondary,
                    fontWeight: '400',
                    paddingLeft: 0,
                    alignItems: 'center',
                  }}>
                  {KbsToMB(item.size)}
                </Text>
              </View>
            </View>
          </View>
          <TouchableOpacity
            onPress={() => {
              setBookmarked(!bookmarked)
              setSaved(!saved);
              const status = BookmarkStatus(item.did);
              PdfViewerAction.manageBookmarks(item, status, uid);
              !status
                ? dispatch(
                  userAddBookMarks({
                    ...item
                  }),
                )
                : dispatch(
                  userRemoveBookMarks({ ...item }),
                );
            }}>
            <FontAwesome
              name={
                BookmarkStatus(item.did) || bookmarked
                  ? 'bookmark'
                  : 'bookmark-o'
              }
              size={theme.sizes.height * 0.035}
              color={theme.colors.SearchCategory}
            />
          </TouchableOpacity>
        </TouchableOpacity>
      </View>
      <View style={styles.cardOptions}>
        <TouchableOpacity style={styles.cardOptionContainer} onPress={() => {
          {
            RatedStatus(item.did) ? (
              Toast.show({
                title: "You can only rate once",
                duration: 2000,
              })
            ) : setModalVisible(true)
          }
        }} >
          <Text style={styles.cardOptionText}>Rate</Text>
          <AntDesign name={RatedStatus(item.did) ? 'star' : 'staro'} size={theme.sizes.iconSmall} color={RatedStatus(item.did) ? '#FFC960' : "#F1F1FA"} />
        </TouchableOpacity>
        <TouchableOpacity style={styles.cardOptionContainer} onPress={onOpen} >
          <Text style={styles.cardOptionText}>Report</Text>
          <ReportIconWhite />
        </TouchableOpacity>
        <TouchableOpacity style={styles.cardOptionContainer} onPress={handleSharePdf} >
          <Text style={styles.cardOptionText}>Share</Text>
          <ShareIcon />
        </TouchableOpacity>
      </View>
      <Modal isOpen={modalVisible} onClose={() => setModalVisible(false)} size={'xl'}>
        <Modal.Content >
          <Box margin={2} >
            <Text fontSize={'14px'} fontWeight={'700'} marginTop={3} textAlign="center" >
              How likely are you to recommend this resources to your friends/colleagues?
            </Text>
            <Stack direction="row" space={2} marginY={10} alignItems="center" justifyContent="center" >
              <SwipeableRating
                rating={ratingCount}
                size={theme.sizes.height * 0.05}
                gap={theme.sizes.width * 0.02}
                onPress={(rating: any) => {
                  setRatingCount(rating)
                }}
                swipeable={true}
                color={theme.colors.yellowWarning}
                emptyColor={theme.colors.terinaryText}
                maxRating={5}
                allowHalves={true}
                style={{
                  alignSelf: 'center',
                  justifyContent: 'center',
                  alignItems: 'center',
                }}
              />
              {/* {
              [1,2,3,4,5].map((item, index)=>{
                return(
                 <AntDesign onMagicTap={()=>{
                  setRatingCount(item)
                 }} name={ratingCount > item || ratingCount === item ? "star" : "staro" } size={50} key={index} onPress={()=>{
                  setRatingCount(item)
                 }} color="#FFC960" />
                )  
              })    
             }  */}
            </Stack>
            <Stack direction="row" space={2} marginY={5} alignItems="center" justifyContent="space-evenly" >
              <TouchableOpacity onPress={() => {
                setModalVisible(false);
              }} >
                <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.terinaryText} >
                  Cancel
                </Text>
              </TouchableOpacity>
              <TouchableOpacity style={{
                backgroundColor: theme.colors.primary,
                borderRadius: 10,
                paddingHorizontal: theme.sizes.width * 0.06,
                paddingVertical: 10,
              }} onPress={() => {
                setModalVisible(false);
              }} >
                <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={"#F1F1FA"} onPress={() => {
                  submitRatingCount();
                }} >
                  Confirm
                </Text>
              </TouchableOpacity>

            </Stack>
          </Box>
        </Modal.Content>
      </Modal>
      <Center>
        <Actionsheet isOpen={isOpen} onClose={onClose} borderRadius={0}>
          {
            !submitted ? (
              <Card style={{
                backgroundColor: "#F1F1FA",
                width: "100%",
                alignItems: "center",
                justifyContent: "center",
                borderTopLeftRadius: 20,
                borderTopRightRadius: 20,
              }}>
                <ReportIconBlack />
                <Box w="100%" h={theme.sizes.height * 0.1} px={4} my={4} justifyContent="center" alignItems={"center"} >
                  <Text fontSize={theme.sizes.subtitle} color={theme.colors.primaryText} fontWeight={700} >
                    Why are you reporting this resource?
                  </Text>
                  <Text fontSize={theme.sizes.textSmall} color="#91919F" textAlign={"center"} fontWeight={700} >
                    Your report is anonymous, except if you are reporting an intellectual property infringement
                  </Text>
                </Box>
                <Box w="100%" px={0} my={4} justifyContent="center" alignItems={"center"} >
                  <Actionsheet.Item style={{
                    borderBottomWidth: 0.9,
                    borderBottomColor: theme.colors.textSecondary,
                    // backgroundColor: theme.colors.quaternary,
                  }} onPress={() => {
                    setChecked1(!checked1);
                  }}>
                    <Checkbox _android={{
                      _checked: {
                        bg: theme.colors.primary,
                        borderColor: theme.colors.primary,
                        color: theme.colors.quaternary,
                      },
                      _unchecked: {
                        bg: theme.colors.quaternary,
                        borderColor: theme.colors.primary,
                        color: theme.colors.primary,
                      },
                    }} onChange={(value) => {
                      setChecked1(!checked1);
                    }} value={"Checked 1"} colorScheme="green" >
                      <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={'95%'} >
                        Copyrights: The notes or this resource file contain copyrighted material
                      </Text>
                    </Checkbox>
                  </Actionsheet.Item>
                  <Actionsheet.Item style={{
                    borderBottomWidth: 0.9,
                    borderBottomColor: "#91919F",
                    backgroundColor: "#F1F1FA",
                  }} onPress={() => {
                    setChecked2(!checked2);
                  }}>
                    <Checkbox _android={{
                      _checked: {
                        bg: theme.colors.primary,
                        borderColor: theme.colors.primary,
                        color: theme.colors.quaternary,
                      },
                      _unchecked: {
                        bg: theme.colors.quaternary,
                        borderColor: theme.colors.primary,
                        color: theme.colors.primary,
                      },
                    }} onChange={(value) => {
                      setChecked2(!checked2);
                    }} value={"Checked 1"} colorScheme="green" >
                      <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={'95%'} >
                        Misleading resource: The uploaded source contains inaccurate and false information.
                      </Text>
                    </Checkbox>
                  </Actionsheet.Item>
                  <Actionsheet.Item style={{
                    borderBottomWidth: 0.9,
                    borderBottomColor: "#91919F",
                    backgroundColor: "#F1F1FA",
                  }} onPress={() => {
                    setChecked3(!checked3);
                  }}>
                    <Checkbox
                      _android={{
                        _checked: {
                          bg: theme.colors.primary,
                          borderColor: theme.colors.primary,
                          color: theme.colors.quaternary,
                        },
                        _unchecked: {
                          bg: theme.colors.quaternary,
                          borderColor: theme.colors.primary,
                          color: theme.colors.primary,
                        },
                      }}
                      onChange={(value) => {
                        setChecked3(!checked3);
                      }} value={"Checked 1"} colorScheme="green" >
                      <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={"92%"}>
                        Spam: This file contains content other than notes and resources.
                      </Text>
                    </Checkbox>
                  </Actionsheet.Item>
                </Box>
                <Box w="100%" h={theme.sizes.height * 0.08} px={4} my={0} justifyContent="center" alignItems={"center"} >
                  <Text fontSize={theme.sizes.subtitle} mt={-6} color={theme.colors.primary} fontWeight={700} onPress={() => {
                    mail()
                  }} >
                    Reason not listed here? Write to Us
                  </Text>
                </Box>
                <Stack direction="row" space={2} marginY={0} paddingX={5} alignItems="center" justifyContent="space-evenly" width={"100%"} >
                  <TouchableOpacity onPress={onClose} >
                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.terinaryText} >
                      Cancel
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={{
                    backgroundColor: theme.colors.primary,
                    borderRadius: 10,
                    paddingHorizontal: theme.sizes.width * 0.05,
                    paddingVertical: 10,
                  }} onPress={() => {
                    submitReport(userFirestoreData?.usersData, {
                      checked1,
                      checked2,
                      checked3,
                    }, item);
                    setSubmitted(true);
                  }} >
                    <Text fontSize={theme.sizes.title} fontWeight={'700'} textAlign="center" color={theme.colors.white} >
                      Confirm
                    </Text>
                  </TouchableOpacity>
                </Stack>
                <Ionicons name="close-circle" size={theme.sizes.height * 0.05} onPress={onClose} color="#BCC4CC" style={{
                  position: "absolute",
                  top: 15,
                  right: 15,
                }} />
              </Card>
            ) : (
              <Card style={{
                height: 400,
                backgroundColor: theme.colors.quaternary,
                width: "100%",
                alignItems: "center",
                justifyContent: "center",
                borderTopLeftRadius: 20,
                borderTopRightRadius: 20,
              }} >
                <AntDesign name="checkcircle" size={50} color={theme.colors.primary} />
                <Box w="100%" h={theme.sizes.height * 0.1} px={4} my={4} justifyContent="center" alignItems={"center"} marginBottom={20} >
                  <Text fontSize={theme.sizes.title} color={theme.colors.primaryText} fontWeight={700} >
                    Thank you for letting us know!
                  </Text>
                  <Text fontSize={theme.sizes.subtitle} padding={theme.sizes.height * 0.01} paddingTop={theme.sizes.height * 0.01} color={theme.colors.textSecondary} textAlign={"center"} fontWeight={700} >
                    We will review your report and take appropriate action.
                  </Text>
                </Box>
                <TouchableOpacity style={{
                  backgroundColor: theme.colors.primary,
                  borderRadius: 10,
                  width: "100%",
                  paddingVertical: theme.sizes.height * 0.02,
                  marginVertical: theme.sizes.height * 0.02,
                  position: "absolute",
                  height: theme.sizes.height * 0.07,
                  bottom: 0,
                  justifyContent: "center",
                  alignItems: "center",
                }} onPress={() => {
                  onClose();
                }} >
                  <Text fontSize={theme.sizes.title} fontWeight={'700'} textAlign="center" color={theme.colors.quaternary} >
                    Close
                  </Text>
                </TouchableOpacity>
                <Ionicons name="close-circle" size={30} onPress={onClose} color="#BCC4CC" style={{
                  position: "absolute",
                  top: 15,
                  right: 15,
                }} />
              </Card>
            )
          }
        </Actionsheet>
      </Center>
    </View>
  );
});

export default NotesCard;

const styles = StyleSheet.create({});
