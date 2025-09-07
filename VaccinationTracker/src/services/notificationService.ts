import notifee, {
  AndroidImportance,
  AndroidColor,
  TriggerType,
  TimestampTrigger,
  RepeatFrequency,
} from '@notifee/react-native';
import moment from 'moment';
import { Child, VaccinationRecord, Reminder } from '../types';
import { StorageService } from './storage';
import { VaccinationService } from './vaccinationService';
import { getVaccineById } from '../data/vaccineSchedules';
import i18n from '../locales/i18n';

export class NotificationService {
  private static channelId = 'vaccination-reminders';

  /**
   * Initialize notification channel for Android
   */
  static async initialize(): Promise<void> {
    await notifee.requestPermission();

    // Create a channel for Android
    await notifee.createChannel({
      id: this.channelId,
      name: 'Vaccination Reminders',
      lights: false,
      vibration: true,
      importance: AndroidImportance.HIGH,
      sound: 'default',
    });
  }

  /**
   * Schedule a reminder notification
   */
  static async scheduleReminder(
    child: Child,
    vaccinationRecord: VaccinationRecord,
    daysBefore: number = 7
  ): Promise<string> {
    const vaccine = getVaccineById(child.country, vaccinationRecord.vaccineId);
    if (!vaccine) return '';

    const scheduledDate = moment(vaccinationRecord.scheduledDate);
    const reminderDate = scheduledDate.clone().subtract(daysBefore, 'days');
    
    // Don't schedule if the reminder date is in the past
    if (reminderDate.isBefore(moment())) {
      return '';
    }

    const trigger: TimestampTrigger = {
      type: TriggerType.TIMESTAMP,
      timestamp: reminderDate.toDate().getTime(),
    };

    const notificationId = await notifee.createTriggerNotification(
      {
        id: `${child.id}_${vaccinationRecord.id}`,
        title: i18n.t('reminders.title'),
        body: i18n.t('reminders.upcoming', {
          childName: child.name,
          vaccineName: i18n.t(`vaccines.${vaccine.nameKey.split('.')[1]}`),
          days: daysBefore,
        }),
        android: {
          channelId: this.channelId,
          smallIcon: 'ic_launcher',
          color: AndroidColor.BLUE,
          pressAction: {
            id: 'default',
            launchActivity: 'default',
          },
        },
        ios: {
          sound: 'default',
          categoryId: 'vaccination-reminder',
        },
        data: {
          childId: child.id,
          vaccineId: vaccinationRecord.vaccineId,
          recordId: vaccinationRecord.id,
        },
      },
      trigger
    );

    // Save reminder to storage
    const reminder: Reminder = {
      id: notificationId,
      childId: child.id,
      vaccineId: vaccinationRecord.vaccineId,
      reminderDate: reminderDate.toISOString(),
      isEnabled: true,
      notificationId,
    };
    await StorageService.addReminder(reminder);

    return notificationId;
  }

  /**
   * Schedule reminders for all upcoming vaccinations
   */
  static async scheduleAllReminders(child: Child): Promise<void> {
    const settings = await StorageService.getSettings();
    if (!settings.notificationsEnabled) return;

    const upcomingVaccinations = await VaccinationService.getUpcomingVaccinations(
      child.id,
      90 // Look 90 days ahead
    );

    for (const vaccination of upcomingVaccinations) {
      await this.scheduleReminder(child, vaccination, settings.reminderDaysBefore);
    }
  }

  /**
   * Cancel a specific reminder
   */
  static async cancelReminder(notificationId: string): Promise<void> {
    await notifee.cancelNotification(notificationId);
    
    // Update reminder in storage
    const reminders = await StorageService.getReminders();
    const reminder = reminders.find(r => r.notificationId === notificationId);
    if (reminder) {
      await StorageService.updateReminder(reminder.id, { isEnabled: false });
    }
  }

  /**
   * Cancel all reminders for a child
   */
  static async cancelChildReminders(childId: string): Promise<void> {
    const reminders = await StorageService.getReminders();
    const childReminders = reminders.filter(r => r.childId === childId);
    
    for (const reminder of childReminders) {
      if (reminder.notificationId) {
        await notifee.cancelNotification(reminder.notificationId);
      }
    }
  }

  /**
   * Show immediate notification for overdue vaccinations
   */
  static async showOverdueNotification(
    child: Child,
    vaccinationRecord: VaccinationRecord
  ): Promise<void> {
    const vaccine = getVaccineById(child.country, vaccinationRecord.vaccineId);
    if (!vaccine) return;

    const daysOverdue = Math.abs(
      VaccinationService.getDaysUntilVaccination(vaccinationRecord.scheduledDate)
    );

    await notifee.displayNotification({
      title: i18n.t('reminders.title'),
      body: i18n.t('reminders.overdue', {
        childName: child.name,
        vaccineName: i18n.t(`vaccines.${vaccine.nameKey.split('.')[1]}`),
        days: daysOverdue,
      }),
      android: {
        channelId: this.channelId,
        smallIcon: 'ic_launcher',
        color: AndroidColor.RED,
        importance: AndroidImportance.HIGH,
        pressAction: {
          id: 'default',
          launchActivity: 'default',
        },
      },
      ios: {
        sound: 'default',
        critical: true,
        criticalVolume: 0.8,
      },
      data: {
        childId: child.id,
        vaccineId: vaccinationRecord.vaccineId,
        recordId: vaccinationRecord.id,
      },
    });
  }

  /**
   * Check and show notifications for overdue vaccinations
   */
  static async checkOverdueVaccinations(): Promise<void> {
    const children = await StorageService.getChildren();
    
    for (const child of children) {
      const overdueVaccinations = await VaccinationService.getOverdueVaccinations(child.id);
      
      for (const vaccination of overdueVaccinations) {
        await this.showOverdueNotification(child, vaccination);
      }
    }
  }

  /**
   * Handle notification press
   */
  static async handleNotificationPress(notification: any): Promise<void> {
    const { childId, recordId } = notification.data || {};
    
    if (childId && recordId) {
      // Navigate to the specific vaccination record
      // This will be handled by the navigation service
      console.log('Navigate to vaccination record:', recordId);
    }
  }
}