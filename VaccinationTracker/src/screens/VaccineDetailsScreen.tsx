import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useRoute } from '@react-navigation/native';
import DatePicker from 'react-native-date-picker';
import Icon from 'react-native-vector-icons/MaterialIcons';
import moment from 'moment';
import { Child, VaccinationRecord } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';
import { getVaccineById } from '../data/vaccineSchedules';

const VaccineDetailsScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const route = useRoute();
  const { childId, vaccineId, recordId } = route.params as {
    childId: string;
    vaccineId: string;
    recordId?: string;
  };

  const [child, setChild] = useState<Child | null>(null);
  const [record, setRecord] = useState<VaccinationRecord | null>(null);
  const [completedDate, setCompletedDate] = useState(new Date());
  const [notes, setNotes] = useState('');
  const [doctorName, setDoctorName] = useState('');
  const [location, setLocation] = useState('');
  const [batchNumber, setBatchNumber] = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadData();
  }, [childId, recordId]);

  const loadData = async () => {
    try {
      const children = await StorageService.getChildren();
      const foundChild = children.find(c => c.id === childId);
      if (foundChild) {
        setChild(foundChild);
      }

      if (recordId) {
        const records = await StorageService.getVaccinationRecords();
        const foundRecord = records.find(r => r.id === recordId);
        if (foundRecord) {
          setRecord(foundRecord);
          if (foundRecord.completedDate) {
            setCompletedDate(new Date(foundRecord.completedDate));
            setNotes(foundRecord.notes || '');
            setDoctorName(foundRecord.doctorName || '');
            setLocation(foundRecord.location || '');
            setBatchNumber(foundRecord.batchNumber || '');
          }
        }
      }
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsCompleted = async () => {
    if (!record) return;

    setSaving(true);
    try {
      await VaccinationService.markVaccinationAsCompleted(record.id, {
        completedDate: completedDate.toISOString(),
        notes,
        doctorName,
        location,
        batchNumber,
      });

      Alert.alert(t('common.success'), t('vaccination.recordSuccess'));
      navigation.goBack();
    } catch (error) {
      console.error('Error saving vaccination:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    } finally {
      setSaving(false);
    }
  };

  if (loading || !child || !record) {
    return (
      <View style={styles.centerContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  const vaccine = getVaccineById(child.country, vaccineId);
  if (!vaccine) {
    return (
      <View style={styles.centerContainer}>
        <Text>Vaccine not found</Text>
      </View>
    );
  }

  const isCompleted = record.status === 'completed';
  const statusColor = {
    overdue: '#f44336',
    upcoming: '#2196F3',
    completed: '#4CAF50',
  }[record.status];

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={[styles.statusBadge, { backgroundColor: statusColor }]}>
          <Text style={styles.statusText}>{t(`schedule.${record.status}`)}</Text>
        </View>
        <Text style={styles.vaccineName}>
          {t(`vaccines.${vaccine.nameKey.split('.')[1]}`)}
        </Text>
        <Text style={styles.childName}>{child.name}</Text>
      </View>

      <View style={styles.infoSection}>
        <View style={styles.infoRow}>
          <Icon name="calendar-today" size={20} color="#666" />
          <Text style={styles.infoLabel}>{t('schedule.scheduledFor')}</Text>
          <Text style={styles.infoValue}>
            {moment(record.scheduledDate).format('MMMM DD, YYYY')}
          </Text>
        </View>

        {vaccine.type === 'recommended' && (
          <View style={styles.infoRow}>
            <Icon name="info" size={20} color="#FF9800" />
            <Text style={styles.infoLabel}>Type</Text>
            <View style={styles.recommendedBadge}>
              <Text style={styles.recommendedText}>{t('schedule.recommended')}</Text>
            </View>
          </View>
        )}

        {record.status === 'overdue' && (
          <View style={styles.infoRow}>
            <Icon name="warning" size={20} color="#f44336" />
            <Text style={styles.infoLabel}>Status</Text>
            <Text style={[styles.infoValue, { color: '#f44336' }]}>
              {Math.abs(
                VaccinationService.getDaysUntilVaccination(record.scheduledDate)
              )}{' '}
              {t('schedule.daysOverdue')}
            </Text>
          </View>
        )}
      </View>

      {!isCompleted && (
        <View style={styles.form}>
          <Text style={styles.sectionTitle}>{t('vaccination.recordVaccination')}</Text>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vaccination.date')}</Text>
            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <Icon name="calendar-today" size={20} color="#666" />
              <Text style={styles.dateText}>
                {moment(completedDate).format('MMMM DD, YYYY')}
              </Text>
            </TouchableOpacity>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vaccination.doctorName')}</Text>
            <TextInput
              style={styles.input}
              value={doctorName}
              onChangeText={setDoctorName}
              placeholder={t('vaccination.doctorName')}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vaccination.location')}</Text>
            <TextInput
              style={styles.input}
              value={location}
              onChangeText={setLocation}
              placeholder={t('vaccination.location')}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vaccination.batchNumber')}</Text>
            <TextInput
              style={styles.input}
              value={batchNumber}
              onChangeText={setBatchNumber}
              placeholder={t('vaccination.batchNumber')}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vaccination.notes')}</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder={t('vaccination.addNotes')}
              multiline
              numberOfLines={4}
            />
          </View>

          <TouchableOpacity
            style={styles.completeButton}
            onPress={handleMarkAsCompleted}
            disabled={saving}
          >
            <Icon name="check-circle" size={20} color="#fff" />
            <Text style={styles.completeButtonText}>
              {saving ? t('common.loading') : t('schedule.markAsCompleted')}
            </Text>
          </TouchableOpacity>
        </View>
      )}

      {isCompleted && (
        <View style={styles.completedSection}>
          <Text style={styles.sectionTitle}>Vaccination Details</Text>

          {record.completedDate && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>{t('schedule.completedOn')}</Text>
              <Text style={styles.detailValue}>
                {moment(record.completedDate).format('MMMM DD, YYYY')}
              </Text>
            </View>
          )}

          {record.doctorName && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>{t('vaccination.doctorName')}</Text>
              <Text style={styles.detailValue}>{record.doctorName}</Text>
            </View>
          )}

          {record.location && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>{t('vaccination.location')}</Text>
              <Text style={styles.detailValue}>{record.location}</Text>
            </View>
          )}

          {record.batchNumber && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>{t('vaccination.batchNumber')}</Text>
              <Text style={styles.detailValue}>{record.batchNumber}</Text>
            </View>
          )}

          {record.notes && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>{t('vaccination.notes')}</Text>
              <Text style={styles.detailValue}>{record.notes}</Text>
            </View>
          )}
        </View>
      )}

      <DatePicker
        modal
        open={showDatePicker}
        date={completedDate}
        mode="date"
        maximumDate={new Date()}
        onConfirm={(date) => {
          setShowDatePicker(false);
          setCompletedDate(date);
        }}
        onCancel={() => {
          setShowDatePicker(false);
        }}
      />
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
  header: {
    backgroundColor: '#fff',
    padding: 20,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 15,
    marginBottom: 10,
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  vaccineName: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 5,
    textAlign: 'center',
  },
  childName: {
    fontSize: 16,
    color: '#666',
  },
  infoSection: {
    backgroundColor: '#fff',
    padding: 20,
    marginTop: 10,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
    marginLeft: 10,
    flex: 1,
  },
  infoValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  recommendedBadge: {
    backgroundColor: '#FFF3E0',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  recommendedText: {
    fontSize: 12,
    color: '#FF9800',
    fontWeight: '600',
  },
  form: {
    backgroundColor: '#fff',
    padding: 20,
    marginTop: 10,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 20,
  },
  inputGroup: {
    marginBottom: 15,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: '#666',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f8f8f8',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  textArea: {
    minHeight: 100,
    textAlignVertical: 'top',
  },
  dateButton: {
    backgroundColor: '#f8f8f8',
    borderRadius: 8,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  dateText: {
    fontSize: 14,
    color: '#333',
    marginLeft: 10,
  },
  completeButton: {
    backgroundColor: '#4CAF50',
    borderRadius: 8,
    padding: 15,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
  },
  completeButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  completedSection: {
    backgroundColor: '#fff',
    padding: 20,
    marginTop: 10,
  },
  detailRow: {
    marginBottom: 15,
  },
  detailLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
    textTransform: 'uppercase',
  },
  detailValue: {
    fontSize: 14,
    color: '#333',
  },
});

export default VaccineDetailsScreen;