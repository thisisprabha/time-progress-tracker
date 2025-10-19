import { NativeModules } from 'react-native';

const { WidgetUpdateModule } = NativeModules;

export const updateWidgets = () => {
  console.log('updateWidgets called from JavaScript');
  if (WidgetUpdateModule) {
    console.log('WidgetUpdateModule found, calling updateWidgets');
    WidgetUpdateModule.updateWidgets();
  } else {
    console.warn('WidgetUpdateModule not found');
  }
};
