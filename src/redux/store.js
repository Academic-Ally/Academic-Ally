import { configureStore } from '@reduxjs/toolkit';
import usersDataReducer from './reducers/usersData';
import userBookmarkManagementReducer from './reducers/userBookmarkManagement';
import userRecentViewsManagementReducer from './reducers/usersRecentPdfsManager';
import SubjectsList from './reducers/subjectsList';
import userState from './reducers/userState';
import theme from './reducers/theme';

export default configureStore({
  reducer: {
    usersData: usersDataReducer,
    userBookmarkManagement: userBookmarkManagementReducer,
    userRecentPdfs: userRecentViewsManagementReducer,
    subjectsList: SubjectsList,
    userState: userState,
    theme: theme,
  },
});
