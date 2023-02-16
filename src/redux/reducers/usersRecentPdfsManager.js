import {createSlice} from '@reduxjs/toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const createUserDataSlice = createSlice({
  name: 'RecentsManagement',
  initialState: {
    RecentViews: [],
  },
  reducers: {
    userAddToRecentsStart: (state, action) => {
      if (state.RecentViews?.length > 0) {
        state.RecentViews = [action.payload, ...state.RecentViews];

        state.RecentViews = state.RecentViews.filter(
          (recents, index, self) =>
            index === self.findIndex(t => t.notesId === recents.notesId),
        );

        AsyncStorage.setItem(
          'RecentsManagement',
          JSON.stringify(state.RecentViews),
        );
      } else {
        state.RecentViews = [action.payload];
      }
    },

    userAddToRecents: (state, action) => {
      state.RecentViews = action.payload;
    },
    userRemoveFromRecents: (state, action) => {
      //renmove the bookmark from the array
      state.RecentViews = state.RecentViews.filter(
        recents => recents.notesId !== action.payload.notesId,
      );
      AsyncStorage.setItem(
        'RecentsManagement',
        JSON.stringify(state.RecentViews),
      );
    },
    userClearRecents: (state, action) => {
      state.RecentViews = [];
      AsyncStorage.setItem(
        'RecentsManagement',
        JSON.stringify(state.RecentViews),
      );
    },
  },
});

export const {
  userAddToRecentsStart,
  userAddToRecents,
  userRemoveFromRecents,
  userClearRecents,
} = createUserDataSlice.actions;

export default createUserDataSlice.reducer;