import { Toast } from "native-base";

const { firestoreDB } = require("../../Modules/auth/firebase/firebase");
const { setInitiatedChatList } = require("./AllyBotSlice");

class AllyBotActions {
    static loadInitiatedChats = (uid) => (dispatch) => {
        console.log("[AllyBot] Loading chats for uid:", uid);
        
        if (!uid) {
            console.log("[AllyBot] No UID provided");
            return () => {};
        }
        
        try {
            const query = firestoreDB()
              .collection('Users')
              .doc(uid)
              .collection('InitializedPdf');
            
            const unsubscribe = query.onSnapshot((querySnapshot) => {
                try {
                    if (!querySnapshot?.docs) {
                        console.log("[AllyBot] No documents in snapshot");
                        dispatch(setInitiatedChatList([]));
                        return;
                    }
                    
                    console.log("[AllyBot] Processing", querySnapshot.docs.length, "documents");
                    
                    const documents = querySnapshot.docs.map((doc) => {
                        try {
                            const data = doc.data() || {};
                            
                            // Set a default date instead of trying to convert Firestore date
                            const date = new Date();
                            
                            // Safely access conversations with fallbacks
                            const conversations = Array.isArray(data.conversations) ? data.conversations : [];
                            const lastMessage = conversations.length > 0 ? conversations[conversations.length - 1] : null;
                            
                            const chatItem = {
                                date: date,
                                docId: doc.id,
                                subject: data.subject || '',
                                name: data.name || 'Unnamed Document',
                                lastConversation: lastMessage || {
                                    date: null,
                                    sender: 'AllyBot',
                                    message: 'no message'
                                }
                            };
                            
                            return chatItem;
                        } catch (docError) {
                            console.log("[AllyBot] Error processing document:", docError);
                            return null;
                        }
                    }).filter(Boolean);
                    
                    // Sort by date (newest first)
                    const sortedDocs = documents.sort((a, b) => b.date - a.date);
                    
                    console.log("[AllyBot] Dispatching", sortedDocs.length, "processed documents");
                    dispatch(setInitiatedChatList(sortedDocs));
                    
                } catch (error) {
                    console.log("[AllyBot] Error in onSnapshot:", error);
                    dispatch(setInitiatedChatList([]));
                }
            }, (error) => {
                console.error("[AllyBot] Firestore error:", error);
                dispatch(setInitiatedChatList([]));
            });
            
            return unsubscribe;
        } catch (error) {
            console.log("[AllyBot] Error setting up listener:", error);
            dispatch(setInitiatedChatList([]));
            return () => {};
        }
    }
    
    static deleteChat = (uid, id) => {
        if (!uid || !id) {
            console.log("[AllyBot] Missing uid or id for deleteChat");
            return;
        }
        
        firestoreDB()
            .collection('Users')
            .doc(uid)
            .collection('InitializedPdf')
            .doc(id)
            .delete()
            .then(() => {
                Toast.show({
                    title: 'Deleted Chat',
                    backgroundColor: '#FF0000'
                });
            })
            .catch(error => {
                console.log("[AllyBot] Error deleting chat:", error);
                Toast.show({
                    title: 'Error deleting chat',
                    backgroundColor: '#FF0000'
                });
            });
    }
}

export default AllyBotActions