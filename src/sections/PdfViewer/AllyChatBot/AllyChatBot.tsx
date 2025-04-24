import LottieView from 'lottie-react-native';
import { Avatar, Box, Icon, IconButton, Toast } from 'native-base';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Dimensions, FlatList, Image, KeyboardAvoidingView, Modal, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import MaterialIcons from 'react-native-vector-icons/MaterialIcons'
import { useSelector } from 'react-redux';

import PdfViewerAction from '../../../screens/PdfViewer/pdfViewerAction';
import { ChatHeader } from './chatHeader';
import createStyles from './styles';

interface Message {
    id: number;
    text: string;
    senderId: string;
    sender: string;
    image: any;
    messageText: any
    message: any
    loading : boolean,
    date: any
}

interface Props {
    open: boolean,
    close: any,
    docId: any,
    choosenDoc: any
}

const { width, height } = Dimensions.get('screen')

const ChatScreen  = React.memo(({open, close, docId, choosenDoc}: Props) => {
    const [messages, setMessages] = useState<any>([]);
    const [messageText, setMessageText] = useState('');
    const data = {
        participantPhoto: "https://firebasestorage.googleapis.com/v0/b/academic-ally-app.appspot.com/o/logo%2FAlly Bot™.png?alt=media&token=d3b0a0ad-8dc7-4428-84de-4b952f0998ad"
    }
    const {uid}: any = useSelector((state: any) => state.bootReducer.userInfo);
    const theme = useSelector((state: any) => { return state.theme; });
    const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);

    const usersPhoto = useSelector((state: any)=> state.usersData.userProfile)
    const flatListRef: any = useRef(null);

    // useEffect(() => {
    //   flatListRef.current.scrollToEnd({ animated: true });
    // }, [data]);

    useEffect(() => {
        PdfViewerAction.monitorMessageUpdates(docId, setMessages, uid);
    }, [])

    const renderMessage = (item: Message) => {
      const isMyMessage = item?.sender === 'AllyBot' ? false : true;
      const loading = item?.loading ? true : false
        return (
            <View
            style={[
              styles.flexRow,
              {alignSelf: isMyMessage ? 'flex-end' : 'flex-start'},
            ]}>
            {!isMyMessage &&(
              <Image source={{
                uri: data?.participantPhoto
              }} style={styles.avatarImg} />
            )}
            
            <View style={isMyMessage ? styles.myMssgContainer : styles.mssgContainer}>
              <View style={styles.textContainer}>
              {
              !loading ?
                <Text
                  style={[
                    styles.mssgText,
                    {color: theme.colors.white},
                  ]}>
                  {item?.message}
                </Text>
                :
            <Box >
            <LottieView
                source={require('../../../assets/lottie/textLoading.json')}
                autoPlay
                loop
                style={{
                  width: 80,
                }}
              />
            </Box>
            }
              </View>
            </View> 
            {isMyMessage && (
              <Image source={{
                uri: usersPhoto ? usersPhoto : 'https://firebasestorage.googleapis.com/v0/b/academic-ally-app.appspot.com/o/logo%2FAcademicAllyLogo.png?alt=media&token=0c6b43ea-6d06-49b1-acdf-5516bed88f28'
              }} style={styles.avatarImg} />
            )}
          </View>
        );
    };

    const sendMessage = () => {
        if (messages?.length > 0){
          setMessages([...messages, {
            sender: 'user',
            message: messageText,
            date: new Date(),
          },{
            sender: 'AllyBot',
            loading: true,
            date: new Date()
          } 
        ])
      }
      else{
        setMessages([{
          sender: 'user',
          message: messageText,
          date: new Date(),
        },{
          sender: 'AllyBot',
          loading: true,
          date: new Date()
        } 
      ])
      setMessageText("")
      }
      setMessageText("")
        PdfViewerAction.chatWithPdf(docId, messageText, uid).then((res)=>{
          if(!res){
            console.log("res", res)
            close()
            Toast.show({
              title: 'Error: PDF Text Recognition',
              description: 'Oops! It seems we encountered an issue with the PDF you provided. Our AI is having trouble recognizing handwritten or cursive text, which probably caused the error. Please try another PDF with clear, machine-readable text for accurate answers to your questions.Thank you for your understanding! 📄🚀',
              duration: 10000,
              collapsable: true
            })
          }
        })
    };
    return (
        <Modal >
            <View style={[styles.mainContainer, {backgroundColor: theme.colors.quaternary}]}>
            <ChatHeader name={'AllyBot'} onPress={()=>{close()}}/>
                    <FlatList
                        data={messages}
                        showsVerticalScrollIndicator={false}
                        ref={flatListRef}
                        contentContainerStyle={styles.contentContainer}
                        renderItem={({ item }) => renderMessage(item)}
                        onContentSizeChange={() =>
                            flatListRef.current.scrollToEnd({ animated: true })
                          }
                          // inverted
                    />
                    <View style={styless.inputContainer}>
                        <TextInput
                            style={styless.input}
                            value={messageText}
                            onChangeText={setMessageText}
                            placeholder="  Send a message"
                            placeholderTextColor="#999"
                            multiline
                            underlineColorAndroid="transparent"
                            onSubmitEditing={sendMessage}
                            returnKeyType='send'
                        />
                        <TouchableOpacity style={styless.sendButton} onPress={sendMessage}>
                            <Text style={styless.sendButtonText}>
                              <Icon as={MaterialIcons} name='send' color={theme.colors.white} size={22  } />
                            </Text>
                        </TouchableOpacity>
                    </View>
            </View>
        </Modal>
    );
});

const styless = StyleSheet.create({
    inputContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        borderTopColor: '#ccc',
        paddingHorizontal: 8,
        paddingVertical: 5
    },
    input: {
        flex: 1,
        minHeight: 40,
        maxHeight: 200,
        paddingHorizontal: 5,
        fontSize: 16,
        color: '#333',
        backgroundColor: '#f5f5f5',
        borderRadius: 10,
    },
    sendButton: {
        marginLeft: 4,
        paddingHorizontal: 16,
        paddingVertical: 8,
        backgroundColor: '#7DC579',
        borderRadius: 10,
        height: 50,
        justifyContent:'center'
    },
    sendButtonText: {
        fontSize: 14,
        color: '#F1F1FA',
        fontWeight: 'bold'
    },
});

export default ChatScreen;
