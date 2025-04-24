import React, { createContext, useContext, useState, useCallback } from 'react';
import NotificationToast from '../components/NotificationToast';

const NotificationContext = createContext({
  showNotification: () => {},
});

export const useNotification = () => useContext(NotificationContext);

export const NotificationProvider = ({ children }) => {
  const [notification, setNotification] = useState(null);

  const showNotification = useCallback(
    ({ title, message, type = 'default', duration = 3000, onPress }) => {
      setNotification({
        title,
        message,
        type,
        duration,
        onPress,
      });
    },
    [],
  );

  const hideNotification = useCallback(() => {
    setNotification(null);
  }, []);

  return (
    <NotificationContext.Provider value={{ showNotification }}>
      {children}
      {notification && (
        <NotificationToast
          {...notification}
          onHide={hideNotification}
        />
      )}
    </NotificationContext.Provider>
  );
};

export default NotificationContext; 