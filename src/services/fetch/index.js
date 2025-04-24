import AsyncStorage from '@react-native-async-storage/async-storage';
import auth from '@react-native-firebase/auth';
import { firebase } from '@react-native-firebase/auth';
import dynamicLinks from '@react-native-firebase/dynamic-links';
import firestore from '@react-native-firebase/firestore';
import messaging from '@react-native-firebase/messaging';
import { Toast } from 'native-base';
import { Alert, Share } from 'react-native';
import { PERMISSIONS, request } from 'react-native-permissions';

import { setVisitedSubjects } from '../../redux/reducers/subjectsList';
import CrashlyticsService from '../../services/CrashlyticsService';

export const userFirestoreData = async (userData, type, item, dispatch) => {
  let list = [];
  await firestore()
    .collection('Universities')
    .doc(`${userData.university}`)
    .collection(`${userData.course}`)
    .doc(`${userData.branch}`)
    .collection(`${userData.sem}`)
    .doc(type)
    .collection(item.subjectName).get().then((querySnapshot) => {
      if (querySnapshot.docs.length > 0) {
        querySnapshot.forEach((doc) => {
          list.push({
            ...doc.data(),
            id: doc.id,
            branch: userData.branch,
            sem: userData.sem,
            university: userData.university || userData.university,
            course: userData.course || userData.course,
          });
        });
      }
    });
  dispatch(setVisitedSubjects({ subject: list, status: type, subjectName: item.subjectName, branch: userData.branch, sem: userData.sem }));
  return list;
}

const checkIfDocExists = async (item, type, usersData) => {
  const status = await firestore()
    .collection('Universities')
    .doc(`${usersData.usersData.university}`)
    .collection(`${usersData.usersData.course}`)
    .doc(`${usersData.usersData.branch}`)
    .collection(`${usersData.usersData.sem}`)
    .doc(type)
    .collection(item.subjectName)
    .get().then((querySnapshot) => {
      if (querySnapshot.docs.length > 0) {
        return true;
      } else {
        return false;
      }
    });
  return status;
}

const updateFirebstore = async (item, userFirestoreData) => {
  await firestore()
    .collection('Universities')
    .doc(userFirestoreData.data().university).collection(userFirestoreData.data().course)
    .doc(userFirestoreData.data().branch)
    .collection(userFirestoreData.data().sem)
    .doc('SubjectsList').set(
      {
        list: item,
      },
    )
}

export const fetchSubjectList = async (setList, dispatch, setReccommendSubjects, setReccommendSubjectsLoaded, setLoaded, usersData) => {
  await firestore()
    .collection('Users')
    .doc(auth().currentUser?.uid)
    .get()
    .then(async (userFirestoreData) => {
      let updatedList = [];
      await firestore()
        .collection('Universities')
        .doc(userFirestoreData.data().university).collection(userFirestoreData.data().course)
        .doc(userFirestoreData.data().branch)
        .collection(userFirestoreData.data().sem)
        .doc('SubjectsList')
        .get().then(async (item) => {
          updatedList.push(...item.data().list);
          setList(
            updatedList.filter(
              (item, index, self) =>
                self.indexOf(item) === index,
            ),
          );
          setLoaded(true);
          dispatch(setReccommendSubjects(updatedList));
          dispatch(setReccommendSubjectsLoaded(true));
        })
    }).catch((error) => {
      console.log("Error getting document:", error);
    }
    );
}

export const fetchBookmarksList = async (dispatch, setBookmarks, setListData) => {
  try {
    const item = await firestore()
      .collection('Users')
      .doc(auth().currentUser?.uid)
      .collection('NotesBookmarked')
      .get();

    const updatedList = item.docs.map((doc) => (
      {
        ...doc.data(),
        'docId': doc?.id
      }
    ));

    dispatch(setBookmarks(updatedList));
    setListData(updatedList);
  } catch (error) {
    console.log("Error getting document:", error);
    CrashlyticsService.recordError(error);
  }
};


export const fetchNotesList = async (dispatch, setSubjectsList, setListLoaded, data, val) => {
  try {
    const list = await AsyncStorage.getItem('subjectsList');
    if (list?.length !== 0 && list !== null && val === true) {
      dispatch(setSubjectsList(JSON.parse(list)));
      dispatch(setListLoaded(true));
    } else {
      firestore()
        .collection('QueryList')
        .doc(`${data.university}`)
        .collection(`${data.course}`)
        .doc('SubjectsListDetail')
        .get()
        .then((doc) => {
          const subjectsList = doc.data().list;
          dispatch(setSubjectsList(subjectsList));
          dispatch(setListLoaded(true));
        })
        .catch(error => {
          dispatch(setListLoaded(false));
          Toast.show({
            title: 'Check your internet connection and try again later',
            duration: 3000,
          });
        });
    }
  } catch (error) {
    console.error(error);
  }
}

export async function ViewCount(data) {
  try {
    await firestore()
      .collection('Universities')
      .doc(`${data.university}`)
      .collection(`${data.course}`)
      .doc(`${data.branch}`)
      .collection(`${data.sem}`)
      .doc(`${data.type}`)
      .collection(`${data.subjectName}`)
      .doc(`${data.id}`)
      .update({
        views: firebase.firestore.FieldValue.increment(1) || 0
      })
  }
  catch (error) {
    console.log(error);
  }
}

