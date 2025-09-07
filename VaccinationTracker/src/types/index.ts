export type Country = 
  | 'USA'
  | 'China'
  | 'Russia'
  | 'Germany'
  | 'France'
  | 'Italy'
  | 'Brazil'
  | 'Mexico'
  | 'Argentina'
  | 'Turkey'
  | 'Ukraine'
  | 'Uzbekistan';

export type Language = 'en' | 'zh' | 'ru' | 'es' | 'tr' | 'uk';

export type VaccinationStatus = 'upcoming' | 'overdue' | 'completed';

export type VaccineType = 'mandatory' | 'recommended';

export interface Vaccine {
  id: string;
  name: string;
  nameKey: string; // For localization
  ageInMonths: number; // Age when vaccine should be given
  type: VaccineType;
  doses?: number; // Number of doses required
  interval?: number; // Interval between doses in months
  description?: string;
  descriptionKey?: string; // For localization
}

export interface VaccinationSchedule {
  country: Country;
  vaccines: Vaccine[];
}

export interface Child {
  id: string;
  name: string;
  dateOfBirth: string; // ISO date string
  country: Country;
  photoUri?: string;
  createdAt: string;
  updatedAt: string;
}

export interface VaccinationRecord {
  id: string;
  childId: string;
  vaccineId: string;
  scheduledDate: string; // ISO date string
  completedDate?: string; // ISO date string
  status: VaccinationStatus;
  notes?: string;
  doctorName?: string;
  location?: string;
  batchNumber?: string;
  nextDoseDate?: string; // For multi-dose vaccines
  createdAt: string;
  updatedAt: string;
}

export interface Reminder {
  id: string;
  childId: string;
  vaccineId: string;
  reminderDate: string; // ISO date string
  isEnabled: boolean;
  notificationId?: string;
}

export interface AppSettings {
  language: Language;
  showRecommendedVaccines: boolean;
  notificationsEnabled: boolean;
  reminderDaysBefore: number; // Days before scheduled date to remind
}