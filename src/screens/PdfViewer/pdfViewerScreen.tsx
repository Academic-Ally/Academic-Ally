import { RouteProp, useRoute } from '@react-navigation/native';
import { Alert, Box, Center, CloseIcon, HStack, Icon, IconButton, Modal, Text, Toast, VStack } from 'native-base';
import { PDFInvalidObject } from 'pdf-lib';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { ActivityIndicator, Dimensions, Linking, StatusBar, View } from 'react-native';
import Pdf from 'react-native-pdf';
import Fontisto from 'react-native-vector-icons/Fontisto';
import Ionicons from 'react-native-vector-icons/Ionicons';
import { useDispatch, useSelector } from 'react-redux';

import RestrictedScreen from '../../layouts/restrictedScreen';
import { firestoreDB } from '../../Modules/auth/firebase/firebase';
import { userAddToRecentsStart } from '../../redux/reducers/usersRecentPdfsManager';
import AllyChatBot from '../../sections/PdfViewer/AllyChatBot/AllyChatBot';
import ExistingChatList from '../../sections/PdfViewer/ExistingChatListModal';
import PdfPageSplitter from '../../sections/PdfViewer/PdfPageSplitter';
import PopOver from '../../sections/PdfViewer/PopOver';
import RecentlyVisited from '../../sections/PdfViewer/RecentlyVisited';
import NavigationService from '../../services/NavigationService';
import UtilityService from '../../services/UtilityService';
import PdfViewerAction from './pdfViewerAction';
import createStyles from './styles';

type RootStackParamList = {
  NotesList: {
    userData: {
      course: string;
      branch: string;
      sem: string;
    };
    notesData: any;
    category: string;
    subjectName: string;
  };
};

