# Vaccination Tracker

A comprehensive React Native application for tracking children's vaccination schedules across multiple countries.

## Features

### 🌍 Multi-Country Support
- United States
- China
- Russia
- Germany
- France
- Italy
- Brazil
- Mexico
- Argentina
- Turkey
- Ukraine
- Uzbekistan

### 👶 Child Profile Management
- Add multiple children profiles
- Track each child's vaccination schedule independently
- Store child information including name, date of birth, and country

### 💉 Vaccination Tracking
- **Mandatory Vaccines**: Shown by default
- **Recommended Vaccines**: Can be enabled through settings
- **Status Tracking**: 
  - Upcoming vaccinations
  - Overdue vaccinations
  - Completed vaccinations
- Record vaccination details including date, doctor, location, and notes

### 📅 Smart Scheduling
- Automatic calculation of vaccination dates based on child's date of birth
- Country-specific vaccination calendars hardcoded in the app
- No external API dependencies - all data stored locally

### 🔔 Notifications
- Push notifications for upcoming vaccinations
- Customizable reminder timing (1-30 days before)
- Overdue vaccination alerts

### 🌐 Internationalization
- Default language: English
- Ready for localization to:
  - Chinese (中文)
  - Russian (Русский)
  - Spanish (Español)
  - Turkish (Türkçe)
  - Ukrainian (Українська)

## Installation

### Prerequisites
- Node.js >= 20
- React Native development environment set up for iOS/Android
- For iOS: Xcode and CocoaPods
- For Android: Android Studio and Android SDK

### Setup

1. Install dependencies:
```bash
npm install
```

2. For iOS, install pods:
```bash
cd ios && pod install
cd ..
```

3. Configure native modules:

#### Android
The app should work out of the box on Android. If you encounter issues with vector icons:
```bash
npx react-native-vector-icons link
```

#### iOS
For notifications to work on iOS, you need to:
1. Open the project in Xcode
2. Enable Push Notifications capability
3. Configure notification permissions in Info.plist

## Running the Application

### Android
```bash
npx react-native run-android
```

### iOS
```bash
npx react-native run-ios
```

### Start Metro bundler
```bash
npm start
```

## Project Structure

```
src/
├── components/       # Reusable UI components
├── screens/         # Application screens
├── navigation/      # Navigation configuration
├── services/        # Business logic services
├── data/           # Vaccination schedules data
├── locales/        # Internationalization files
├── types/          # TypeScript type definitions
├── utils/          # Utility functions
├── hooks/          # Custom React hooks
└── store/          # State management
```

## Key Features Implementation

### Data Storage
- All data is stored locally using AsyncStorage
- No external API calls after installation
- Vaccination calendars are hardcoded in the bundle

### Vaccination Schedules
- Each country has its own vaccination calendar
- Vaccines are categorized as mandatory or recommended
- Multi-dose vaccines are handled automatically

### Notifications
- Uses @notifee/react-native for local notifications
- Reminders scheduled based on user preferences
- Automatic detection of overdue vaccinations

## Settings

Users can configure:
- **Language**: Choose interface language
- **Notifications**: Enable/disable and set reminder timing
- **Recommended Vaccines**: Show/hide recommended vaccines
- **Data Management**: Export or delete all data

## Development

### Adding a New Country

1. Add the country to the `Country` type in `src/types/index.ts`
2. Add vaccination schedule in `src/data/vaccineSchedules.ts`
3. Add country translation in `src/locales/[language].ts`

### Adding a New Language

1. Create translation file in `src/locales/[language].ts`
2. Import and add to resources in `src/locales/i18n.ts`
3. Add language option in Settings screen

## Security & Privacy

- All data is stored locally on the device
- No data is sent to external servers
- User has full control over their data
- Can delete all data at any time through settings

## Troubleshooting

### Build Issues

If you encounter build issues:

1. Clear caches:
```bash
npx react-native start --reset-cache
cd android && ./gradlew clean
cd ios && rm -rf build/
```

2. Reinstall dependencies:
```bash
rm -rf node_modules
npm install
```

### Notification Issues

- Ensure notifications are enabled in device settings
- Check that the app has necessary permissions
- For iOS, ensure Push Notifications capability is enabled

## License

This project is private and proprietary.

## Support

For issues or questions, please contact the development team.