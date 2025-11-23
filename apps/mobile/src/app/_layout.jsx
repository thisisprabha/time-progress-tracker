
import { useAuth } from '@/utils/auth/useAuth';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const { initiate, isReady } = useAuth();

  useEffect(() => {
    try {
      initiate();
    } catch (error) {
      console.error('Auth initialization error:', error);
      // Continue anyway - don't block app launch
    }
  }, [initiate]);

  useEffect(() => {
    // Hide splash screen after a short delay even if auth isn't ready
    const timer = setTimeout(() => {
      SplashScreen.hideAsync().catch(console.error);
    }, 1000);
    
    if (isReady) {
      clearTimeout(timer);
      SplashScreen.hideAsync().catch(console.error);
    }
    
    return () => clearTimeout(timer);
  }, [isReady]);

  // Don't block rendering - always show the app
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack screenOptions={{ headerShown: false }} initialRouteName="index">
        <Stack.Screen name="index" />
        <Stack.Screen name="widget-demo" />
      </Stack>
    </GestureHandlerRootView>
  );
}
