import { StyleSheet } from "react-native";
import { Dimensions } from "react-native";

const { width, height } = Dimensions.get('window');
const createStyles = (theme:any, sizes:any) =>
    StyleSheet.create({
        header: {
            backgroundColor: theme.primary,
            height: height * 0.22,
            borderBottomLeftRadius: 30,
            borderBottomRightRadius: 30,
            paddingTop: height * 0.02,
            paddingHorizontal: width * 0.05,
            // elevation: 4,
            shadowColor: '#000',
            shadowOffset: { width: 0, height: 4 },
            shadowOpacity: 0.1,
            shadowRadius: 8,
            zIndex: 1,
        },
        userInfo: {
            flexDirection: "row",
            alignItems: "center",
            width: "100%",
            justifyContent: "space-between",
            // marginTop: heigh,
        },
        userImgContainer: {
            backgroundColor: "#F1F1FA",
            borderRadius: 50,
            elevation: 4,
            shadowColor: '#000',
            shadowOffset: { width: 0, height: 2 },
            shadowOpacity: 0.15,
            shadowRadius: 6,
            borderWidth: 1.5,
            borderColor: 'rgba(255, 255, 255, 0.9)',
        },
        userImg: {
            width: width * 0.15,
            height: width * 0.15,
            borderRadius: 50,
        },
        salutation: {
            color: "#F1F1FA",
            fontSize: sizes.title,
            fontWeight: "700",
            lineHeight: height * 0.04,
            textShadowColor: 'rgba(0, 0, 0, 0.1)',
            textShadowOffset: { width: 0, height: 1 },
            textShadowRadius: 2,
        },
        userName: {
            color: "#F1F1FA",
            fontSize: sizes.subtitle,
            fontWeight: "700",
            opacity: 0.9,
        },
        recommendedContainer: {
            marginTop: -height * 0.12,
            backgroundColor: theme.secondary,
            paddingTop: height * 0.12,
            borderTopLeftRadius: 30,
            borderTopRightRadius: 30,
            minHeight: height * 0.8,
            paddingBottom: height * 0.08,
            elevation: 5,
            shadowColor: '#000',
            shadowOffset: { width: 0, height: -3 },
            shadowOpacity: 0.1,
            shadowRadius: 6,
            zIndex: 0,
        },
        subContainer:{
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingHorizontal: width * 0.05,
            marginBottom: height * 0.02,
            marginTop: height * 0.02,
        },
        recommendedText: {
            color: theme.primaryText,
            lineHeight: height * 0.04,
            fontSize: sizes.title,
            fontWeight: '700',
            fontFamily: 'DM Sans',
            fontStyle: 'normal',
        }
    })

export default createStyles;