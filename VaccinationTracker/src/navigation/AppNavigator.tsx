import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTranslation } from 'react-i18next';

// Import screens (we'll create these next)
import HomeScreen from '../screens/HomeScreen';
import ChildrenScreen from '../screens/ChildrenScreen';
import AddChildScreen from '../screens/AddChildScreen';
import ChildProfileScreen from '../screens/ChildProfileScreen';
import ScheduleScreen from '../screens/ScheduleScreen';
import VaccineDetailsScreen from '../screens/VaccineDetailsScreen';
import SettingsScreen from '../screens/SettingsScreen';

export type RootStackParamList = {
  Main: undefined;
  AddChild: { childId?: string };
  ChildProfile: { childId: string };
  VaccineDetails: { childId: string; vaccineId: string; recordId?: string };
};

export type MainTabParamList = {
  Home: undefined;
  Children: undefined;
  Schedule: undefined;
  Settings: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

const MainTabs: React.FC = () => {
  const { t } = useTranslation();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: string;

          switch (route.name) {
            case 'Home':
              iconName = 'home';
              break;
            case 'Children':
              iconName = 'child-care';
              break;
            case 'Schedule':
              iconName = 'calendar-today';
              break;
            case 'Settings':
              iconName = 'settings';
              break;
            default:
              iconName = 'home';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#2196F3',
        tabBarInactiveTintColor: 'gray',
        headerStyle: {
          backgroundColor: '#2196F3',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeScreen} 
        options={{ title: t('navigation.home') }}
      />
      <Tab.Screen 
        name="Children" 
        component={ChildrenScreen} 
        options={{ title: t('navigation.children') }}
      />
      <Tab.Screen 
        name="Schedule" 
        component={ScheduleScreen} 
        options={{ title: t('navigation.schedule') }}
      />
      <Tab.Screen 
        name="Settings" 
        component={SettingsScreen} 
        options={{ title: t('navigation.settings') }}
      />
    </Tab.Navigator>
  );
};

const AppNavigator: React.FC = () => {
  const { t } = useTranslation();

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: {
            backgroundColor: '#2196F3',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen 
          name="Main" 
          component={MainTabs} 
          options={{ headerShown: false }}
        />
        <Stack.Screen 
          name="AddChild" 
          component={AddChildScreen} 
          options={{ title: t('navigation.addChild') }}
        />
        <Stack.Screen 
          name="ChildProfile" 
          component={ChildProfileScreen} 
          options={{ title: t('navigation.childProfile') }}
        />
        <Stack.Screen 
          name="VaccineDetails" 
          component={VaccineDetailsScreen} 
          options={{ title: t('navigation.vaccineDetails') }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;