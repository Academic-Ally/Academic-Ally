import LottieView from 'lottie-react-native';
import { Box, Card, Divider, FlatList, Icon, IconButton, Popover, Progress, Text, Toast, useDisclose, View } from 'native-base'
import React, { useEffect, useMemo, useState } from 'react'
import { ActivityIndicator, Dimensions, Share, StyleSheet, TextInput, TouchableOpacity, VirtualizedList } from 'react-native'
import RNFS from 'react-native-fs'
import Pdf from 'react-native-pdf'
import AntDesign from 'react-native-vector-icons/AntDesign'
import Feather from 'react-native-vector-icons/Feather'
import { useDispatch, useSelector } from 'react-redux'

import MainScreenLayout from '../../layouts/mainScreenLayout'
import { userRemoveFromRecents } from '../../redux/reducers/usersRecentPdfsManager';
import DownloadingList from '../../sections/Downloads/DownloadingList';
import ReportActionSheet from '../../sections/NotesCard/Report/ReportActionSheet'
import NavigationService from '../../services/NavigationService'
import UtilityService from '../../services/UtilityService'
import PdfViewerAction from '../PdfViewer/pdfViewerAction'

const { width, height } = Dimensions.get('screen');

const RecentScreen = () => {
  const dynamicLink = useSelector((state: any) => state?.bootReducer?.utilis?.dynamicLink);
  const recentsList = useSelector((state: any) => state.userRecentPdfs.RecentViews)||[];
  const dispatch = useDispatch()
  const [files, setFiles] = useState([])
  const [data, setData] = useState(recentsList)
  const [searchTerm, setSearchTerm] = useState('');
  const [sortedArray, setSortedArray] = useState<any>([])
  // console.log(recentsList)
  const groupByDate = (array: any) => {
    if(array?.length > 0){
      const groupedArray: any = {};
      for (const item of array) {
        const date = new Date(item?.viewedTime);
        const dateString = date.toDateString();
        if (groupedArray[dateString]) {
          groupedArray[dateString].push(item);
        } else {
          groupedArray[dateString] = [item];
        } 
      }
      return Object.values(groupedArray);
    }
  };

  

  const onSearch = () => {
    if (searchTerm === '') {    
      groupByDate(data)
    } else {
        const array = data;
      const filteredData: any = array.map((group: any) => {
        const filteredItems = group?.filter((item: any) => {
          return (
            item.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.branch.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.sem.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.category.toLowerCase().includes(searchTerm.toLowerCase())
          );
        });
        return filteredItems.length > 0 ? filteredItems : null;
      });
      setSortedArray(filteredData.filter((group: any) => group !== null));
    }
  }

  useEffect(() => {
    data?.length > 0 ? onSearch() : null
  }, [searchTerm, data]);


  const theme = useSelector((state: any) => state.theme);
  const size = theme?.sizes;
  const colors = theme?.colors;

  const getDownloadedList = async () => {
    setFiles(recentsList)
  }

  useEffect(() => {
    getDownloadedList()
  }, [])

  useEffect(() => {
    if(recentsList?.length > 0){
        const updatedArray = groupByDate(recentsList); 
        setSortedArray(updatedArray);
          setData(updatedArray)
    }
  }, [files, recentsList])

  const PdfPreviewComponent = React.memo(({ notesData, index }: any) => {
    const { isOpen, onOpen, onClose } = useDisclose();
    const dispatch = useDispatch()
    const data = notesData;
    const [visible, setVisible] = useState(true);
    const [url, setUrl] = useState("")
    const { filePath } = notesData;
    const initialFocusRef = React.useRef(null);
    const checkFileExist = async () => {
        const exists = await RNFS.exists(filePath);
        if(exists){
            setUrl(filePath)
        }
        else {
            return filePath
        }
    }
    useEffect(()=>{
        checkFileExist()
    },[])
    const source: object = {
      uri: url,
      cache: true,
      expiration: 60 * 60 * 30 * 24 * 1000,
    };

    return (
      <>
        <Card width={size.width * 0.85} height={size.height * 0.25} bgColor={colors.primary} borderRadius={20} marginY={3} p={0} display={visible ? 'flex' : 'none'}>
          <TouchableOpacity
            style={{
              width: '100%',
              height: '70%',
              borderRadius: 20,
            }}
            onPress={() => {
              NavigationService.navigate(NavigationService.screens.PdfViewer, {
                userData: {},
                notesData: notesData,
                selected: notesData?.category,
                subject: notesData?.subject,
              });
            }}
          >
            <Box width={'100%'} height={'100%'} justifyContent={'center'} alignItems={'center'} backgroundColor={colors.white} borderTopRadius={20}>
              <Pdf
                trustAllCerts={false}
                source={source}
                scale={3.5}
                minScale={0.5}
                maxScale={5.0}
                spacing={10}
                singlePage={true}
                page={1}
                style={{
                  width: '100%',
                  height: '100%',
                  backgroundColor: colors.terinaryText,
                }}
              />
              <View
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  backgroundColor: 'rgba(0, 0, 0, 0.1)',
                  alignItems: 'center'
                }}
              />
            </Box>
          </TouchableOpacity>

          <Box width={'100%'} height={'30%'} justifyContent={'flex-start'} borderTopRadius={20.0} flexDirection={'row'} p={4}>
            <Box width={'90%'} height={'100%'} flexDirection={'column'}>
              <Box width={'100%'} flexDirection={'row'} pb={1}>
                <Text width={'50%'} color={colors.white} fontSize={size.textMidTiny} fontWeight={'bold'}>
                  {(notesData?.subject)?.slice(0, 20)}
                </Text>
                <Text width={'35%'} color={colors.white} fontSize={size.textMidTiny} fontWeight={'bold'}>
                  Branch: {notesData?.branch}
                </Text>
                <Text width={'15%'} color={colors.white} fontSize={size.textMidTiny} fontWeight={'bold'}>
                  Sem: {notesData?.sem}
                </Text>
              </Box>
              <Box width={'100%'} flexDirection={'row'}>
                <Text width={'50%'} color={colors.white} fontSize={size.textMidTiny}>
                  {(notesData?.name)?.slice(0, 20)}
                </Text>
                <Text width={'40%'} color={colors.white} fontSize={size.textMidTiny}>
                  {notesData?.category}
                </Text>
              </Box>
            </Box>
            <Box width={'10%'} height={'100%'} justifyContent={'center'} alignItems={'flex-end'}>
              <Box w="100%" alignItems="center">
                <Popover
                  initialFocusRef={initialFocusRef}
                  placement={'bottom right'}
                  trigger={(triggerProps) => {
                    return (
                      <IconButton
                        borderRadius={'full'}
                        _hover={{
                          bg: 'gray',
                        }}
                        ref={initialFocusRef}
                        variant="ghost"
                        icon={<Icon as={Feather} name="more-vertical" size="xl" color="white" />}
                        {...triggerProps}
                      />
                    );
                  }}
                >
                  <Popover.Content width={size.width * 0.32} p={0}>
                    <Popover.Body p={0} backgroundColor={colors.popOver}>
                      <TouchableOpacity
                        style={{
                          width: '100%',
                          alignItems: 'center',
                          justifyContent: 'space-around',
                          paddingVertical: 8,
                          flexDirection: 'row',
                        }}
                        onPress={async () => {
                          try {
                            dispatch(userRemoveFromRecents(notesData));
                            const exists = await RNFS.exists(filePath);
                            if (exists) {
                              await RNFS.unlink(filePath);
                            } 
                          } catch (error) {
                            Toast.show({
                              title: 'Something went wrong',
                              placement: 'bottom',
                              duration: 3000,
                            });
                          }
                        }}
                      >
                        <Text color={colors.primaryText} fontSize={size.textMedium} fontWeight={'bold'}>
                          Delete
                        </Text>
                        <Icon as={<AntDesign name="delete" />} color={colors.primaryText} size={22} />
                      </TouchableOpacity>
                      <Divider width={'100%'} />
                      <TouchableOpacity
                        style={{
                          width: '100%',
                          alignItems: 'center',
                          justifyContent: 'space-around',
                          paddingVertical: 6,
                          flexDirection: 'row',
                        }}
                        onPress={async () => {
                          try {
                            await PdfViewerAction.sharePdf(notesData, dynamicLink).then((link: any) => {
                              Share.share({
                                title: `${notesData?.subject}`,
                                message: `If you're studying ${notesData?.subject}, you might find these ${notesData.category} on Academic Ally helpful. I did! Check them out:${link}`,
                              });
                            }).catch((error: any) => {
                              Toast.show({
                                title: 'Something went wrong',
                                placement: 'bottom',
                                duration: 3000,
                              });
                            });
                          } catch (error) {
                            Toast.show({
                              title: 'Something went wrong',
                              placement: 'bottom',
                              duration: 3000,
                            });
                          }
                        }}
                      >
                        <Text color={colors.primaryText} fontSize={size.textMedium} fontWeight={'bold'}>
                          Share
                        </Text>
                        <Icon as={<colors.shareIcon />} color={colors.primaryText} size="md" />
                      </TouchableOpacity>
                      <Divider width={'100%'} />
                      <TouchableOpacity
                        style={{
                          width: '100%',
                          alignItems: 'center',
                          justifyContent: 'space-around',
                          paddingVertical: 6,
                          flexDirection: 'row',
                        }}
                        onPress={() => {
                          onOpen();
                        }}
                      >
                        <Text color={colors.primaryText} fontSize={size.textMedium} fontWeight={'bold'}>
                          Report
                        </Text>
                        <Icon as={<colors.reportIcon />} color={colors.primaryText} size="md" />
                      </TouchableOpacity>
                    </Popover.Body>
                  </Popover.Content>
                </Popover>
              </Box>
            </Box>
          </Box>
          <ReportActionSheet isOpen={isOpen} onClose={onClose} notesData={data} />
        </Card>
      </>
    );
  });

  const ItemGroupComponent = React.memo(({ itemGroup }: any) => (
    <>
      <Text style={{
        fontSize: theme.sizes.title,
        fontWeight: 'bold',
        color: theme.colors.primaryText,
        marginLeft: 0,
        marginTop: 20,
        marginBottom: 10,
        width: '95%',

      }}>
        {UtilityService.formatDate(itemGroup[0]?.viewedTime, 'MMM dd, yyyy')}
      </Text>
      <FlatList
        data={itemGroup}
        keyExtractor={(item, index) => index.toString()}
        renderItem={({ item }: any) => (
          <PdfPreviewComponent notesData={item} />
        )}
      />
    </>
  ));

  const ListEmptyComponent = React.memo(() => (
    <View
      style={{
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <LottieView
        style={{
          height: theme.sizes.lottieIconHeight,
          alignSelf: 'center',
        }}
        source={require('../../assets/lottie/NoBookMarks.json')}
        autoPlay
        loop
      />
      <Text
        style={{
          fontSize: theme.sizes.title,
          color: theme.colors.primaryText,
          fontWeight: 'bold',
        }}
      >
        No Recent pdf's
      </Text>
    </View>
  ));

  const ListFooterComponent = React.memo(() => (
    <View style={{ marginBottom: theme.sizes.height * 0.1 }} />
  ));

  return (
    <MainScreenLayout rightIconFalse={true} title={'Recents'} handleScroll={() => { }} name="DownloadScreen" >
      <Box justifyContent={'center'} alignItems={'center'} flex={1} >
        <View
          style={[
            styles.searchContainer,
            { backgroundColor: theme.colors.quaternary },
          ]}
        >
          <TextInput
            value={searchTerm}
            onChangeText={setSearchTerm}
            placeholder="Search"
            placeholderTextColor={theme.colors.primaryText}
            style={[
              styles.searchInput,
              { color: theme.colors.primaryText },
            ]}
          />
          <Feather
            name="search"
            size={theme.sizes.iconSmall}
            color={theme.colors.primaryText}
            style={styles.searchIcon}
            onPress={onSearch}
          />
        </View>
        <VirtualizedList
            data={sortedArray}
            keyExtractor={(item, index) => index.toString()}
            renderItem={({ item }: any) => (
              <ItemGroupComponent itemGroup={item} />
            )}
            getItemCount={(data) => data?.length}
            getItem={(data, index) => data[index]}
            initialNumToRender={10}
            maxToRenderPerBatch={10}
            showsVerticalScrollIndicator={false}
            ListEmptyComponent={ListEmptyComponent}
            ListFooterComponent={ListFooterComponent}
        />
      </Box>
    </MainScreenLayout>
  )
}

export default RecentScreen

const styles = StyleSheet.create({
  searchContainer: {
    width: width * 0.85,
    height: height * 0.06,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: width * 0.03,
    alignSelf: 'center',
    marginVertical: height * 0.02,
  },
  searchInput: {
    width: width * 0.7,
    height: height * 0.1,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: width * 0.03,
    marginVertical: height * 0.01,
    alignSelf: 'center',
  },
  searchIcon: {
    width: width * 0.05,
    height: width * 0.05,
  }
})