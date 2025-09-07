import AsyncStorage from '@react-native-async-storage/async-storage';
import { Child, VaccinationRecord, Reminder, AppSettings } from '../types';

const STORAGE_KEYS = {
  CHILDREN: '@VaccineTracker:children',
  VACCINATION_RECORDS: '@VaccineTracker:vaccinationRecords',
  REMINDERS: '@VaccineTracker:reminders',
  SETTINGS: '@VaccineTracker:settings',
};

export class StorageService {
  // Children
  static async getChildren(): Promise<Child[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.CHILDREN);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('Error loading children:', error);
      return [];
    }
  }

  static async saveChildren(children: Child[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.CHILDREN, JSON.stringify(children));
    } catch (error) {
      console.error('Error saving children:', error);
      throw error;
    }
  }

  static async addChild(child: Child): Promise<void> {
    const children = await this.getChildren();
    children.push(child);
    await this.saveChildren(children);
  }

  static async updateChild(childId: string, updates: Partial<Child>): Promise<void> {
    const children = await this.getChildren();
    const index = children.findIndex(c => c.id === childId);
    if (index !== -1) {
      children[index] = { ...children[index], ...updates, updatedAt: new Date().toISOString() };
      await this.saveChildren(children);
    }
  }

  static async deleteChild(childId: string): Promise<void> {
    const children = await this.getChildren();
    const filtered = children.filter(c => c.id !== childId);
    await this.saveChildren(filtered);
    
    // Also delete related vaccination records and reminders
    const records = await this.getVaccinationRecords();
    const filteredRecords = records.filter(r => r.childId !== childId);
    await this.saveVaccinationRecords(filteredRecords);
    
    const reminders = await this.getReminders();
    const filteredReminders = reminders.filter(r => r.childId !== childId);
    await this.saveReminders(filteredReminders);
  }

  // Vaccination Records
  static async getVaccinationRecords(): Promise<VaccinationRecord[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.VACCINATION_RECORDS);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('Error loading vaccination records:', error);
      return [];
    }
  }

  static async saveVaccinationRecords(records: VaccinationRecord[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.VACCINATION_RECORDS, JSON.stringify(records));
    } catch (error) {
      console.error('Error saving vaccination records:', error);
      throw error;
    }
  }

  static async addVaccinationRecord(record: VaccinationRecord): Promise<void> {
    const records = await this.getVaccinationRecords();
    records.push(record);
    await this.saveVaccinationRecords(records);
  }

  static async updateVaccinationRecord(recordId: string, updates: Partial<VaccinationRecord>): Promise<void> {
    const records = await this.getVaccinationRecords();
    const index = records.findIndex(r => r.id === recordId);
    if (index !== -1) {
      records[index] = { ...records[index], ...updates, updatedAt: new Date().toISOString() };
      await this.saveVaccinationRecords(records);
    }
  }

  static async getChildVaccinationRecords(childId: string): Promise<VaccinationRecord[]> {
    const records = await this.getVaccinationRecords();
    return records.filter(r => r.childId === childId);
  }

  // Reminders
  static async getReminders(): Promise<Reminder[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.REMINDERS);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('Error loading reminders:', error);
      return [];
    }
  }

  static async saveReminders(reminders: Reminder[]): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.REMINDERS, JSON.stringify(reminders));
    } catch (error) {
      console.error('Error saving reminders:', error);
      throw error;
    }
  }

  static async addReminder(reminder: Reminder): Promise<void> {
    const reminders = await this.getReminders();
    reminders.push(reminder);
    await this.saveReminders(reminders);
  }

  static async updateReminder(reminderId: string, updates: Partial<Reminder>): Promise<void> {
    const reminders = await this.getReminders();
    const index = reminders.findIndex(r => r.id === reminderId);
    if (index !== -1) {
      reminders[index] = { ...reminders[index], ...updates };
      await this.saveReminders(reminders);
    }
  }

  // Settings
  static async getSettings(): Promise<AppSettings> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.SETTINGS);
      return data ? JSON.parse(data) : this.getDefaultSettings();
    } catch (error) {
      console.error('Error loading settings:', error);
      return this.getDefaultSettings();
    }
  }

  static async saveSettings(settings: AppSettings): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
    } catch (error) {
      console.error('Error saving settings:', error);
      throw error;
    }
  }

  static async updateSettings(updates: Partial<AppSettings>): Promise<void> {
    const settings = await this.getSettings();
    const updated = { ...settings, ...updates };
    await this.saveSettings(updated);
  }

  static getDefaultSettings(): AppSettings {
    return {
      language: 'en',
      showRecommendedVaccines: false,
      notificationsEnabled: true,
      reminderDaysBefore: 7,
    };
  }

  // Clear all data
  static async clearAllData(): Promise<void> {
    try {
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.CHILDREN,
        STORAGE_KEYS.VACCINATION_RECORDS,
        STORAGE_KEYS.REMINDERS,
        STORAGE_KEYS.SETTINGS,
      ]);
    } catch (error) {
      console.error('Error clearing data:', error);
      throw error;
    }
  }
}