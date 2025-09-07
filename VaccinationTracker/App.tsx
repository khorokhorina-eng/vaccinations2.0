import React, { useEffect } from 'react';
import { StatusBar } from 'react-native';
import { I18nextProvider } from 'react-i18next';
import i18n from './src/locales/i18n';
import AppNavigator from './src/navigation/AppNavigator';
import { NotificationService } from './src/services/notificationService';

const App: React.FC = () => {
  useEffect(() => {
    // Initialize notifications
    NotificationService.initialize();
    
    // Check for overdue vaccinations periodically
    const checkOverdue = () => {
      NotificationService.checkOverdueVaccinations();
    };
    
    // Check immediately and then every 24 hours
    checkOverdue();
    const interval = setInterval(checkOverdue, 24 * 60 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, []);

  return (
    <I18nextProvider i18n={i18n}>
      <StatusBar barStyle="light-content" backgroundColor="#2196F3" />
      <AppNavigator />
    </I18nextProvider>
  );
};

export default App;