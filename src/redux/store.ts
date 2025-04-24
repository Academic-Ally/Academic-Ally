import { configureStore } from '@reduxjs/toolkit';
import UserRequestsReducer from './reducers/UserRequestsReducer';
import themeReducer from './reducers/themeReducer';
import bootReducer from './reducers/bootReducer';

const store = configureStore({
  reducer: {
    UserRequestsReducer,
    theme: themeReducer,
    bootReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store; 