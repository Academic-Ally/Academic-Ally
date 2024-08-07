import { Dimensions, StyleSheet } from 'react-native';

const {width, height} = Dimensions.get('window');
const createStyles = (theme: any, sizes: any) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.primary,
      marginBottom: 0,
    },
    headerContainer: {
      height: height * 0.08,
      width: width,
      justifyContent: 'space-between',
      alignItems: 'flex-end',
      flexDirection: 'row',
      paddingHorizontal: width * 0.05,
      position: 'relative',
      paddingBottom: height * 0.015,
    },
    body: {
      flex: 1,
      backgroundColor: theme.secondary,
      borderTopLeftRadius: 30,
      borderTopRightRadius: 30,
      width: width,
      justifyContent: 'center',
      alignItems: 'center',
    },
    bodyContent: {
      height: height * 0.8,
      justifyContent: 'center',
      alignItems: 'center',
    },
    searchContainer: {
      width: width * 0.9,
      height: height * 0.06,
      backgroundColor: '#F1F1FA',
      borderRadius: 10,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingHorizontal: width * 0.03,
      alignSelf: 'center',
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
      color: '#161719',
    },
    searchIcon: {
      width: width * 0.05,
      height: width * 0.05,
    },
    categoryContainer: {
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'flex-start',
      paddingHorizontal: width * 0.05,
      marginVertical: height * 0.02,
      width: width,
    },
    categoryTitle: {
      fontSize: sizes.title,
      fontWeight: 'bold',
      color: theme.primaryText,
      marginBottom: width * 0.02,
    },
    categoryList: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      flexWrap: 'wrap',
      width: width - 100,
    },
    categoryItem: {
      width: width * 0.2,
      height: height * 0.05,
      backgroundColor: theme.searchCategory,
      borderRadius: 10,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: width * 0.03,
      marginVertical: height * 0.01,
      alignSelf: 'center',
    },
    categoryItemText: {
      fontSize: sizes.subtitle,
      fontWeight: 'bold',
      color: '#F1F1FA',
      textAlign: 'center',
    },
    containerText: {
      color: 'white',
      fontWeight: 'bold',
      backgroundColor: 'rgba(255, 255, 255, 0.17)',
      width: width * 0.05,
      height: width * 0.05,
      borderRadius: 2,
      position: 'absolute',
      justifyContent: 'center',
      alignItems: 'center',
      transform: [{rotate: '45deg'}],
    },
    containerBox: {
      backgroundColor: '#FF8181',
      width: height * 0.1,
      height: height * 0.1,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: 10,
      shadowColor: '#161719719',
    },
    subjectItem: {
      width: width * 0.9,
      height: height * 0.15,
      backgroundColor: '#F1F1FA',
      borderRadius: 10,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'flex-start',
      paddingHorizontal: height * 0.015,
      marginVertical: width * 0.02,
      alignSelf: 'center',
    },
    subjectItemTextContainer: {
      width: width * 0.65,
      height: height * 0.1,
      backgroundColor: '#F1F1FA',
      borderRadius: 10,
      flexDirection: 'column',
      alignItems: 'flex-start',
      justifyContent: 'space-around',
      paddingHorizontal: height * 0.015,
      marginVertical: width * 0.02,
      paddingVertical: height * 0.005,
      alignSelf: 'center',
    },
    subjectItemText: {
      fontSize: sizes.title,
      fontWeight: 'bold',
      color: theme.primaryText,
      textAlign: 'left',
    },
    subjectItemBranch: {
      fontSize: sizes.subtitle,
      fontWeight: 'bold',
      color: theme.primaryText,
      textAlign: 'center',
    },
    subjectItemBranchText: {
      fontSize: sizes.subtitle,
      fontWeight: '600',
      color: theme.primaryText,
      textAlign: 'center',
      paddingLeft: 5,
    },
    subjectItemSem: {
      fontSize: sizes.subtitle,
      fontWeight: 'bold',
      color: theme.primaryText,
      textAlign: 'center',
    },
    headerText: {
      fontSize: sizes.title,
      fontWeight: 'bold',
      color: theme.white,
      textAlign: 'center',
      paddingLeft: 5,
    },
    header: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    SignupButton: {
      marginTop: 20,
    },

    disabledIp: {
      width: width - 50,
      justifyContent: 'flex-start',
      alignItems: 'center',
      marginTop: height * 0.02,
      height: height * 0.07,
      backgroundColor: theme.quaternary,
      borderRadius: 10,
      elevation: 3,
      shadowColor: '#161719719',
      shadowOffset: {width: 0, height: 2},
      shadowOpacity: 0.8,
      shadowRadius: 2,
      flexDirection: 'row',
      paddingLeft: 20,
    },
  });

export default createStyles;
