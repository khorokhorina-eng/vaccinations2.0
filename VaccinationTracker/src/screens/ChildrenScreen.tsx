import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Image,
  Alert,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { Child } from '../types';
import { StorageService } from '../services/storage';
import { VaccinationService } from '../services/vaccinationService';

const ChildrenScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);

  const loadChildren = async () => {
    try {
      const loadedChildren = await StorageService.getChildren();
      setChildren(loadedChildren);
    } catch (error) {
      console.error('Error loading children:', error);
      Alert.alert(t('errors.general'), t('errors.loadError'));
    } finally {
      setLoading(false);
    }
  };

  useFocusEffect(
    React.useCallback(() => {
      loadChildren();
    }, [])
  );

  const handleDeleteChild = (child: Child) => {
    Alert.alert(
      t('children.deleteConfirm'),
      t('children.deleteWarning'),
      [
        { text: t('common.cancel'), style: 'cancel' },
        {
          text: t('common.delete'),
          style: 'destructive',
          onPress: async () => {
            try {
              await StorageService.deleteChild(child.id);
              loadChildren();
            } catch (error) {
              console.error('Error deleting child:', error);
              Alert.alert(t('errors.general'), t('errors.saveError'));
            }
          },
        },
      ]
    );
  };

  const renderChild = ({ item }: { item: Child }) => {
    const age = VaccinationService.formatAge(item.dateOfBirth);

    return (
      <TouchableOpacity
        style={styles.childCard}
        onPress={() =>
          navigation.navigate('ChildProfile' as never, { childId: item.id } as never)
        }
      >
        <View style={styles.childAvatar}>
          {item.photoUri ? (
            <Image source={{ uri: item.photoUri }} style={styles.avatarImage} />
          ) : (
            <Icon name="person" size={40} color="#fff" />
          )}
        </View>
        <View style={styles.childInfo}>
          <Text style={styles.childName}>{item.name}</Text>
          <Text style={styles.childAge}>{age}</Text>
          <Text style={styles.childCountry}>{t(`countries.${item.country}`)}</Text>
        </View>
        <View style={styles.childActions}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() =>
              navigation.navigate('AddChild' as never, { childId: item.id } as never)
            }
          >
            <Icon name="edit" size={20} color="#2196F3" />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => handleDeleteChild(item)}
          >
            <Icon name="delete" size={20} color="#f44336" />
          </TouchableOpacity>
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
    <View style={styles.container}>
      {children.length === 0 ? (
        <View style={styles.emptyState}>
          <Icon name="child-care" size={80} color="#ccc" />
          <Text style={styles.emptyStateTitle}>{t('children.noChildren')}</Text>
          <Text style={styles.emptyStateText}>{t('children.addFirstChild')}</Text>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => navigation.navigate('AddChild' as never)}
          >
            <Icon name="add" size={24} color="#fff" />
            <Text style={styles.addButtonText}>{t('children.addChild')}</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <>
          <FlatList
            data={children}
            renderItem={renderChild}
            keyExtractor={item => item.id}
            contentContainerStyle={styles.listContainer}
          />
          <TouchableOpacity
            style={styles.fab}
            onPress={() => navigation.navigate('AddChild' as never)}
          >
            <Icon name="add" size={30} color="#fff" />
          </TouchableOpacity>
        </>
      )}
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
  listContainer: {
    padding: 15,
  },
  childCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 15,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  childAvatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#2196F3',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 15,
  },
  avatarImage: {
    width: 60,
    height: 60,
    borderRadius: 30,
  },
  childInfo: {
    flex: 1,
  },
  childName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  childAge: {
    fontSize: 14,
    color: '#666',
    marginBottom: 2,
  },
  childCountry: {
    fontSize: 12,
    color: '#999',
  },
  childActions: {
    flexDirection: 'row',
  },
  actionButton: {
    padding: 8,
    marginLeft: 5,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  emptyStateTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginTop: 20,
    marginBottom: 10,
  },
  emptyStateText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 30,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2196F3',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 25,
  },
  addButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 8,
  },
  fab: {
    position: 'absolute',
    right: 20,
    bottom: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#2196F3',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
  },
});

export default ChildrenScreen;