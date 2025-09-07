import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { Picker } from '@react-native-picker/picker';
import { AppSettings, Language } from '../types';
import { StorageService } from '../services/storage';
import { NotificationService } from '../services/notificationService';
import i18n from '../locales/i18n';

const SettingsScreen: React.FC = () => {
  const { t } = useTranslation();
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSettings();
    NotificationService.initialize();
  }, []);

  const loadSettings = async () => {
    try {
      const loadedSettings = await StorageService.getSettings();
      setSettings(loadedSettings);
    } catch (error) {
      console.error('Error loading settings:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
    }
  };

  const handleLanguageChange = async (language: Language) => {
    if (!settings) return;
    
    try {
      await i18n.changeLanguage(language);
      const updatedSettings = { ...settings, language };
      setSettings(updatedSettings);
      await StorageService.saveSettings(updatedSettings);
    } catch (error) {
      console.error('Error changing language:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    }
  };

  const handleNotificationsToggle = async (value: boolean) => {
    if (!settings) return;

    try {
      const updatedSettings = { ...settings, notificationsEnabled: value };
      setSettings(updatedSettings);
      await StorageService.saveSettings(updatedSettings);

      if (value) {
        await NotificationService.initialize();
        // Reschedule all reminders
        const children = await StorageService.getChildren();
        for (const child of children) {
          await NotificationService.scheduleAllReminders(child);
        }
      } else {
        // Cancel all notifications
        const children = await StorageService.getChildren();
        for (const child of children) {
          await NotificationService.cancelChildReminders(child.id);
        }
      }
    } catch (error) {
      console.error('Error toggling notifications:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    }
  };

  const handleShowRecommendedToggle = async (value: boolean) => {
    if (!settings) return;

    try {
      const updatedSettings = { ...settings, showRecommendedVaccines: value };
      setSettings(updatedSettings);
      await StorageService.saveSettings(updatedSettings);
    } catch (error) {
      console.error('Error toggling recommended vaccines:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    }
  };

  const handleReminderDaysChange = async (days: number) => {
    if (!settings) return;

    try {
      const updatedSettings = { ...settings, reminderDaysBefore: days };
      setSettings(updatedSettings);
      await StorageService.saveSettings(updatedSettings);

      // Reschedule all reminders with new timing
      if (settings.notificationsEnabled) {
        const children = await StorageService.getChildren();
        for (const child of children) {
          await NotificationService.cancelChildReminders(child.id);
          await NotificationService.scheduleAllReminders(child);
        }
      }
    } catch (error) {
      console.error('Error changing reminder days:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    }
  };

  const handleDeleteAllData = () => {
    Alert.alert(
      t('settings.deleteAllData'),
      t('settings.deleteWarning'),
      [
        { text: t('common.cancel'), style: 'cancel' },
        {
          text: t('common.delete'),
          style: 'destructive',
          onPress: async () => {
            try {
              await StorageService.clearAllData();
              Alert.alert(t('common.success'), 'All data has been deleted');
              loadSettings();
            } catch (error) {
              console.error('Error deleting data:', error);
              Alert.alert(t('errors.general'), t('errors.saveError'));
            }
          },
        },
      ]
    );
  };

  if (loading || !settings) {
    return (
      <View style={styles.centerContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('settings.language')}</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={settings.language}
            onValueChange={(value) => handleLanguageChange(value as Language)}
            style={styles.picker}
          >
            <Picker.Item label="English" value="en" />
            {/* Add more languages when translations are available */}
            {/* <Picker.Item label="中文" value="zh" />
            <Picker.Item label="Русский" value="ru" />
            <Picker.Item label="Español" value="es" />
            <Picker.Item label="Türkçe" value="tr" />
            <Picker.Item label="Українська" value="uk" /> */}
          </Picker>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('settings.notifications')}</Text>
        
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>{t('settings.enableNotifications')}</Text>
            <Text style={styles.settingDescription}>
              Receive reminders for upcoming vaccinations
            </Text>
          </View>
          <Switch
            value={settings.notificationsEnabled}
            onValueChange={handleNotificationsToggle}
            trackColor={{ false: '#ccc', true: '#81C784' }}
            thumbColor={settings.notificationsEnabled ? '#4CAF50' : '#f4f3f4'}
          />
        </View>

        {settings.notificationsEnabled && (
          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>{t('settings.reminderDays')}</Text>
              <Text style={styles.settingDescription}>
                How many days before vaccination to remind
              </Text>
            </View>
            <View style={styles.daysSelector}>
              <TouchableOpacity
                style={styles.dayButton}
                onPress={() => handleReminderDaysChange(Math.max(1, settings.reminderDaysBefore - 1))}
              >
                <Icon name="remove" size={20} color="#666" />
              </TouchableOpacity>
              <Text style={styles.daysText}>{settings.reminderDaysBefore}</Text>
              <TouchableOpacity
                style={styles.dayButton}
                onPress={() => handleReminderDaysChange(Math.min(30, settings.reminderDaysBefore + 1))}
              >
                <Icon name="add" size={20} color="#666" />
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Vaccines</Text>
        
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>{t('settings.showRecommended')}</Text>
            <Text style={styles.settingDescription}>
              Include recommended vaccines in schedules
            </Text>
          </View>
          <Switch
            value={settings.showRecommendedVaccines}
            onValueChange={handleShowRecommendedToggle}
            trackColor={{ false: '#ccc', true: '#81C784' }}
            thumbColor={settings.showRecommendedVaccines ? '#4CAF50' : '#f4f3f4'}
          />
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Data Management</Text>
        
        <TouchableOpacity style={styles.dangerButton} onPress={handleDeleteAllData}>
          <Icon name="delete-forever" size={20} color="#f44336" />
          <Text style={styles.dangerButtonText}>{t('settings.deleteAllData')}</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('settings.about')}</Text>
        
        <View style={styles.aboutRow}>
          <Text style={styles.aboutLabel}>{t('settings.version')}</Text>
          <Text style={styles.aboutValue}>1.0.0</Text>
        </View>
        
        <TouchableOpacity style={styles.aboutRow}>
          <Text style={styles.aboutLabel}>{t('settings.privacyPolicy')}</Text>
          <Icon name="chevron-right" size={20} color="#999" />
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.aboutRow}>
          <Text style={styles.aboutLabel}>{t('settings.termsOfService')}</Text>
          <Icon name="chevron-right" size={20} color="#999" />
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  section: {
    backgroundColor: '#fff',
    marginBottom: 10,
    padding: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2196F3',
    marginBottom: 15,
    textTransform: 'uppercase',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  settingInfo: {
    flex: 1,
    marginRight: 10,
  },
  settingLabel: {
    fontSize: 16,
    color: '#333',
    marginBottom: 4,
  },
  settingDescription: {
    fontSize: 13,
    color: '#666',
  },
  pickerContainer: {
    backgroundColor: '#f8f8f8',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    overflow: 'hidden',
  },
  picker: {
    height: 50,
  },
  daysSelector: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dayButton: {
    padding: 8,
    backgroundColor: '#f0f0f0',
    borderRadius: 20,
  },
  daysText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginHorizontal: 15,
    minWidth: 30,
    textAlign: 'center',
  },
  dangerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 15,
    backgroundColor: '#ffebee',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ffcdd2',
  },
  dangerButtonText: {
    color: '#f44336',
    fontSize: 16,
    fontWeight: '500',
    marginLeft: 8,
  },
  aboutRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  aboutLabel: {
    fontSize: 14,
    color: '#333',
  },
  aboutValue: {
    fontSize: 14,
    color: '#666',
  },
});

export default SettingsScreen;