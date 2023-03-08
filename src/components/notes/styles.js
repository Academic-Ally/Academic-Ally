import {StyleSheet, Dimensions} from 'react-native';

const {width, height} = Dimensions.get('window');
const createStyles = () =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: '#6360FF',
    },
    headerContainer: {
      height: height * 0.15,
      width: width,
      justifyContent: 'space-between',
      alignItems: 'flex-end',
      flexDirection: 'row',
      paddingHorizontal: 20,
      position: 'relative',
      paddingBottom: 30,
    },
    body: {
      flex: 1,
      backgroundColor: '#F5F5F5',
      borderTopLeftRadius: 40,
      borderTopRightRadius: 40,
      width: width,
      justifyContent: 'space-around',
    },
    bodyContent: {
      flex: 1,
      justifyContent: 'space-around',
      flexDirection: 'row',
      flexWrap: 'wrap',
      paddingHorizontal: 20,
      paddingTop: 20,
    },
    categoryBtns: {
      width: width * 0.4,
      height: height * 0.25,
      backgroundColor: '#fff',
      borderRadius: 20,
      justifyContent: 'center',
      alignItems: 'center',
      marginHorizontal: 0,
      marginVertical: 10,
      //change btn position on hover
      transform: [{scale: 1}],
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 2,
      },
      shadowOpacity: 0.25,
      shadowRadius: 3.84,
      elevation: 5,
    },
    categoryBtnClicked: {
      transform: [{scale: 1.1}],
      borderColor: '#6360FF',
      borderWidth: 2,
    },
    selectBtn: {
      width: width,
      height: height * 0.25,
      justifyContent: 'center',
      alignItems: 'center',
      paddingTop: 120,
    },
    btnText: {
      fontSize: 16,
      fontWeight: '600',
      color: '#161719',
      textAlign: 'center',
      lineHeight: 20,
      marginTop: 10,
    },
    disabledBtn: {
      width: width * 0.4,
      height: height * 0.25,
      backgroundColor: '#D3D3D3',
      borderRadius: 20,
      justifyContent: 'center',
      alignItems: 'center',
      marginHorizontal: 0,
      marginVertical: 10,
      //change btn position on hover
      transform: [{scale: 1}],
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 2,
      },
      shadowOpacity: 0.5,
      shadowRadius: 3.84,
      elevation: 2,
    },
    disabledBtnClicked: {
      transform: [{scale: 1.1}],
      borderColor: '#FF8181',
      borderWidth: 2,
      backgroundColor: '#fff',
    },

    reccomendationContainer: {
      alignItems: 'center',
      marginTop: 20,
      width: width / 1.1,
      height: height / 4.3,
      alignSelf: 'center',
      borderRadius: 10,
      marginBottom: 20,
      backgroundColor: '#6360FF',
    },
    reccomendationStyle: {
      width: width / 1.1,
      height: "75%",
      backgroundColor: '#FCFCFF',
      borderColor: '#0000000',
      borderRadius: 10,
      justifyContent: 'space-around',
      alignItems: 'center',
    },
    containerText: {
      fontSize: 18,
      color: 'white',
      fontWeight: 'bold',
      backgroundColor: 'rgba(255, 255, 255, 0.17)',
      width: 30,
      height: 30,
      borderRadius: 50,
      position: 'absolute',
      justifyContent: 'center',
      alignItems: 'center',
      transform: [{rotate: '45deg'}],
    },
    containerBox: {
      backgroundColor: '#FF8181',
      width: 80,
      height: 80,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: 15,
      shadowColor: '#000',
    },
    subjectName: {
      fontSize: 15,
      fontWeight: '700',
      color: '#161719',
      fontFamily: 'DM Sans',
      fontStyle: 'normal',
      width: '90%',
    },
    subjectContainer: {
      width: width / 1.1,
      height: height / 7,
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      position: 'relative',
      shadowColor: '#000',
      borderRadius: 10,
      paddingHorizontal: 15,
    },
    categoryBtnsContainer: {
      flex: 1,
      justifyContent: 'space-around',
      flexDirection: 'row',
      flexWrap: 'wrap',
      alignSelf: 'center',
    },
    notesListHeaderContainer: {
      width: width,
      height: height * 0.08,
      justifyContent: 'space-evenly',
      alignItems: 'center',
      flexDirection: 'row',
      paddingHorizontal: 20,
    },
    notesListHeaderText: {
      fontSize: 16,
      fontWeight: 'bold',
      color: '#161719',
    },
    notesListValueText: {
      fontSize: 14,
      fontWeight: 'bold',
      color: '#91919F',
    },
    header: {
      width: width,
      height: height * 0.08,
      justifyContent: 'center',
      alignItems: 'center',
      marginVertical: 10,
    },
    headerText: {
      fontSize: 22,
      fontWeight: 'bold',
      color: '#161719',
      textDecorationLine: 'underline',
    },
    cardOptions: {
        width: '100%',
        height: '25%',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexDirection: 'row',
        paddingHorizontal: 25,
    },
    cardOptionContainer: {
      justifyContent: 'space-between',
      alignItems: 'center',
      flexDirection: 'row',
    },
    cardOptionText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: '600',
        paddingRight: 5,
      }

  });

export default createStyles;