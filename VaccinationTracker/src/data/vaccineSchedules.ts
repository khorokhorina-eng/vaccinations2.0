import { VaccinationSchedule, Country } from '../types';

// Common vaccines used across multiple countries
const commonVaccines = {
  BCG: { id: 'bcg', nameKey: 'vaccines.bcg', name: 'BCG (Tuberculosis)' },
  HepB: { id: 'hepb', nameKey: 'vaccines.hepb', name: 'Hepatitis B' },
  DTaP: { id: 'dtap', nameKey: 'vaccines.dtap', name: 'DTaP (Diphtheria, Tetanus, Pertussis)' },
  Polio: { id: 'polio', nameKey: 'vaccines.polio', name: 'Polio (IPV)' },
  Hib: { id: 'hib', nameKey: 'vaccines.hib', name: 'Haemophilus influenzae type b' },
  PCV: { id: 'pcv', nameKey: 'vaccines.pcv', name: 'Pneumococcal (PCV13)' },
  Rotavirus: { id: 'rotavirus', nameKey: 'vaccines.rotavirus', name: 'Rotavirus' },
  MMR: { id: 'mmr', nameKey: 'vaccines.mmr', name: 'MMR (Measles, Mumps, Rubella)' },
  Varicella: { id: 'varicella', nameKey: 'vaccines.varicella', name: 'Varicella (Chickenpox)' },
  HepA: { id: 'hepa', nameKey: 'vaccines.hepa', name: 'Hepatitis A' },
  MenACWY: { id: 'menacwy', nameKey: 'vaccines.menacwy', name: 'Meningococcal ACWY' },
  HPV: { id: 'hpv', nameKey: 'vaccines.hpv', name: 'Human Papillomavirus' },
  Influenza: { id: 'flu', nameKey: 'vaccines.flu', name: 'Influenza (Flu)' },
  COVID19: { id: 'covid19', nameKey: 'vaccines.covid19', name: 'COVID-19' },
};