const PdfViewer = React.memo(() => {
  const route = useRoute<RouteProp<RootStackParamList, 'NotesList'>>();
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage]: any = useState(0);
  const [landscape, setLandscape] = useState(false);
  const [scale, setScale] = useState(1);
  const [pageNo, setPageNo] = useState(0);
  const [Display, setDisplay] = useState<any>(true);
  const [viewRecentSheet, setViewRecentSheet] = useState<any>(false);
  const [splitPages, setSplitPages] = useState<any>([]);
  const [visibleSpliterModal, setVisibleSpliterModal] = useState<any>(false)
  const [filePath, setFilePath]= useState<any>(null);
  const [viewPdfChatModal, setViewPdfChatModal] = useState<boolean>(false)
  const [existingChatList, setExistingChatList] = useState<any>([])
  const [existingChatListModal, setExistingChatListModal] = useState<any>(false)
  const [currentProgress, setCurrentProgress] = useState<any>('started...')
  const [startedProcessing, setStartedProcessing] = useState<any>(false)
  const [sourceId, setSourceId] = useState<string>('');
  const [choosenDoc, setchoosenDoc] = useState<any>( null );
  const [pdfLoaded, setPdfLoaded] = useState<boolean>(false);

  const { userData, notesData } = route.params;
  const { university, course, branch, sem, did, uid, uid2, uid3, category, size } = notesData;
  const name = UtilityService.replaceUnusualCharacters(notesData?.name, '&');
  const subject = UtilityService.replaceUnusualCharacters(notesData?.subject, '&');
  const pdfRef = useRef(null);
  const dispatch: any = useDispatch();

  const placeholdersValues = [university, course, branch, sem, category, name, subject, did, uid, uid2, uid3];
  const mainUrl = useSelector((state: any) => state.bootReducer.protectedUtils?.mainUrl);
  const secondaryUrl = useSelector((state: any) => state.bootReducer.protectedUtils?.secondaryUrl);
  const userInfo: any = useSelector((state: any) => state.bootReducer.userInfo);
  const theme = useSelector((state: any) => { return state.theme; });
  const potrait = useSelector((state: any) => state.theme).isPotrait;
  const { usersData } = useSelector((state: any) => state.usersData);
  const styles = useMemo(() => createStyles(theme.colors, theme.sizes, landscape), [theme, potrait]);
  const [url, setUrl] = useState<any>(null);
  const mail = useSelector((state: any) => state?.bootReducer?.utilis);
  const {max_init_per_day = 0, max_pages = 0, premium_max_init_per_day = 0, premium_max_pages = 0, mailTo = 'syedaffan880@gmail.com', status = false } = useSelector((state: any) => state?.bootReducer?.utilis)?.pdfChat || {};
  const [maxPagesAllowed, setMaxPagesAllowed] = useState(max_pages);
  const [maxInitiationLimit, setMaxInitiationLimit] = useState(max_init_per_day);

  function bitsToKB(bits: any) {
    const kilobytes = bits / 1024 / 8;
    return kilobytes;
  }

  useEffect(()=>{
    if(usersData?.premiumUser){
      setMaxInitiationLimit(premium_max_init_per_day);
      setMaxPagesAllowed(premium_max_pages);
    }
  },[])

const handleOpenEmail = () => {
  const email = mailTo || 'admin@getacademically.co';
  const subject = 'Premium Plan Inquiry'; // Subject for the email
  const body = 'Hi,\n\nI am interested in upgrading to the Premium plan for unlimited PDF chat access. Please provide me with more information about the premium options and how to get started.\n\nThank you!\n\n'; // Pre-written message body

  const url = `mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  Linking.openURL(url); // Open the email app with the pre-written email content
};

  useEffect(() => {
    const updateOrientation = () => {
      const { width, height } = Dimensions.get('window');
      setLandscape(width > height ? true : false);

      if (landscape) {
        setDisplay(false)
        setScale(3);
      }
      else {
        setDisplay(true)
        setScale(1)
      }
    };

    updateOrientation();
  }, []);

  useEffect(() => {
    if (potrait) {
      setDisplay(true);
      setScale(1)
    }
    else {
      setDisplay(false)
      setScale(3)
    }
  }, [potrait])

  useEffect(() => {
    if (url === null || url === undefined || url === "") {
      PdfViewerAction.checkIfFileExists(notesData).then((res: any) => {
        if (res) {
          setUrl(res)
        }
        else {
          setUrl(UtilityService.replaceString(mainUrl, placeholdersValues))
        }
      });
    }
  }, [mainUrl, placeholdersValues, secondaryUrl, url]);

  const source: object = {
    uri: url,
    cache: true,
    expiration: 60 * 60 * 24 * 7,
  };

  const handleChat = () => {
    if(existingChatList?.length > 0){
      setExistingChatListModal(true)
    }
    else if (totalPages > maxPagesAllowed && existingChatList?.length === 0){
      setVisibleSpliterModal(true);
    }
    else if(totalPages < maxPagesAllowed && existingChatList?.length === 0 ){
      createChat([])
      setVisibleSpliterModal(true);
    }
  }

  const createChat = (pages: any) => {
    const uid = userInfo.uid
      PdfViewerAction.handleCreateFile(notesData, url, pages, uid, setCurrentProgress, setStartedProcessing).then((res: any)=>{
        if(res?.sourceId){
          PdfViewerAction.getChatDoc(uid, res?.docId).then((data)=>{
            setchoosenDoc([data])
            setSourceId(res?.docId);
            setVisibleSpliterModal(false);
            setViewPdfChatModal(true);
          })
        }
        else{
          if(res.message){
            Toast.show({
              title: `${res.message}`,
              placement: 'top-right',
              backgroundColor: theme.colors.redError,
            });
          }
          else{
            Toast.show({
              title: 'Error, Initiating chat',
              placement: 'top-right',
              backgroundColor: theme.colors.redError,
            });
          }
          setVisibleSpliterModal(false);
            setViewPdfChatModal(false);
        }
      })
  }

  const handleAddNewChat = () =>{
    if (totalPages > maxPagesAllowed ){
      setVisibleSpliterModal(true);
    }
    else {
      setVisibleSpliterModal(true);
      const newRange = Array.from({ length: totalPages - 1 + 1 }, (_, index) => 1 + index);
      createChat(newRange)
    }
  }
  
  useEffect(() => {
    if(notesData?.id){
    const unsubscribe = firestoreDB()
      .collection('Users')
      .doc(userInfo.uid)
      .collection('InitializedPdf')
      .where('docId', '>=', notesData?.id)
      .where('docId', '<=', `${notesData?.id}\uf8ff`)
      .onSnapshot((querySnapshot) => {
        const documents = querySnapshot?.docs
          .map((doc) => {
            const data = doc.data();
            const date = data?.date || data?.date?.toDate();
            return { ...data, date, docId: doc.id }; 
          })
          .sort((a, b) => b.date - a.date);
        setExistingChatList(documents);
      });
    return () => unsubscribe();
    }
  }, []);
  
  const handleInitiateChat = () => {
    maxInitiationLimit > usersData?.initiatedChats
    ? handleChat()
    : Toast.show({
        title: 'Message Limit Exceeded 🚫',
        description:
          'Upgrade to our Premium plan for unlimited PDF chat access! 📩😊\n\n'
          + `Contact us at ${mailTo} to inquire about premium options and get started.\n\n`
          + 'Thank you for being part of our community! Feel free to reach out if you have any questions or need help.\n\n'
          + 'Happy chatting! 😊📩',
        backgroundColor: '#FFA726',
        placement: 'top',
        duration: 5000,
        collapsable: true,
        onTouchStart: handleOpenEmail
      });
  }

  return (
    <RestrictedScreen>
      <StatusBar
        backgroundColor={theme.colors.primary}
        barStyle="light-content"
      />
      {
        viewPdfChatModal &&
        <AllyChatBot open={viewPdfChatModal} close={()=> {
          setVisibleSpliterModal(false);
          setViewPdfChatModal(false);
          setExistingChatListModal(false);
        }} docId={sourceId} choosenDoc={choosenDoc} />
      }
      <ExistingChatList existingChatList={existingChatList} open={existingChatListModal} close={()=>{ setExistingChatListModal(false) }} handleAddNewChat={handleAddNewChat} setDocId={(id: any)=>{
        setVisibleSpliterModal(false);
        setViewPdfChatModal(true);
        setSourceId(id);
        setchoosenDoc(existingChatList.filter((doc: any)=> doc.docId === id))
      }} />
      <PdfPageSplitter setVisibleSpliterModal={()=> setVisibleSpliterModal(false)} createChat={createChat} visibleSpliterModal={visibleSpliterModal} currentProgress={currentProgress} startedProcessing={startedProcessing} totalPdfPages={totalPages} maxPages={maxPagesAllowed} />
      <View style={styles.container}>
        <View style={Display ? styles.headerContainer : { display: 'none' }} >
          <IconButton borderRadius={'full'} _hover={{ bg: '#D3D3D3', }} _pressed={{ bg: '#D3D3D3', }} onPress={() => { NavigationService.goBack() }} variant="ghost" icon={<Icon as={Ionicons} name="chevron-back-outline" size={'xl'} color={theme.colors.white} />} p={0} />
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'center', width: '60%' }}>
            <Text style={{ fontSize: 18, color: '#ffffff', fontWeight: '600', width: '100%', textAlign: 'center' }}>
              Page {currentPage} of {totalPages}
            </Text>
          </View>
          <IconButton borderRadius={'xl'} _hover={{ bg: '#D3D3D3', }}  _pressed={{ bg: '#D3D3D3', }} onPress={() => setViewRecentSheet(true)} variant="ghost" icon={<Icon as={Fontisto} name="history" size={'lg'} color={theme.colors.white} />} p={0} />
         {
          status && pdfLoaded && 
          <IconButton
          borderRadius={'xl'}
          _hover={{ bg: '#D3D3D3' }}
          onPress={handleInitiateChat}
          variant="ghost"
          _pressed={{ bg: '#D3D3D3', }}
          icon={<Icon as={Ionicons} name="md-chatbubble-ellipses-outline" size={'xl'} color={theme.colors.white} />}
          p={0}
        />
         }
        </View>
        <View style={styles.body}>
          <View>
            <View style={{ justifyContent: 'center', alignItems: 'center' }}>
              {
                url && <Pdf
                  ref={pdfRef}
                  trustAllCerts={false}
                  source={source}
                  scale={scale}
                  minScale={0.5}
                  maxScale={5.0}
                  spacing={10}
                  enableRTL={true}
                  enableAnnotationRendering={true}
                  onPageChanged={(page, numberOfPages) => {
                    setCurrentPage(page);
                  }}
                  page={pageNo}
                  onPageSingleTap={() => {
                    if (potrait) {
                      setDisplay(Display ? false : true);
                    }
                  }}
                  renderActivityIndicator={progress => {
                    var progressBar = progress * 100;
                    return (
                      <View>
                        <ActivityIndicator
                          animating={true}
                          color="#FF8181"
                          size="large"
                        />
                        <Text style={{ textAlign: 'center', color: "#FF8181" }}>
                          {progressBar?.toFixed(2)}% Loaded
                        </Text>
                      </View>
                    );
                  }}
                  onError={error => {
                    if (error?.toString()?.toLowerCase()?.includes('no pdf  source')) {
                      setUrl(UtilityService.replaceString(secondaryUrl, placeholdersValues))
                    }
                  }}
                  onLoadComplete={(numberOfPages, filePath) => {
                    dispatch(userAddToRecentsStart({ ...notesData, "viewedTime": `${new Date()}`, "category": category, filePath }));
                    setFilePath(filePath);
                    setTotalPages(numberOfPages);
                    setPdfLoaded(PdfViewerAction.canPDFBeAnalyzed(size, numberOfPages))
                  }}
                  style={{
                    width: '100%',
                    height: '100%',
                  }}
                />
              }
            </View>
          </View>
        </View>
        <View style={{zIndex: 1}}>
          <PopOver url={url} notesData={notesData} />
        </View>
        <RecentlyVisited toggleOpen={viewRecentSheet} toggleClose={() => setViewRecentSheet(false)} userData={userData} notesData={notesData} />
      </View>
    </RestrictedScreen>
  );
});

export default PdfViewer;
