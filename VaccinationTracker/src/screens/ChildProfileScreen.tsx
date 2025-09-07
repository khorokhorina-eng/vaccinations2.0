import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useRoute } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import moment from 'moment';
import { Child, VaccinationRecord } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';
import { getVaccineById } from '../data/vaccineSchedules';

const ChildProfileScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const route = useRoute();
  const { childId } = route.params as { childId: string };

  const [child, setChild] = useState<Child | null>(null);
  const [vaccinations, setVaccinations] = useState<VaccinationRecord[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, [childId]);

  const loadData = async () => {
    try {
      const children = await StorageService.getChildren();
      const foundChild = children.find(c => c.id === childId);
      if (foundChild) {
        setChild(foundChild);
        const records = await StorageService.getChildVaccinationRecords(childId);
        setVaccinations(records);
      }
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
    }
  };

  const getVaccinationStats = () => {
    const completed = vaccinations.filter(v => v.status === 'completed').length;
    const upcoming = vaccinations.filter(v => v.status === 'upcoming').length;
    const overdue = vaccinations.filter(v => v.status === 'overdue').length;
    const total = vaccinations.length;

    return { completed, upcoming, overdue, total };
  };

  const renderVaccinationItem = (record: VaccinationRecord) => {
    if (!child) return null;
    const vaccine = getVaccineById(child.country, record.vaccineId);
    if (!vaccine) return null;

    const statusColor = {
      overdue: '#f44336',
      upcoming: '#2196F3',
      completed: '#4CAF50',
    }[record.status];

    const statusIcon = {
      overdue: 'warning',
      upcoming: 'schedule',
      completed: 'check-circle',
    }[record.status];

    return (
      <TouchableOpacity
        key={record.id}
        style={styles.vaccinationCard}
        onPress={() =>
          navigation.navigate('VaccineDetails' as never, {
            childId: child.id,
            vaccineId: record.vaccineId,
            recordId: record.id,
          } as never)
        }
      >
        <Icon name={statusIcon} size={24} color={statusColor} />
        <View style={styles.vaccinationInfo}>
          <Text style={styles.vaccineName}>
            {t(`vaccines.${vaccine.nameKey.split('.')[1]}`)}
          </Text>
          <Text style={styles.vaccineDate}>
            {record.completedDate
              ? `${t('schedule.completedOn')} ${moment(record.completedDate).format('MMM DD, YYYY')}`
              : `${t('schedule.scheduledFor')} ${moment(record.scheduledDate).format('MMM DD, YYYY')}`}
          </Text>
        </View>
        <Icon name="chevron-right" size={20} color="#999" />
      </TouchableOpacity>
    );
  };

  if (loading || !child) {
    return (
      <View style={styles.centerContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  const age = VaccinationService.formatAge(child.dateOfBirth);
  const stats = getVaccinationStats();
  const completionPercentage = Math.round((stats.completed / stats.total) * 100) || 0;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.profileSection}>
          <View style={styles.avatar}>
            {child.photoUri ? (
              <Image source={{ uri: child.photoUri }} style={styles.avatarImage} />
            ) : (
              <Icon name="person" size={60} color="#fff" />
            )}
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.childName}>{child.name}</Text>
            <Text style={styles.childAge}>{age}</Text>
            <Text style={styles.childCountry}>{t(`countries.${child.country}`)}</Text>
          </View>
          <TouchableOpacity
            style={styles.editButton}
            onPress={() =>
              navigation.navigate('AddChild' as never, { childId: child.id } as never)
            }
          >
            <Icon name="edit" size={20} color="#2196F3" />
          </TouchableOpacity>
        </View>

        <View style={styles.progressSection}>
          <Text style={styles.progressTitle}>Vaccination Progress</Text>
          <View style={styles.progressBar}>
            <View
              style={[styles.progressFill, { width: `${completionPercentage}%` }]}
            />
          </View>
          <Text style={styles.progressText}>{completionPercentage}% Complete</Text>
        </View>

        <View style={styles.statsContainer}>
          <View style={styles.statCard}>
            <Icon name="check-circle" size={24} color="#4CAF50" />
            <Text style={styles.statNumber}>{stats.completed}</Text>
            <Text style={styles.statLabel}>{t('schedule.completed')}</Text>
          </View>
          <View style={styles.statCard}>
            <Icon name="schedule" size={24} color="#2196F3" />
            <Text style={styles.statNumber}>{stats.upcoming}</Text>
            <Text style={styles.statLabel}>{t('schedule.upcoming')}</Text>
          </View>
          <View style={styles.statCard}>
            <Icon name="warning" size={24} color="#f44336" />
            <Text style={styles.statNumber}>{stats.overdue}</Text>
            <Text style={styles.statLabel}>{t('schedule.overdue')}</Text>
          </View>
        </View>
      </View>

      <View style={styles.vaccinationsSection}>
        <Text style={styles.sectionTitle}>Vaccination Schedule</Text>
        {vaccinations.map(renderVaccinationItem)}
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
  header: {
    backgroundColor: '#fff',
    paddingBottom: 20,
    marginBottom: 10,
  },
  profileSection: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#2196F3',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 15,
  },
  avatarImage: {
    width: 80,
    height: 80,
    borderRadius: 40,
  },
  profileInfo: {
    flex: 1,
  },
  childName: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  childAge: {
    fontSize: 16,
    color: '#666',
    marginBottom: 2,
  },
  childCountry: {
    fontSize: 14,
    color: '#999',
  },
  editButton: {
    padding: 10,
  },
  progressSection: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  progressTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 10,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4CAF50',
    borderRadius: 4,
  },
  progressText: {
    fontSize: 14,
    color: '#666',
    marginTop: 5,
    textAlign: 'center',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 20,
  },
  statCard: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginVertical: 5,
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
  },
  vaccinationsSection: {
    backgroundColor: '#fff',
    padding: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 15,
  },
  vaccinationCard: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  vaccinationInfo: {
    flex: 1,
    marginLeft: 15,
  },
  vaccineName: {
    fontSize: 16,
    color: '#333',
    marginBottom: 4,
  },
  vaccineDate: {
    fontSize: 14,
    color: '#666',
  },
});

export default ChildProfileScreen;