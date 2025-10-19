import { NativeModules } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const { WidgetUpdateModule } = NativeModules;

export const syncSettingsToSharedPreferences = async () => {
  console.log('syncSettingsToSharedPreferences called from JavaScript');
  
  try {
    // Read settings from AsyncStorage
    const userPerspective = await AsyncStorage.getItem("userPerspective");
    const timeMode = await AsyncStorage.getItem("timeMode");
    const selectedDisplayItems = await AsyncStorage.getItem("selectedDisplayItems");
    const customEvents = await AsyncStorage.getItem("customEvents");
    
    console.log('Settings read from AsyncStorage:', {
      userPerspective,
      timeMode,
      selectedDisplayItems,
      customEvents
    });
    
    if (WidgetUpdateModule) {
      console.log('WidgetUpdateModule found, syncing settings to SharedPreferences');
      WidgetUpdateModule.syncSettingsToSharedPreferences(
        userPerspective || "half-empty",
        timeMode || "24h", 
        selectedDisplayItems || '["today","month","year"]',
        customEvents || '[]'
      );
    } else {
      console.warn('WidgetUpdateModule not found');
    }
  } catch (error) {
    console.error('Error syncing settings to SharedPreferences:', error);
  }
};

export const updateWidgets = async () => {
  console.log('updateWidgets called from JavaScript');
  
  // First sync settings to SharedPreferences
  await syncSettingsToSharedPreferences();
  
  // Then trigger widget updates
  if (WidgetUpdateModule) {
    console.log('WidgetUpdateModule found, calling updateWidgets');
    WidgetUpdateModule.updateWidgets();
  } else {
    console.warn('WidgetUpdateModule not found');
  }
};