async function addToUSersRateList(data, rating) {
  await firestore()
    .collection('Users')
    .doc(auth().currentUser?.uid)
    .collection('RatedList')
    .doc(`${data.did}`)
    .set({
      subject: data.subjectName,
      rating: rating,
      category: data.type,
      university: data.university,
      course: data.course,
      branch: data.branch,
      sem: data.sem,
      id: data.id,
      did: data.did,
      name: data.name,
      size: data.size,
      college: data.college,
      uploaderId: data.uploaderId,
      uploaderName: data.uploaderName,
    })
}

export async function submitRating(data, newRating) {
  const rate = (newRating + data.rating)
  const rating = rate / 2;
  if (data.rating === 0) {
    try {
      await firestore()
        .collection('Universities')
        .doc(data.university)
        .collection(data.course)
        .doc(data.branch)
        .collection(data.sem)
        .doc(data.type)
        .collection(data.subjectName)
        .doc(data.id)
        .update({
          rating: newRating,
        })
      addToUSersRateList(data, newRating);

    }
    catch (error) {
      console.log(error);
    }
  }
  else {
    try {
      await firestore()
        .collection('Universities')
        .doc(data.university)
        .collection(data.course)
        .doc(data.branch)
        .collection(data.sem)
        .doc(data.type)
        .collection(data.subjectName)
        .doc(data.id)
        .update({
          rating: rating,
        })
      addToUSersRateList(data, rating);
    }
    catch (error) {
      console.log(error);
    }
  }
}

export async function submitReport(userData, ReportData, notesData) {
  try {
    await firestore()
      .collection('userReports')
      .doc(userData.university)
      .collection(userData.course)
      .doc(userData.branch)
      .collection(userData.sem)
      .doc(auth().currentUser?.uid)
      .set({
        ...userData,
        uid: auth().currentUser?.uid,
        report: ReportData,
        subjectName: notesData.name,
        subjectDid: notesData.did,
        subjectId: notesData.id,
        date: new Date().getTime(),
        sCourse: userData.course,
        sBranch: userData.branch,
        sSem: userData.sem,
        sUniversity: userData.university,
        sCategory: notesData.category,
      })
  }
  catch (error) {
    Toast.show({
      title: 'Something went wrong',
      duration: 3000,
    });
  }
}

export async function getMailId() {
  const mail = await firestore()
    .collection('utils')
    .doc('mail')
    .get()
    .then((doc) => {
      return doc.data().mailId;
    }
    )
    .catch(error => {
      Toast.show({
        title: 'Something went wrong',
        duration: 3000,
      });
    }
    );
  return mail;
}

export const shareNotes = async (notesData, dynamicLink) => {
  const link = await dynamicLinks().buildShortLink(
    {
      link: `https://app.getacademically.co?id=/${notesData?.category}/${notesData?.university}/${notesData?.course}/${notesData?.branch}/${notesData?.sem}/${notesData?.subject}/${notesData?.did}/${notesData?.units}/${notesData?.name}/ViewNotes`,
      domainUriPrefix: dynamicLink,
      android: {
        packageName: 'com.academically',
      },
    },
    dynamicLinks.ShortLinkType.SHORT,
  ).then((res) => {
    Share.share({
      title: notesData.subject,
      message: `If you're studying ${notesData.subject}, you might find these ${notesData.category} on Academic Ally helpfull. I did! Check them out:
      ${res}`,
    });
  }).catch((error) => {
    console.log(error)
    Toast.show({
      title: 'Something went wrong, Please try again later',
      duration: 3000,
    })
  });
}

export const ratedResourcesList = async () => {
  const list = await firestore()
    .collection('Users')
    .doc(auth().currentUser?.uid)
    .get()
    .then(async (userFirestoreData) => {
      let updatedList = [];
      await firestore()
        .collection('Users')
        .doc(auth().currentUser?.uid)
        .collection('RatedList')
        .get().then(async (item) => {
          for (const items of item.docs) {
            updatedList.push(items.id)
          };
        })
      return updatedList;
    }).catch((error) => {
      console.log("Error getting document:", error);
    }
    );
  return list;
}

async function requestPermisssion() {
  const authStatus = await messaging().requestPermission();
  const enabled =
    authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
    authStatus === messaging.AuthorizationStatus.PROVISIONAL;
}

export const getFcmToken = async () => {
  try {
    let fcmToken = await AsyncStorage.getItem('fcmToken');
    
    // Only request notifications permission if needed
    if (!fcmToken) {
      await requestPermisssion();
      fcmToken = await messaging().getToken();
      
      if (fcmToken && auth().currentUser?.uid) {
        await AsyncStorage.setItem('fcmToken', fcmToken);
        
        try {
          await firestore()
            .collection('Users')
            .doc(auth().currentUser.uid)
            .update({
              fcmToken: fcmToken,
            });
        } catch (error) {
          console.log("Error updating FCM token:", error);
        }
      }
    }
    return fcmToken;
  } catch (error) {
    console.error("Error in getFcmToken:", error);
    return null;
  }
}

export const NotificationListner = async () => {
  try {
    const unsubscribe = messaging().onMessage(async remoteMessage => {
      if (remoteMessage) {
        Alert.alert('A new FCM message arrived!', JSON.stringify(remoteMessage));
      }
    });
    return unsubscribe;
  } catch (error) {
    console.error("Error in NotificationListner:", error);
    return () => {};
  }
}