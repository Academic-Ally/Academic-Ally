import { createAsyncThunk } from '@reduxjs/toolkit';
import firestore from '@react-native-firebase/firestore';

export const loadNewUploads = createAsyncThunk(
    'userRequests/loadNewUploads',
    async (params: { university: string; course: string; branches: string[] }) => {
        const { university, course, branches } = params;
        const snapshot = await firestore()
            .collection('uploads')
            .where('university', '==', university)
            .where('course', '==', course)
            .where('branch', 'in', branches)
            .where('status', '==', 'pending')
            .get();

        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    }
);

export const approveUpload = createAsyncThunk(
    'userRequests/approveUpload',
    async (requestId: string) => {
        await firestore()
            .collection('uploads')
            .doc(requestId)
            .update({
                status: 'approved',
                approvedAt: firestore.FieldValue.serverTimestamp()
            });
        return requestId;
    }
);

export const rejectUpload = createAsyncThunk(
    'userRequests/rejectUpload',
    async (requestId: string) => {
        await firestore()
            .collection('uploads')
            .doc(requestId)
            .update({
                status: 'rejected',
                rejectedAt: firestore.FieldValue.serverTimestamp()
            });
        return requestId;
    }
);

const UserRequestsActions = {
    loadNewUploads,
    approveUpload,
    rejectUpload
};

export default UserRequestsActions; 