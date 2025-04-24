import LottieView from 'lottie-react-native';
import React, { useEffect, useMemo, useState } from 'react';
import { FlatList, RefreshControl, Text, TouchableOpacity, View } from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';
import { useDispatch, useSelector } from 'react-redux';
import FontAwesome5 from 'react-native-vector-icons/FontAwesome5'
import { Avatar, Icon, HStack } from 'native-base';

import NewRequestCard from '../../components/notes/newRequestCard';
import createStyles from './styles';
import UserRequestsActions from '../UserRequests/UserRequestsActions';

const UserUploadRequestsScreen = () => {
    const dispatch = useDispatch();
    const [isRefreshing, setIsRefreshing] = useState(false);
    const UserRequests = useSelector((state: any) => state.UserRequestsReducer);
    const loadingRequests = useSelector((state: any) => state.UserRequestsReducer).loadingRequests;
    const theme = useSelector((state: any) => state.theme);
    const styles = useMemo(() => createStyles(theme.colors, theme.sizes), [theme]);
    const customClaims = useSelector((state: any) => state.bootReducer.customClaims);
    const managerUniversity = customClaims?.branchManagerDetails?.university;
    const managerCourse = customClaims?.branchManagerDetails?.course;
    const managerBranch = customClaims?.branchManagerDetails?.branches;

    const handleRefresh = () => {
        setIsRefreshing(true);
        // dispatch(UserRequestsActions.loadNewUploads(managerUniversity,
        //      managerCourse,
        //      managerBranch
        //fix linter error
        dispatch(UserRequestsActions.loadNewUploads(managerUniversity, managerCourse, managerBranch) as any).then(() => setIsRefreshing(false));
    };

    useEffect(() => {
        handleRefresh();
    }, [loadingRequests]);

    useEffect(() => {
        if (UserRequests.loading === false) {
            setIsRefreshing(false);
        }
    }, [UserRequests.loading]);

    const renderItem = ({ item, index }: { item: any, index: number }) => (
        <NewRequestCard item={item} index={index} />
    );
    return (
        <View style={styles.container}>
            <View style={styles.headerContainer}>
                <View style={styles.header}>
                    <MaterialCommunityIcons
                        name="clipboard-edit-outline"
                        size={theme.sizes.iconMedium}
                        color="#F1F1FA"
                    />
                    <Text style={styles.headerText}>Requests</Text>
                </View>
            </View>
            <View style={styles.body}>
                <FlatList
                    showsVerticalScrollIndicator={false}
                    data={UserRequests?.NewRequests}
                    renderItem={renderItem}
                    refreshControl={
                        <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
                    }

                    ListEmptyComponent={() => (
                        <View style={{
                            width: theme.sizes.width,
                            justifyContent: 'center',
                            alignItems: 'center',
                            marginTop: theme.sizes.height * 0.15,

                        }}>
                            <LottieView
                                style={{
                                    height: theme.sizes.lottieIconHeight,
                                    alignSelf: 'center',
                                }}
                                source={require('../../assets/lottie/NoBookMarks.json')}
                                autoPlay
                                loop
                            />
                            <Text style={{
                                fontSize: theme.sizes.title,
                                color: theme.colors.primaryText,
                                fontWeight: 'bold',
                            }}>No Requests</Text>
                        </View>
                    )}
                />
            </View>
        </View>
    );
};

export default UserUploadRequestsScreen;