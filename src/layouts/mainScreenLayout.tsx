import { useNavigation } from '@react-navigation/native';
import { Icon, IconButton } from 'native-base';
import React, { useEffect, useMemo } from 'react';
import { Platform, SafeAreaView, StatusBar, Text, View } from 'react-native';
import Orientation from 'react-native-orientation-locker';
import Ionicons from 'react-native-vector-icons/Ionicons';
import { useSelector } from 'react-redux';

import RestrictedScreen from './restrictedScreen';
import createStyles from './styles';

interface Props {
    children?: React.ReactNode;
    rightIconFalse: boolean;
    title: string;
    handleScroll: (event: any) => void;
    name: any;
    handleShare?: () => void;
}

const MainScreenLayout = ({ children, rightIconFalse, title, handleScroll, name, handleShare }: Props) => {
    const navigation = useNavigation();
    const theme = useSelector((state: any) => state.theme);
    const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);

    useEffect(() => {
        if (name && name === "PdfViewer") {
            Orientation.unlockAllOrientations()
        }
        else {
            Orientation.lockToPortrait()
        }
    }, [])

    return (
        <RestrictedScreen>
            <SafeAreaView style={[styles.container, { backgroundColor: theme.colors.primary }]}>
                <View style={styles.headerContainer}>
                    <View style={{
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        width: '100%',
                        paddingHorizontal: 20,
                        paddingTop: Platform.OS === 'ios' ? 10 : 20,
                        paddingBottom: Platform.OS === 'ios' ? 10 : 0,
                        minHeight: Platform.OS === 'ios' ? 44 : 56
                    }} >
                        <StatusBar
                            translucent={Platform.OS === 'android'}
                            backgroundColor={theme.colors.primary}
                            barStyle={'light-content'}
                        />
                        <IconButton
                            borderRadius={'full'}
                            _hover={{
                                bg: '#D3D3D3',
                            }}
                            _pressed={{
                                bg: '#D3D3D3',
                            }}
                            onPress={() => { navigation.goBack() }}
                            variant="ghost"
                            icon={<Icon as={Ionicons} name="chevron-back-outline" size={'xl'} color={theme.colors.white} />}
                            p={0}
                        />
                        {title && (
                            <View style={styles.header}>
                                <Text style={[styles.headerText, Platform.OS === 'ios' ? { fontWeight: '600' } : null]}>{title}</Text>
                            </View>
                        )}
                        {!rightIconFalse && (
                            <IconButton
                                borderRadius={'full'}
                                _hover={{
                                    bg: '#D3D3D3',
                                }}
                                _pressed={{
                                    bg: '#D3D3D3',
                                }}
                                onPress={handleShare}
                                variant="ghost"
                                icon={<Icon as={Ionicons} name="md-share-social-outline" size={'xl'} color={theme.colors.white} />}
                                p={0}
                            />
                        )}
                        {rightIconFalse && (
                            <View style={{ width: 30 }} />
                        )}
                    </View>
                </View>
                <View style={styles.body}>
                    <View style={styles.bodyContent}>
                        {children}
                    </View>
                </View>
            </SafeAreaView>
        </RestrictedScreen>
    );
};

export default MainScreenLayout;
