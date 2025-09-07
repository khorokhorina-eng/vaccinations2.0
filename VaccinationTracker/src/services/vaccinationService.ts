import moment from 'moment';
import { Child, Vaccine, VaccinationRecord, VaccinationStatus, Country } from '../types';
import { getVaccineSchedule } from '../data/vaccineSchedules';
import { StorageService } from './storage';

export class VaccinationService {
  /**
   * Calculate scheduled dates for all vaccines based on child's date of birth
   */
  static calculateScheduledDates(dateOfBirth: string, vaccines: Vaccine[]): Map<string, Date> {
    const scheduledDates = new Map<string, Date>();
    const birthDate = moment(dateOfBirth);

    vaccines.forEach(vaccine => {
      const scheduledDate = birthDate.clone().add(vaccine.ageInMonths, 'months');
      scheduledDates.set(vaccine.id, scheduledDate.toDate());
    });

    return scheduledDates;
  }

  /**
   * Determine vaccination status based on scheduled date and completion
   */
  static getVaccinationStatus(
    scheduledDate: Date,
    completedDate?: string
  ): VaccinationStatus {
    if (completedDate) {
      return 'completed';
    }

    const today = moment().startOf('day');
    const scheduled = moment(scheduledDate).startOf('day');

    if (scheduled.isAfter(today)) {
      return 'upcoming';
    } else {
      return 'overdue';
    }
  }

  /**
   * Create vaccination records for a child
   */
  static async createVaccinationRecordsForChild(child: Child): Promise<void> {
    const schedule = getVaccineSchedule(child.country);
    const settings = await StorageService.getSettings();
    
    // Filter vaccines based on settings
    const vaccines = settings.showRecommendedVaccines 
      ? schedule.vaccines 
      : schedule.vaccines.filter(v => v.type === 'mandatory');

    const scheduledDates = this.calculateScheduledDates(child.dateOfBirth, vaccines);
    const existingRecords = await StorageService.getChildVaccinationRecords(child.id);
    
    const newRecords: VaccinationRecord[] = [];

    vaccines.forEach(vaccine => {
      // Check if record already exists
      const exists = existingRecords.some(r => r.vaccineId === vaccine.id);
      if (!exists) {
        const scheduledDate = scheduledDates.get(vaccine.id);
        if (scheduledDate) {
          const record: VaccinationRecord = {
            id: `${child.id}_${vaccine.id}_${Date.now()}`,
            childId: child.id,
            vaccineId: vaccine.id,
            scheduledDate: scheduledDate.toISOString(),
            status: this.getVaccinationStatus(scheduledDate),
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };

          // Handle multi-dose vaccines
          if (vaccine.doses && vaccine.doses > 1) {
            for (let dose = 0; dose < vaccine.doses; dose++) {
              const doseDate = moment(scheduledDate)
                .add(dose * (vaccine.interval || 1), 'months')
                .toDate();
              
              const doseRecord: VaccinationRecord = {
                ...record,
                id: `${child.id}_${vaccine.id}_dose${dose + 1}_${Date.now()}`,
                scheduledDate: doseDate.toISOString(),
                status: this.getVaccinationStatus(doseDate),
              };
              newRecords.push(doseRecord);
            }
          } else {
            newRecords.push(record);
          }
        }
      }
    });

    // Save new records
    for (const record of newRecords) {
      await StorageService.addVaccinationRecord(record);
    }
  }

  /**
   * Mark a vaccination as completed
   */
  static async markVaccinationAsCompleted(
    recordId: string,
    completionData: {
      completedDate: string;
      notes?: string;
      doctorName?: string;
      location?: string;
      batchNumber?: string;
    }
  ): Promise<void> {
    await StorageService.updateVaccinationRecord(recordId, {
      ...completionData,
      status: 'completed',
    });
  }

  /**
   * Get upcoming vaccinations for a child
   */
  static async getUpcomingVaccinations(
    childId: string,
    daysAhead: number = 30
  ): Promise<VaccinationRecord[]> {
    const records = await StorageService.getChildVaccinationRecords(childId);
    const futureDate = moment().add(daysAhead, 'days');
    
    return records.filter(record => {
      if (record.status !== 'upcoming') return false;
      const scheduledDate = moment(record.scheduledDate);
      return scheduledDate.isBetween(moment(), futureDate);
    });
  }

  /**
   * Get overdue vaccinations for a child
   */
  static async getOverdueVaccinations(childId: string): Promise<VaccinationRecord[]> {
    const records = await StorageService.getChildVaccinationRecords(childId);
    return records.filter(record => record.status === 'overdue');
  }

  /**
   * Get completed vaccinations for a child
   */
  static async getCompletedVaccinations(childId: string): Promise<VaccinationRecord[]> {
    const records = await StorageService.getChildVaccinationRecords(childId);
    return records.filter(record => record.status === 'completed');
  }

  /**
   * Calculate child's age in months
   */
  static getChildAgeInMonths(dateOfBirth: string): number {
    return moment().diff(moment(dateOfBirth), 'months');
  }

  /**
   * Format age for display
   */
  static formatAge(dateOfBirth: string): string {
    const months = this.getChildAgeInMonths(dateOfBirth);
    
    if (months < 12) {
      return `${months} months`;
    } else {
      const years = Math.floor(months / 12);
      const remainingMonths = months % 12;
      if (remainingMonths === 0) {
        return `${years} year${years > 1 ? 's' : ''}`;
      } else {
        return `${years} year${years > 1 ? 's' : ''} ${remainingMonths} month${remainingMonths > 1 ? 's' : ''}`;
      }
    }
  }

  /**
   * Calculate days until vaccination
   */
  static getDaysUntilVaccination(scheduledDate: string): number {
    return moment(scheduledDate).diff(moment(), 'days');
  }

  /**
   * Format scheduled date for display
   */
  static formatScheduledDate(scheduledDate: string): string {
    const date = moment(scheduledDate);
    const today = moment();
    const tomorrow = moment().add(1, 'day');
    
    if (date.isSame(today, 'day')) {
      return 'Today';
    } else if (date.isSame(tomorrow, 'day')) {
      return 'Tomorrow';
    } else {
      return date.format('MMM DD, YYYY');
    }
  }
}