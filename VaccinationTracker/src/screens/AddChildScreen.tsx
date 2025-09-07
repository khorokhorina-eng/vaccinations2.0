import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  Platform,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useRoute } from '@react-navigation/native';
import DatePicker from 'react-native-date-picker';
import Icon from 'react-native-vector-icons/MaterialIcons';
import moment from 'moment';
import { Picker } from '@react-native-picker/picker';
import { Child, Country } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';
import { NotificationService } from '../services/notificationService';

const AddChildScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const route = useRoute();
  const childId = (route.params as any)?.childId;
  const isEditing = !!childId;

  const [name, setName] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState(new Date());
  const [country, setCountry] = useState<Country>('USA');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [loading, setLoading] = useState(false);

  const countries: Country[] = [
    'USA',
    'China',
    'Russia',
    'Germany',
    'France',
    'Italy',
    'Brazil',
    'Mexico',
    'Argentina',
    'Turkey',
    'Ukraine',
    'Uzbekistan',
  ];

  useEffect(() => {
    if (isEditing) {
      loadChild();
    }
  }, [childId]);

  const loadChild = async () => {
    try {
      const children = await StorageService.getChildren();
      const child = children.find(c => c.id === childId);
      if (child) {
        setName(child.name);
        setDateOfBirth(new Date(child.dateOfBirth));
        setCountry(child.country);
      }
    } catch (error) {
      console.error('Error loading child:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    }
  };

  const validateForm = (): boolean => {
    if (!name.trim()) {
      Alert.alert(t('errors.general'), t('errors.childNameRequired'));
      return false;
    }

    if (moment(dateOfBirth).isAfter(moment())) {
      Alert.alert(t('errors.general'), t('errors.futureDate'));
      return false;
    }

    return true;
  };

  const handleSave = async () => {
    if (!validateForm()) return;

    setLoading(true);
    try {
      if (isEditing) {
        await StorageService.updateChild(childId, {
          name: name.trim(),
          dateOfBirth: dateOfBirth.toISOString(),
          country,
        });
      } else {
        const newChild: Child = {
          id: `child_${Date.now()}`,
          name: name.trim(),
          dateOfBirth: dateOfBirth.toISOString(),
          country,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        
        await StorageService.addChild(newChild);
        
        // Create vaccination records for the new child
        await VaccinationService.createVaccinationRecordsForChild(newChild);
        
        // Schedule reminders
        await NotificationService.scheduleAllReminders(newChild);
      }

      navigation.goBack();
    } catch (error) {
      console.error('Error saving child:', error);
      Alert.alert(t('errors.general'), t('errors.saveError'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.form}>
        <View style={styles.inputGroup}>
          <Text style={styles.label}>{t('children.name')}</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder={t('children.name')}
            autoCapitalize="words"
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>{t('children.dateOfBirth')}</Text>
          <TouchableOpacity
            style={styles.dateButton}
            onPress={() => setShowDatePicker(true)}
          >
            <Icon name="calendar-today" size={20} color="#666" />
            <Text style={styles.dateText}>
              {moment(dateOfBirth).format('MMMM DD, YYYY')}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>{t('children.country')}</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={country}
              onValueChange={(value) => setCountry(value as Country)}
              style={styles.picker}
            >
              {countries.map(c => (
                <Picker.Item key={c} label={t(`countries.${c}`)} value={c} />
              ))}
            </Picker>
          </View>
        </View>

        <View style={styles.buttonContainer}>
          <TouchableOpacity
            style={[styles.button, styles.cancelButton]}
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.cancelButtonText}>{t('common.cancel')}</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.button, styles.saveButton]}
            onPress={handleSave}
            disabled={loading}
          >
            <Text style={styles.saveButtonText}>
              {loading ? t('common.loading') : t('common.save')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <DatePicker
        modal
        open={showDatePicker}
        date={dateOfBirth}
        mode="date"
        maximumDate={new Date()}
        onConfirm={(date) => {
          setShowDatePicker(false);
          setDateOfBirth(date);
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
  form: {
    padding: 20,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  dateButton: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  dateText: {
    fontSize: 16,
    color: '#333',
    marginLeft: 10,
  },
  pickerContainer: {
    backgroundColor: '#fff',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    overflow: 'hidden',
  },
  picker: {
    height: Platform.OS === 'ios' ? 200 : 50,
  },
  buttonContainer: {
    flexDirection: 'row',
    marginTop: 30,
    gap: 10,
  },
  button: {
    flex: 1,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  saveButton: {
    backgroundColor: '#2196F3',
  },
  cancelButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#666',
  },
  saveButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },
});

export default AddChildScreen;