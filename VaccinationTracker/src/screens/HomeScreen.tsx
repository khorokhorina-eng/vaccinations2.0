import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import moment from 'moment';
import { Child, VaccinationRecord } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';
import { getVaccineById } from '../data/vaccineSchedules';

const HomeScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const [children, setChildren] = useState<Child[]>([]);
  const [upcomingVaccinations, setUpcomingVaccinations] = useState<
    Array<{ child: Child; record: VaccinationRecord }>
  >([]);
  const [overdueVaccinations, setOverdueVaccinations] = useState<
    Array<{ child: Child; record: VaccinationRecord }>
  >([]);
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const loadedChildren = await StorageService.getChildren();
      setChildren(loadedChildren);

      const upcoming: Array<{ child: Child; record: VaccinationRecord }> = [];
      const overdue: Array<{ child: Child; record: VaccinationRecord }> = [];

      for (const child of loadedChildren) {
        const upcomingRecords = await VaccinationService.getUpcomingVaccinations(
          child.id,
          30
        );
        upcomingRecords.forEach(record => {
          upcoming.push({ child, record });
        });

        const overdueRecords = await VaccinationService.getOverdueVaccinations(
          child.id
        );
        overdueRecords.forEach(record => {
          overdue.push({ child, record });
        });
      }

      // Sort by date
      upcoming.sort((a, b) =>
        moment(a.record.scheduledDate).diff(moment(b.record.scheduledDate))
      );
      overdue.sort((a, b) =>
        moment(b.record.scheduledDate).diff(moment(a.record.scheduledDate))
      );

      setUpcomingVaccinations(upcoming);
      setOverdueVaccinations(overdue);
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    React.useCallback(() => {
      loadData();
    }, [])
  );

  const onRefresh = () => {
    setRefreshing(true);
    loadData();
  };

  const renderVaccinationItem = (
    item: { child: Child; record: VaccinationRecord },
    isOverdue: boolean = false
  ) => {
    const vaccine = getVaccineById(item.child.country, item.record.vaccineId);
    if (!vaccine) return null;

    const daysUntil = VaccinationService.getDaysUntilVaccination(
      item.record.scheduledDate
    );
    const formattedDate = VaccinationService.formatScheduledDate(
      item.record.scheduledDate
    );

    return (
      <TouchableOpacity
        key={item.record.id}
        style={[styles.vaccinationCard, isOverdue && styles.overdueCard]}
        onPress={() =>
          navigation.navigate('VaccineDetails' as never, {
            childId: item.child.id,
            vaccineId: item.record.vaccineId,
            recordId: item.record.id,
          } as never)
        }
      >
        <View style={styles.vaccinationHeader}>
          <Icon
            name={isOverdue ? 'warning' : 'schedule'}
            size={24}
            color={isOverdue ? '#f44336' : '#2196F3'}
          />
          <View style={styles.vaccinationInfo}>
            <Text style={styles.childName}>{item.child.name}</Text>
            <Text style={styles.vaccineName}>
              {t(`vaccines.${vaccine.nameKey.split('.')[1]}`)}
            </Text>
          </View>
        </View>
        <View style={styles.vaccinationFooter}>
          <Text style={[styles.dateText, isOverdue && styles.overdueText]}>
            {formattedDate}
          </Text>
          {isOverdue ? (
            <Text style={styles.overdueText}>
              {Math.abs(daysUntil)} {t('schedule.daysOverdue')}
            </Text>
          ) : (
            daysUntil > 0 && (
              <Text style={styles.daysText}>
                {daysUntil} {t('schedule.daysUntil')}
              </Text>
            )
          )}
        </View>
      </TouchableOpacity>
    );
  };

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      <View style={styles.header}>
        <Text style={styles.welcomeText}>{t('common.welcome')}</Text>
        {children.length === 0 ? (
          <TouchableOpacity
            style={styles.addChildButton}
            onPress={() => navigation.navigate('AddChild' as never)}
          >
            <Icon name="add-circle" size={24} color="#fff" />
            <Text style={styles.addChildText}>{t('children.addFirstChild')}</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.summaryContainer}>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryNumber}>{children.length}</Text>
              <Text style={styles.summaryLabel}>
                {children.length === 1 ? 'Child' : 'Children'}
              </Text>
            </View>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryNumber}>{upcomingVaccinations.length}</Text>
              <Text style={styles.summaryLabel}>{t('schedule.upcoming')}</Text>
            </View>
            <View style={styles.summaryCard}>
              <Text style={[styles.summaryNumber, styles.overdueNumber]}>
                {overdueVaccinations.length}
              </Text>
              <Text style={styles.summaryLabel}>{t('schedule.overdue')}</Text>
            </View>
          </View>
        )}
      </View>

      {overdueVaccinations.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('schedule.overdue')}</Text>
          {overdueVaccinations.map(item => renderVaccinationItem(item, true))}
        </View>
      )}

      {upcomingVaccinations.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('schedule.upcoming')}</Text>
          {upcomingVaccinations.map(item => renderVaccinationItem(item))}
        </View>
      )}

      {children.length > 0 &&
        upcomingVaccinations.length === 0 &&
        overdueVaccinations.length === 0 && (
          <View style={styles.emptyState}>
            <Icon name="check-circle" size={64} color="#4CAF50" />
            <Text style={styles.emptyStateText}>{t('schedule.allCompleted')}</Text>
          </View>
        )}
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
    backgroundColor: '#2196F3',
    padding: 20,
    paddingTop: 30,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
  },
  welcomeText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 20,
  },
  addChildButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
    padding: 15,
    borderRadius: 10,
  },
  addChildText: {
    color: '#fff',
    fontSize: 16,
    marginLeft: 10,
  },
  summaryContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  summaryCard: {
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
    padding: 15,
    borderRadius: 10,
    minWidth: 80,
  },
  summaryNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  summaryLabel: {
    fontSize: 12,
    color: '#fff',
    marginTop: 5,
  },
  overdueNumber: {
    color: '#ffcdd2',
  },
  section: {
    padding: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 15,
  },
  vaccinationCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 15,
    marginBottom: 10,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  overdueCard: {
    borderLeftWidth: 4,
    borderLeftColor: '#f44336',
  },
  vaccinationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  vaccinationInfo: {
    marginLeft: 15,
    flex: 1,
  },
  childName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  vaccineName: {
    fontSize: 14,
    color: '#666',
    marginTop: 2,
  },
  vaccinationFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dateText: {
    fontSize: 14,
    color: '#666',
  },
  overdueText: {
    color: '#f44336',
    fontWeight: 'bold',
  },
  daysText: {
    fontSize: 12,
    color: '#999',
  },
  emptyState: {
    alignItems: 'center',
    padding: 40,
  },
  emptyStateText: {
    fontSize: 16,
    color: '#666',
    marginTop: 20,
    textAlign: 'center',
  },
});

export default HomeScreen;