export const vaccineSchedules: Record<Country, VaccinationSchedule> = {
  USA: {
    country: 'USA',
    vaccines: [
      // Birth
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 5 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'mandatory', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // 11-12 years
      { ...commonVaccines.MenACWY, ageInMonths: 132, type: 'mandatory', doses: 2 },
      { ...commonVaccines.HPV, ageInMonths: 132, type: 'recommended', doses: 2 },
      
      // Annual
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.COVID19, ageInMonths: 6, type: 'recommended', doses: 2 },
    ],
  },
  
  China: {
    country: 'China',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      
      // 3 months
      { ...commonVaccines.DTaP, ageInMonths: 3, type: 'mandatory', doses: 4 },
      
      // 8 months
      { ...commonVaccines.MMR, ageInMonths: 8, type: 'mandatory', doses: 2 },
      
      // 6 months
      { ...commonVaccines.HepA, ageInMonths: 18, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'recommended', doses: 4 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'recommended', doses: 3 },
    ],
  },
  
  Russia: {
    country: 'Russia',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 3 months
      { ...commonVaccines.DTaP, ageInMonths: 3, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Polio, ageInMonths: 3, type: 'mandatory', doses: 6 },
      { ...commonVaccines.Hib, ageInMonths: 3, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
    ],
  },
  
  Germany: {
    country: 'Germany',
    vaccines: [
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.HepB, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 11 months
      { ...commonVaccines.MMR, ageInMonths: 11, type: 'mandatory', doses: 2 },
      { ...commonVaccines.Varicella, ageInMonths: 11, type: 'mandatory', doses: 2 },
      { ...commonVaccines.MenACWY, ageInMonths: 12, type: 'mandatory', doses: 1 },
      
      // Recommended
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.HPV, ageInMonths: 108, type: 'recommended', doses: 2 },
    ],
  },
  
  France: {
    country: 'France',
    vaccines: [
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.HepB, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 5 months
      { ...commonVaccines.MenACWY, ageInMonths: 5, type: 'mandatory', doses: 2 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.HPV, ageInMonths: 132, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
    ],
  },
  
  Italy: {
    country: 'Italy',
    vaccines: [
      // 3 months
      { ...commonVaccines.DTaP, ageInMonths: 3, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Polio, ageInMonths: 3, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Hib, ageInMonths: 3, type: 'mandatory', doses: 3 },
      { ...commonVaccines.HepB, ageInMonths: 3, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 3, type: 'mandatory', doses: 3 },
      
      // 13 months
      { ...commonVaccines.MMR, ageInMonths: 13, type: 'mandatory', doses: 2 },
      { ...commonVaccines.Varicella, ageInMonths: 13, type: 'mandatory', doses: 2 },
      { ...commonVaccines.MenACWY, ageInMonths: 13, type: 'mandatory', doses: 1 },
      
      // Recommended
      { ...commonVaccines.Rotavirus, ageInMonths: 3, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.HPV, ageInMonths: 144, type: 'recommended', doses: 2 },
    ],
  },
  
  Brazil: {
    country: 'Brazil',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'mandatory', doses: 2 },
      
      // 3 months
      { ...commonVaccines.MenACWY, ageInMonths: 3, type: 'mandatory', doses: 2 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      { ...commonVaccines.Varicella, ageInMonths: 15, type: 'mandatory', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'mandatory', doses: 1 },
      
      // 9 months
      { id: 'yellowfever', nameKey: 'vaccines.yellowfever', name: 'Yellow Fever', ageInMonths: 9, type: 'mandatory', doses: 1 },
      
      // Recommended
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.HPV, ageInMonths: 108, type: 'recommended', doses: 2 },
    ],
  },
  
  Mexico: {
    country: 'Mexico',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 5 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.HPV, ageInMonths: 132, type: 'recommended', doses: 2 },
    ],
  },
  
  Argentina: {
    country: 'Argentina',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 3 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'mandatory', doses: 2 },
      
      // 3 months
      { ...commonVaccines.MenACWY, ageInMonths: 3, type: 'mandatory', doses: 2 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'mandatory', doses: 1 },
      { ...commonVaccines.Varicella, ageInMonths: 15, type: 'mandatory', doses: 1 },
      
      // Recommended
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.HPV, ageInMonths: 132, type: 'recommended', doses: 2 },
    ],
  },
  
  Turkey: {
    country: 'Turkey',
    vaccines: [
      // Birth
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 1 month
      { ...commonVaccines.BCG, ageInMonths: 1, type: 'mandatory', doses: 1 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 5 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepA, ageInMonths: 18, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
      { ...commonVaccines.MenACWY, ageInMonths: 12, type: 'recommended', doses: 1 },
    ],
  },
  
  Ukraine: {
    country: 'Ukraine',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 5 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
    ],
  },
  
  Uzbekistan: {
    country: 'Uzbekistan',
    vaccines: [
      // Birth
      { ...commonVaccines.BCG, ageInMonths: 0, type: 'mandatory', doses: 1 },
      { ...commonVaccines.HepB, ageInMonths: 0, type: 'mandatory', doses: 3 },
      
      // 2 months
      { ...commonVaccines.DTaP, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Polio, ageInMonths: 2, type: 'mandatory', doses: 4 },
      { ...commonVaccines.Hib, ageInMonths: 2, type: 'mandatory', doses: 3 },
      
      // 12 months
      { ...commonVaccines.MMR, ageInMonths: 12, type: 'mandatory', doses: 2 },
      
      // Recommended
      { ...commonVaccines.PCV, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Rotavirus, ageInMonths: 2, type: 'recommended', doses: 3 },
      { ...commonVaccines.Varicella, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.HepA, ageInMonths: 12, type: 'recommended', doses: 2 },
      { ...commonVaccines.Influenza, ageInMonths: 6, type: 'recommended', doses: 1 },
    ],
  },
};

export const getVaccineSchedule = (country: Country): VaccinationSchedule => {
  return vaccineSchedules[country];
};

export const getVaccineById = (country: Country, vaccineId: string) => {
  const schedule = vaccineSchedules[country];
  return schedule.vaccines.find(v => v.id === vaccineId);
};