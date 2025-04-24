import storage from '@react-native-firebase/storage';
import { Actionsheet, Box, Card, Center, Checkbox, Icon, IconButton, Modal, Stack, Text, useDisclose } from 'native-base';
import React, { useMemo, useState } from 'react';
import { ActivityIndicator, StyleSheet, TouchableOpacity, View } from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Ionicons from 'react-native-vector-icons/Ionicons';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';
import { useDispatch, useSelector } from 'react-redux';

import { ReportIconBlack } from '../../assets/images/images';
import UserRequestsActions from '../../screens/UserRequests/UserRequestsActions';
import EditUploadsForm from '../../sections/EditUploadsForm/EditUploadsForm';
import NavigationService from '../../services/NavigationService';
import createStyles from './styles';

const   NewRequestCard = ({ item }: any) => {
    const { isOpen, onOpen, onClose } = useDisclose();
    const theme = useSelector((state: any) => state.theme);
    const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);

    const dispatch: any = useDispatch();
    const [loading, setLoading] = useState(false);
    const [approvalModalVisible, setApprovalModalVisible] = React.useState(false);
    const [rejectionModalVisible, setRejectionModalVisible] = React.useState(false);
    const [openForm, setOpenForm] = useState(false);
    const [checked1, setChecked1] = useState(false);
    const [checked2, setChecked2] = useState(false);
    const [checked3, setChecked3] = useState(false);
    const userFirestoreData = useSelector((state: any) => state.usersData).usersData;
    const userInfo: any = useSelector((state: any) => state.bootReducer.userInfo);
    const dynamicLink = useSelector((state: any) => state?.bootReducer?.utilis?.dynamicLink);
    const [submitted, setSubmitted] = useState(false);
    const customClaims = useSelector((state: any) => state.bootReducer.customClaims);
    const managerUniversity = customClaims?.branchManagerDetails?.university;
    const managerCourse = customClaims?.branchManagerDetails?.course;
    const managerBranch = customClaims?.branchManagerDetails?.branches;
    const data = {
        storageId: item?.storageId,
        path: item?.path,
        university: item?.university,
        course: item?.course,
        branch: item?.branch,
        sem: item?.sem,
        subject: item?.subject,
        category: item?.category,
        name: item?.name,
        units: item?.units || "",
        uploaderName: item?.uploaderName || "",
        uploaderId: item?.uploaderId || "",
        uploaderEmail: item?.uploaderEmail,
        status: "unverified",
        verifiedBy: userFirestoreData?.name,
        verifiedByUid: userInfo?.uid,
        verifiedByEmail: userFirestoreData?.email,
        notesId: item?.notesId,
        userPfp: item?.pfp || null,
    }

    const [editedData, setEditedData] = useState(data);

    const handleRefresh = () => {
        dispatch(UserRequestsActions.loadNewUploads(managerUniversity, managerCourse, managerBranch))
        setLoading(false);
    }; 

    const credentials = {
        notesPath: item?.path,
        bucketName: "academic-ally",
    }

    const getDownloadUrl = async (filePath: any) => {
        try {
            const reference = storage().ref(filePath);
            const downloadUrl = await reference.getDownloadURL();
            return downloadUrl;
        } catch (error) {
            console.error('Error retrieving:', error);
        }
    };

    const approved = () => {
        getDownloadUrl(item?.path).then(async (url) => {
            try {
                // First proceed with the approval
                await dispatch((UserRequestsActions as any).acceptRequest(editedData, url, credentials, handleRefresh, dynamicLink));
                
                // After successful approval, send notification
                const notificationPayload = {
                    topic: `${item.university}_${item.course}_${item.branch}_${item.sem}`,
                    // topic: "Testing123",
                    subjectName: item.subject,
                    resourceType: item.category,
                    userId: item.uploaderId,
                    resourceTitle: item.name
                };
                await fetch('https://academicallyapp.netlify.app/.netlify/functions/notifications/resource-accepted', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(notificationPayload)
                });

                setApprovalModalVisible(false);
            } catch (error) {
                console.error('Error:', error);
                setApprovalModalVisible(false);
            }
        })
    }

    const rejected = () => {
        setLoading(true)
        dispatch((UserRequestsActions as any).rejectRequest(data, handleRefresh, userInfo)).then(() => {
            setRejectionModalVisible(false);
        });
    }


    return (
        <>
            <View style={styles.notesContainer}>
                {
                    loading &&
                    <View style={styles.loader}>
                        <ActivityIndicator size="large" color={theme.colors.primaryText} />
                    </View>
                }
                <View style={styles.reccomendationStyle}>
                    <TouchableOpacity
                        style={styles.subjectContainer}
                        onPress={() => {
                            getDownloadUrl(item?.path).then((url) => {
                                NavigationService.navigate('UserRequestsPdfViewer', {
                                    item: url,
                                });
                            })
                        }}>
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
                                {(editedData?.subject)?.substring(0, 20)}
                            </Text>
                            <Text
                                style={{
                                    fontSize: theme.sizes.subtitle,
                                    color: theme.colors.primaryText,
                                    fontWeight: '400',
                                }}>
                                {(editedData?.category).charAt(0).toUpperCase() + (editedData?.category).slice(1)}
                            </Text>
                            <Text
                                style={{
                                    fontSize: theme.sizes.subtitle,
                                    color: item.units === "" ? theme.colors.textSecondary : theme.colors.primaryText,
                                    fontWeight: '400',
                                }}>
                                {editedData?.units === "" ? "Units: Unknown" : data?.units + " Units"}
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
                                    }}>
                                    <Text style={{
                                        fontSize: theme.sizes.subtitle,
                                        color: theme.colors.primaryText,
                                        fontWeight: '600',
                                    }}>|</Text>
                                    <Text
                                        style={{
                                            fontSize: theme.sizes.subtitle,
                                            color: theme.colors.primaryText,
                                            fontWeight: '600',
                                            paddingHorizontal: theme.sizes.width * 0.01,
                                        }}>
                                        {editedData?.university}
                                    </Text>
                                </View>
                                <View
                                    style={{
                                        flexDirection: 'row',
                                        alignItems: 'center',
                                        justifyContent: 'space-between',
                                    }}>
                                    <Text style={{
                                        fontSize: theme.sizes.subtitle,
                                        color: theme.colors.primaryText,
                                        fontWeight: '600',
                                    }}>|</Text>
                                    <Text
                                        style={{
                                            fontSize: 14,
                                            color: item.rating < 1 ? theme.colors.textSecondary : theme.colors.primaryText,
                                            fontWeight: '600',
                                            paddingHorizontal: theme.sizes.width * 0.01,
                                        }}>
                                        {editedData?.course}
                                    </Text>
                                    <Text style={{
                                        fontSize: theme.sizes.subtitle,
                                        color: theme.colors.primaryText,
                                        fontWeight: '600',
                                    }}>|</Text>
                                </View>
                                <View
                                    style={{
                                        flexDirection: 'row',
                                        alignItems: 'center',
                                        justifyContent: 'space-between',
                                    }}>
                                    <Text
                                        style={{
                                            fontSize: 14,
                                            color: theme.colors.textSecondary,
                                            fontWeight: '400',
                                            alignItems: 'center',
                                            paddingHorizontal: theme.sizes.width * 0.01,
                                        }}>
                                        {editedData?.branch}
                                    </Text>
                                    <Text style={{
                                        fontSize: theme.sizes.subtitle,
                                        color: theme.colors.primaryText,
                                        fontWeight: '600',
                                    }}>|</Text>
                                </View>
                                <View
                                    style={{
                                        flexDirection: 'row',
                                        alignItems: 'center',
                                        justifyContent: 'space-between',
                                    }}>
                                    <Text
                                        style={{
                                            fontSize: 14,
                                            color: theme.colors.textSecondary,
                                            fontWeight: '400',
                                            alignItems: 'center',
                                            paddingHorizontal: theme.sizes.width * 0.01,
                                        }}>
                                        Sem: {editedData?.sem}
                                    </Text>
                                    <Text style={{
                                        fontSize: theme.sizes.subtitle,
                                        color: theme.colors.primaryText,
                                        fontWeight: '600',
                                    }}>|</Text>
                                </View>
                            </View>
                        </View>
                    </TouchableOpacity>
                </View>
                <View style={styles.cardOptions}>
                    <TouchableOpacity
                        onPress={() => {
                            setApprovalModalVisible(true);
                        }}
                        style={[styles.cardOptionContainer, {
                            paddingLeft: 8,
                        }]} >
                        <Text style={styles.cardOptionText}>Approve</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => {
                        setRejectionModalVisible(true);
                    }} style={[styles.cardOptionContainer]} >
                        <Text style={styles.cardOptionText}>Disapprove</Text>
                    </TouchableOpacity>
                    <TouchableOpacity style={[styles.cardOptionContainer]} >
                        <Text style={styles.cardOptionText}>Contact</Text>
                    </TouchableOpacity>
                </View>
                <View style={{
                    position: "absolute",
                    top: 4,
                    right: 4,
                    zIndex: 99,
                }}>
                    <IconButton
                        borderRadius={'full'}
                        _hover={{
                            bg: theme.colors.primary,
                        }}
                        variant="ghost"
                        icon={<Icon as={MaterialCommunityIcons} name="square-edit-outline" size="md" color={theme.colors.mainTheme} />}
                        onPress={() => {
                            setOpenForm(true);
                        }}
                    />
                </View>

                <EditUploadsForm isOpen={openForm} onClose={() => {
                    setOpenForm(false);
                }} data={data} approve={() => {
                    setApprovalModalVisible(true);
                }}
                    setEditedData={setEditedData}
                />
                <Modal isOpen={approvalModalVisible} onClose={() => {
                    setApprovalModalVisible(false);
                }} size={'md'}>
                    <Modal.Content >
                        <Box margin={2} >
                            <Text fontSize={'14px'} fontWeight={'700'} marginTop={3} marginX={3} textAlign="center" >
                                Are you sure you want to approve this resource?
                            </Text>
                            <Stack direction="row" space={2} marginY={5} alignItems="center" justifyContent="space-evenly" >
                                <TouchableOpacity onPress={() => {
                                    setApprovalModalVisible(false);
                                }} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.textTertiary} >
                                        Cancel
                                    </Text>
                                </TouchableOpacity>
                                <TouchableOpacity style={{
                                    backgroundColor: theme.colors.primary,
                                    borderRadius: 10,
                                    paddingHorizontal: theme.sizes.width * 0.06,
                                    paddingVertical: 10,
                                }} onPress={approved} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={"#F1F1FA"} onPress={approved} >
                                        Approve
                                    </Text>
                                </TouchableOpacity>

                            </Stack>
                        </Box>
                    </Modal.Content>
                </Modal>
                <Modal isOpen={rejectionModalVisible} onClose={() => {
                    setRejectionModalVisible(false);
                }} size={'xl'} >
                    <Modal.Content >
                        <Box margin={2} >
                            <Text fontSize={'14px'} fontWeight={'700'} marginTop={3} marginX={3} textAlign="center" >
                                Are you sure you want to reject this resource?
                            </Text>
                            <Stack direction="row" space={2} marginY={5} alignItems="center" justifyContent="space-evenly" >
                                <TouchableOpacity onPress={() => {
                                    setRejectionModalVisible(false);
                                }} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.textTertiary} >
                                        Cancel
                                    </Text>
                                </TouchableOpacity>
                                <TouchableOpacity style={{
                                    backgroundColor: theme.colors.primary,
                                    borderRadius: 10,
                                    paddingHorizontal: theme.sizes.width * 0.06,
                                    paddingVertical: 10,
                                }} onPress={rejected}>
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={"#F1F1FA"} onPress={rejected} >
                                        Disapprove
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
                                            backgroundColor: theme.colors.quaternary,
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
                                                <Text fontSize={theme.sizes.subtitle} color={theme.colors.primaryText} fontWeight={700} paddingLeft={4} width={'95%'} >
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
                                                <Text fontSize={theme.sizes.subtitle} color={theme.colors.primaryText} fontWeight={700} paddingLeft={4} width={'95%'} >
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
                                                <Text fontSize={theme.sizes.subtitle} color={theme.colors.primaryText} fontWeight={700} paddingLeft={4} width={"92%"}>
                                                    Spam: This file contains content other than notes and resources.
                                                </Text>
                                            </Checkbox>
                                        </Actionsheet.Item>
                                    </Box>
                                    <Box w="100%" h={theme.sizes.height * 0.08} px={4} my={0} justifyContent="center" alignItems={"center"} >
                                        <Text fontSize={theme.sizes.subtitle} mt={-6} color={theme.colors.primary} fontWeight={700} onPress={() => {
                                        }} >
                                            Reason not listed here? Write to Us
                                        </Text>
                                    </Box>
                                    <Stack direction="row" space={2} marginY={0} paddingX={5} alignItems="center" justifyContent="space-evenly" width={"100%"} >
                                        <TouchableOpacity onPress={onClose} >
                                            <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.textSecondary} >
                                                Cancel
                                            </Text>
                                        </TouchableOpacity>
                                        <TouchableOpacity style={{
                                            backgroundColor: theme.colors.primary,
                                            borderRadius: 10,
                                            paddingHorizontal: theme.sizes.width * 0.05,
                                            paddingVertical: 10,
                                        }} onPress={() => { }} >
                                            <Text fontSize={theme.sizes.title} fontWeight={'700'} textAlign="center" color={theme.colors.quaternary} >
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
            </View >
        </>
    );
};

export default NewRequestCard;

const styles = StyleSheet.create({});
