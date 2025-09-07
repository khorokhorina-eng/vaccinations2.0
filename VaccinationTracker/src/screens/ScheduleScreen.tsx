import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  SectionList,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import moment from 'moment';
import { Child, VaccinationRecord, VaccinationStatus } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';
import { getVaccineById } from '../data/vaccineSchedules';

interface VaccinationWithChild {
  record: VaccinationRecord;
  child: Child;
}

const ScheduleScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const [children, setChildren] = useState<Child[]>([]);
  const [vaccinations, setVaccinations] = useState<VaccinationWithChild[]>([]);
  const [showRecommended, setShowRecommended] = useState(false);
  const [selectedChild, setSelectedChild] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const loadedChildren = await StorageService.getChildren();
      setChildren(loadedChildren);

      const settings = await StorageService.getSettings();
      setShowRecommended(settings.showRecommendedVaccines);

      const allVaccinations: VaccinationWithChild[] = [];

      for (const child of loadedChildren) {
        const records = await StorageService.getChildVaccinationRecords(child.id);
        
        for (const record of records) {
          const vaccine = getVaccineById(child.country, record.vaccineId);
          if (vaccine) {
            // Filter based on showRecommended setting
            if (vaccine.type === 'mandatory' || showRecommended) {
              allVaccinations.push({ record, child });
            }
          }
        }
      }

      setVaccinations(allVaccinations);
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
    }
  };

  useFocusEffect(
    React.useCallback(() => {
      loadData();
    }, [showRecommended])
  );

  const handleToggleRecommended = async (value: boolean) => {
    setShowRecommended(value);
    await StorageService.updateSettings({ showRecommendedVaccines: value });
    loadData();
  };

  const groupVaccinationsByStatus = () => {
    const filtered = selectedChild
      ? vaccinations.filter(v => v.child.id === selectedChild)
      : vaccinations;

    const overdue = filtered.filter(v => v.record.status === 'overdue');
    const upcoming = filtered.filter(v => v.record.status === 'upcoming');
    const completed = filtered.filter(v => v.record.status === 'completed');

    // Sort by date
    overdue.sort((a, b) =>
      moment(a.record.scheduledDate).diff(moment(b.record.scheduledDate))
    );
    upcoming.sort((a, b) =>
      moment(a.record.scheduledDate).diff(moment(b.record.scheduledDate))
    );
    completed.sort((a, b) =>
      moment(b.record.completedDate || b.record.scheduledDate).diff(
        moment(a.record.completedDate || a.record.scheduledDate)
      )
    );

    const sections = [];
    if (overdue.length > 0) {
      sections.push({ title: t('schedule.overdue'), data: overdue });
    }
    if (upcoming.length > 0) {
      sections.push({ title: t('schedule.upcoming'), data: upcoming });
    }
    if (completed.length > 0) {
      sections.push({ title: t('schedule.completed'), data: completed });
    }

    return sections;
  };

  const renderVaccinationItem = ({ item }: { item: VaccinationWithChild }) => {
    const vaccine = getVaccineById(item.child.country, item.record.vaccineId);
    if (!vaccine) return null;

    const formattedDate = item.record.completedDate
      ? moment(item.record.completedDate).format('MMM DD, YYYY')
      : VaccinationService.formatScheduledDate(item.record.scheduledDate);

    const statusColor = {
      overdue: '#f44336',
      upcoming: '#2196F3',
      completed: '#4CAF50',
    }[item.record.status];

    return (
      <TouchableOpacity
        style={styles.vaccinationCard}
        onPress={() =>
          navigation.navigate('VaccineDetails' as never, {
            childId: item.child.id,
            vaccineId: item.record.vaccineId,
            recordId: item.record.id,
          } as never)
        }
      >
        <View style={[styles.statusIndicator, { backgroundColor: statusColor }]} />
        <View style={styles.vaccinationContent}>
          <View style={styles.vaccinationHeader}>
            <Text style={styles.childName}>{item.child.name}</Text>
            {vaccine.type === 'recommended' && (
              <View style={styles.recommendedBadge}>
                <Text style={styles.recommendedText}>{t('schedule.recommended')}</Text>
              </View>
            )}
          </View>
          <Text style={styles.vaccineName}>
            {t(`vaccines.${vaccine.nameKey.split('.')[1]}`)}
          </Text>
          <View style={styles.vaccinationFooter}>
            <Text style={styles.dateText}>{formattedDate}</Text>
            {item.record.status === 'overdue' && (
              <Text style={styles.overdueText}>
                {Math.abs(
                  VaccinationService.getDaysUntilVaccination(item.record.scheduledDate)
                )}{' '}
                {t('schedule.daysOverdue')}
              </Text>
            )}
          </View>
        </View>
        {item.record.status !== 'completed' && (
          <Icon name="chevron-right" size={24} color="#999" />
        )}
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

  if (children.length === 0) {
    return (
      <View style={styles.emptyState}>
        <Icon name="calendar-today" size={80} color="#ccc" />
        <Text style={styles.emptyStateTitle}>{t('children.noChildren')}</Text>
        <TouchableOpacity
          style={styles.addButton}
          onPress={() => navigation.navigate('Children' as never)}
        >
          <Text style={styles.addButtonText}>{t('children.addFirstChild')}</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const sections = groupVaccinationsByStatus();

  return (
    <View style={styles.container}>
      <View style={styles.filterContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <TouchableOpacity
            style={[
              styles.filterChip,
              !selectedChild && styles.filterChipActive,
            ]}
            onPress={() => setSelectedChild(null)}
          >
            <Text
              style={[
                styles.filterChipText,
                !selectedChild && styles.filterChipTextActive,
              ]}
            >
              All Children
            </Text>
          </TouchableOpacity>
          {children.map(child => (
            <TouchableOpacity
              key={child.id}
              style={[
                styles.filterChip,
                selectedChild === child.id && styles.filterChipActive,
              ]}
              onPress={() => setSelectedChild(child.id)}
            >
              <Text
                style={[
                  styles.filterChipText,
                  selectedChild === child.id && styles.filterChipTextActive,
                ]}
              >
                {child.name}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <View style={styles.toggleContainer}>
        <Text style={styles.toggleLabel}>{t('schedule.showRecommended')}</Text>
        <Switch
          value={showRecommended}
          onValueChange={handleToggleRecommended}
          trackColor={{ false: '#ccc', true: '#81C784' }}
          thumbColor={showRecommended ? '#4CAF50' : '#f4f3f4'}
        />
      </View>

      <SectionList
        sections={sections}
        keyExtractor={item => item.record.id}
        renderItem={renderVaccinationItem}
        renderSectionHeader={({ section }) => (
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            <Text style={styles.sectionCount}>{section.data.length}</Text>
          </View>
        )}
        contentContainerStyle={styles.listContainer}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Icon name="check-circle" size={64} color="#4CAF50" />
            <Text style={styles.emptyStateText}>{t('schedule.noUpcoming')}</Text>
          </View>
        }
      />
    </View>
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
  filterContainer: {
    backgroundColor: '#fff',
    paddingVertical: 10,
    paddingHorizontal: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  filterChip: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f0f0f0',
    marginRight: 10,
  },
  filterChipActive: {
    backgroundColor: '#2196F3',
  },
  filterChipText: {
    fontSize: 14,
    color: '#666',
  },
  filterChipTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  toggleContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  toggleLabel: {
    fontSize: 16,
    color: '#333',
  },
  listContainer: {
    paddingBottom: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    paddingHorizontal: 15,
    paddingVertical: 10,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  sectionCount: {
    fontSize: 14,
    color: '#666',
    backgroundColor: '#e0e0e0',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
  },
  vaccinationCard: {
    backgroundColor: '#fff',
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  statusIndicator: {
    width: 4,
    height: '100%',
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
  },
  vaccinationContent: {
    flex: 1,
    marginLeft: 10,
  },
  vaccinationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  childName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  recommendedBadge: {
    backgroundColor: '#FFF3E0',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    marginLeft: 10,
  },
  recommendedText: {
    fontSize: 11,
    color: '#FF9800',
  },
  vaccineName: {
    fontSize: 16,
    color: '#333',
    marginBottom: 4,
  },
  vaccinationFooter: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dateText: {
    fontSize: 12,
    color: '#666',
  },
  overdueText: {
    fontSize: 12,
    color: '#f44336',
    marginLeft: 10,
  },
  emptyState: {
    alignItems: 'center',
    padding: 40,
  },
  emptyStateTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginTop: 20,
    marginBottom: 10,
  },
  emptyStateText: {
    fontSize: 16,
    color: '#666',
    marginTop: 20,
    textAlign: 'center',
  },
  addButton: {
    marginTop: 20,
    paddingHorizontal: 20,
    paddingVertical: 10,
    backgroundColor: '#2196F3',
    borderRadius: 20,
  },
  addButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default ScheduleScreen;