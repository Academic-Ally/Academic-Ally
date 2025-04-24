import { Actionsheet, Box, Card, Center, Checkbox, Stack, Text } from 'native-base'
import React, { useState } from 'react'
import { Linking, StyleSheet, TouchableOpacity } from 'react-native'
import AntDesign from 'react-native-vector-icons/AntDesign'
import Ionicons from 'react-native-vector-icons/Ionicons'
import { useSelector } from 'react-redux'

import { submitReport } from '../../../services/fetch/index'

const ReportActionSheet = ({ isOpen, onClose, notesData }: any) => {
    const [checked1, setChecked1] = useState(false);
    const [checked2, setChecked2] = useState(false);
    const [checked3, setChecked3] = useState(false);
    const [submitted, setSubmitted] = useState(false);
    const theme = useSelector((state: any) => state.theme);

    const userFirestoreData = useSelector((state: any) => state.usersData);

    async function mail() {
        Linking.openURL(`mailto:academicly.app@gmail.com?body=Report for notes Id : ${notesData?.id}, ${notesData?.course} ${notesData?.branch}, Semester ${notesData.sem} ${(notesData?.category).charAt(0).toUpperCase() + (notesData?.category).slice(1)} of ${notesData?.subject}  `)
    }
    return (
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
                            <theme.light.reportIcon />
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
                                    // backgroundColor: theme.colors.quaternary,
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
                                        <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={'95%'} >
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
                                        <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={'95%'} >
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
                                        <Text fontSize={theme.sizes.subtitle} color={theme.colors.black} fontWeight={700} paddingLeft={4} width={"92%"}>
                                            Spam: This file contains content other than notes and resources.
                                        </Text>
                                    </Checkbox>
                                </Actionsheet.Item>
                            </Box>
                            <Box w="100%" h={theme.sizes.height * 0.08} px={4} my={0} justifyContent="center" alignItems={"center"} >
                                <Text fontSize={theme.sizes.subtitle} mt={-6} color={theme.colors.primary} fontWeight={700} onPress={() => {
                                    mail();
                                }} >
                                    Reason not listed here? Write to Us
                                </Text>
                            </Box>
                            <Stack direction="row" space={2} marginY={0} paddingX={5} alignItems="center" justifyContent="space-evenly" width={"100%"} >
                                <TouchableOpacity onPress={onClose} >
                                    <Text fontSize={theme.sizes.subtitle} fontWeight={'700'} textAlign="center" color={theme.colors.terinaryText} >
                                        Cancel
                                    </Text>
                                </TouchableOpacity>
                                <TouchableOpacity style={{
                                    backgroundColor: theme.colors.primary,
                                    borderRadius: 10,
                                    paddingHorizontal: theme.sizes.width * 0.05,
                                    paddingVertical: 10,
                                }} onPress={() => {
                                    submitReport(userFirestoreData?.usersData, {
                                        checked1,
                                        checked2,
                                        checked3,
                                    }, notesData);
                                    setSubmitted(true);
                                }} >
                                    <Text fontSize={theme.sizes.title} fontWeight={'700'} textAlign="center" color={theme.colors.white} >
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
    )
}

export default ReportActionSheet

const styles = StyleSheet.create({})