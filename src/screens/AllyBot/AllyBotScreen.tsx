import AllyBotActions from './AllyBotActions'
import { formatDistanceToNow } from 'date-fns';
import LottieView from 'lottie-react-native';
import { Box, Divider, Icon, IconButton, Modal, Stack, Text } from 'native-base'
import { fillAndStroke } from 'pdf-lib';
import React, { useEffect, useMemo, useState } from 'react'
import { FlatList, ScrollView, StyleSheet, TouchableOpacity, View } from 'react-native'
import AntDesign from 'react-native-vector-icons/AntDesign'
import { useDispatch, useSelector } from 'react-redux'

import MainScreenLayout from '../../layouts/mainScreenLayout'
import AllyChatBot from '../../sections/PdfViewer/AllyChatBot/AllyChatBot'
import UtilityService from '../../services/UtilityService'

type Props = {}

const AllyBotScreen = (props: Props) => {
  const {uid}: any = useSelector((state: any)=> state.bootReducer.userInfo);
  const theme = useSelector((state: any) => state.theme);
  const dispatch: any = useDispatch<any>()
  const InitiatedChats = useSelector((state: any)=> state.AllyBotReducer.initiatedChatsList)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [openAllyBot, setOpenAllyBot] = useState(false)
  const [choosenDoc, setchoosenDoc] = useState(null)
  const [docId, setDocId] = useState(null)
  const [deleteChatId, setDeleteChatId] = useState(null)
  useEffect(()=>{
    dispatch(AllyBotActions.loadInitiatedChats(uid));
  },[])
  const getTimeAgo = (date1: any, date2: any) => {
    const timeDifference = Math.abs(date1 - date2);
    return formatDistanceToNow(date1, { addSuffix: true });
  };

  const renderItems = (item: any, index: any) => {
    return (
      <>
        <TouchableOpacity key={index} style={{ padding: 10, flexDirection: 'row', width: theme.sizes.width, justifyContent:'space-between', borderRadius: 15, marginHorizontal:5, marginVertical: 7, }} 
        onPress={()=>{
          setDocId(item.docId);
          setchoosenDoc(item);
          setOpenAllyBot(true)
        }}  >
            <Box width={'18%'} borderRadius={10} height={16} backgroundColor={theme.colors.tertiary} />
            <Box flexDirection={'column'} width={'80%'} justifyContent={'space-evenly'} paddingLeft={2.5} >
            <Box flexDirection={'row'} justifyContent={'space-between'} paddingRight={2} paddingBottom={2} >
                <Text fontWeight={'bold'} color={theme.colors.primaryText} >{(UtilityService.removeString(item?.name)).slice(0,25)}</Text>
                <Text color={theme.colors.terinaryText} >
                  {
                    item.lastConversation.date !== null ? (getTimeAgo(new Date(item.lastConversation.date.seconds * 1000 + item.lastConversation.date.nanoseconds / 1000000), new Date())).replace('about'," "): null
                  }
                </Text>
            </Box>
            <Box flexDirection={'row'} justifyContent={'space-between'} paddingRight={2} alignItems={'center'} >
                <Text color={theme.colors.terinaryText}>{(item?.lastConversation.message).slice(0,30) + '....'}</Text>
                <IconButton
                  borderRadius={'full'}
                  _hover={{
                      bg: theme.colors.primary,
                  }}
                  variant="ghost"
                  icon={<Icon as={AntDesign} name="delete" size="md" color={'#FF0000'} />}
                  onPress={() => {
                    setDeleteChatId(item?.docId);
                    setConfirmDelete(true)
                  }}
                />
            </Box>
            </Box>
        </TouchableOpacity>
        <Modal isOpen={confirmDelete} onClose={() => {
                    setConfirmDelete(false);
                }} size={'md'}>
                    <Modal.Content >
                        <Box margin={2} >
                            <Text fontSize={'14px'} fontWeight={'700'} marginTop={3} marginX={3} textAlign="center" >
                              Are you sure you want to delete this chat?
                            </Text>
                            <Stack direction="row" space={2} marginY={5} alignItems="center" justifyContent="space-evenly" >  
                              <TouchableOpacity style={{
                                    backgroundColor: theme.colors.primary,
                                    borderRadius: 10,
                                    paddingHorizontal: theme.sizes.width * 0.06,
                                    paddingVertical: 10,
                                }} onPress={()=>{
                                  setConfirmDelete(false)
                                }} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'600'} textAlign="center" color={"#F1F1FA"} >
                                        Cancel
                                    </Text>
                                </TouchableOpacity>
                                <TouchableOpacity onPress={() => {
                                  AllyBotActions.deleteChat(uid, deleteChatId);
                                  setConfirmDelete(false)
                                }} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'600'} textAlign="center" color={theme.colors.redError} >
                                        Delete
                                    </Text>
                              </TouchableOpacity>
                            </Stack>
                        </Box>
                    </Modal.Content>
                </Modal>
      </>
    )
  }
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

  return (
    <MainScreenLayout rightIconFalse={true} title={'AllyBot'} handleScroll={() => { }} name="AllyBot" >
      <FlatList
        style={{
          marginTop: 5,
        }}
        showsVerticalScrollIndicator={false}
        data={InitiatedChats}
        renderItem={({item, index}: any) => renderItems(item, index)}
        ItemSeparatorComponent={()=>{
          return <Divider />
        }}
        ListEmptyComponent={ListEmptyComponent}
        ListHeaderComponent={()=>{
          return <>
             <Text margin={5} fontWeight={600} fontSize={'3xl'} color={theme.colors.primaryText} >
                Chats
              </Text>
          </>
        }}
      />{
        openAllyBot &&
      <AllyChatBot open={true} close={()=> {setOpenAllyBot(false)}} docId={docId} choosenDoc={choosenDoc} />
      }
    </MainScreenLayout>
  )
}

export default AllyBotScreen

const styles = StyleSheet.create({})