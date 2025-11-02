import React, { useState, useEffect, useCallback, useRef } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  Modal,
  Platform,
  Animated,
  TextInput,
  ScrollView,
  Alert,
  useWindowDimensions,
} from "react-native";
import Svg, { Path } from "react-native-svg";
import { Image } from "expo-image";
import { Asset } from "expo-asset";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { router } from 'expo-router';
import { StatusBar } from "expo-status-bar";
import * as Haptics from "expo-haptics";
import { updateWidgets } from '../utils/widgetUpdate';
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";

// Conditionally import AdMob for Android only
let MobileAds, BannerAd, BannerAdSize, TestIds;
if (Platform.OS === 'android') {
  const GoogleMobileAds = require('react-native-google-mobile-ads');
  MobileAds = GoogleMobileAds.MobileAds;
  BannerAd = GoogleMobileAds.BannerAd;
  BannerAdSize = GoogleMobileAds.BannerAdSize;
  TestIds = GoogleMobileAds.TestIds;
}

const { width: screenWidth, height: screenHeight } = Dimensions.get("window");
const isSmallScreen = screenHeight < 700 || screenWidth < 400;

// Configure notifications
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

const WaterGlassIcon = ({ isHalfFull = true }) => {
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.05,
          duration: 2000,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 2000,
          useNativeDriver: true,
        }),
      ])
    );
    pulse.start();
    return () => pulse.stop();
  }, []);

  return (
    <Animated.View style={{ transform: [{ scale: pulseAnim }] }}>
      <Svg width="120" height="160" viewBox="0 0 120 160">
        {/* Glass outline */}
        <Path
          d="M30 20 L90 20 L85 140 L35 140 Z"
          fill="none"
          stroke="#666666"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Water */}
        <Path
          d="M32 80 L88 80 L84.5 138 L36.5 138 Z"
          fill={isHalfFull ? "#333333" : "transparent"}
          opacity={isHalfFull ? 0.6 : 0}
        />

        {/* Water surface line */}
        {isHalfFull && (
          <Path d="M32 80 L88 80" stroke="#333333" strokeWidth="2" opacity={0.8} />
        )}
      </Svg>
    </Animated.View>
  );
};

const SettingsIcon = ({ onPress }) => {
  const scaleAnim = useRef(new Animated.Value(1)).current;

  const handlePressIn = () => {
    Animated.spring(scaleAnim, {
      toValue: 0.95,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(scaleAnim, {
      toValue: 1,
      useNativeDriver: true,
    }).start();
  };

  return (
    <Animated.View style={{ transform: [{ scale: scaleAnim }] }}>
      <TouchableOpacity 
        onPress={onPress} 
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        style={styles.settingsButton}
      >
        <Svg width="24" height="24" viewBox="0 0 24 24">
          <Path
            d="M12 15.5A3.5 3.5 0 0 1 8.5 12A3.5 3.5 0 0 1 12 8.5a3.5 3.5 0 0 1 3.5 3.5a3.5 3.5 0 0 1-3.5 3.5M19.43 12.97c.04-.32.07-.64.07-.97c0-.33-.03-.66-.07-1l2.11-1.63c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.31-.61-.22l-2.49 1c-.52-.39-1.06-.73-1.69-.98l-.37-2.65A.506.506 0 0 0 14 2h-4c-.25 0-.46.18-.5.42l-.37 2.65c-.63.25-1.17.59-1.69.98l-2.49-1c-.22-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64L4.57 11c-.04.34-.07.67-.07 1c0 .33.03.65.07.97l-2.11 1.66c-.19.15-.25.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1.01c.52.4 1.06.74 1.69.99l.37 2.65c.04.24.25.42.5.42h4c.25 0 .46-.18.5-.42l.37-2.65c.63-.26 1.17-.59 1.69-.99l2.49 1.01c.22.08.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64l-2.11-1.66Z"
            fill="#666666"
            stroke="#666666"
            strokeWidth="0.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </Svg>
      </TouchableOpacity>
    </Animated.View>
  );
};

const TallyCounter = ({ total, completed, label, value, unit }) => {
  const renderTallyMark = (index, isCrossed) => (
    <View key={index} style={styles.tallyMark}>
      {/* Vertical line */}
      <View style={styles.tallyLine} />
      {/* Cross line if completed */}
      {isCrossed && <View style={styles.crossLine} />}
    </View>
  );

  return (
    <View style={styles.tallyContainer}>
      <View style={styles.tallyHeader}>
        <Text style={styles.progressLabel}>{label}</Text>
        <Text style={styles.progressValue}>
          {value} {unit}
        </Text>
      </View>
      <View style={styles.tallyMarksContainer}>
        {Array.from({ length: total }, (_, index) =>
          renderTallyMark(index, index < completed),
        )}
      </View>
    </View>
  );
};

export default function TimeProgressScreen() {
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const [headerSvgUri, setHeaderSvgUri] = useState(null);
  const [bottomSvgUri, setBottomSvgUri] = useState(null);

  const [perspective, setPerspective] = useState(null); // 'half-full' or 'half-empty'
  
  // Debug wrapper for setPerspective
  const debugSetPerspective = useCallback((newPerspective) => {
    console.log("setPerspective called with:", newPerspective, "from:", new Error().stack?.split('\n')[2]);
    setPerspective(newPerspective);
  }, []);
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
  const [showSettingsScreen, setShowSettingsScreen] = useState(false);
  const [timeMode, setTimeMode] = useState('24h'); // '24h' or '9-5'
  const [adLoaded, setAdLoaded] = useState(false);
  const [adTimeout, setAdTimeout] = useState(false);
  const [customEvents, setCustomEvents] = useState([]);
  const [selectedDisplayItems, setSelectedDisplayItems] = useState(['today', 'month', 'year']);
  const [showAddEvent, setShowAddEvent] = useState(false);
  const [newEventName, setNewEventName] = useState('');
  const [newEventDate, setNewEventDate] = useState('');
  const [timeData, setTimeData] = useState({
    yearProgress: 0,
    monthProgress: 0,
    dayProgress: 0,
    weekProgress: 0,
    quarterProgress: 0,
    yearCompleted: 0,
    monthCompleted: 0,
    dayCompleted: 0,
    weekCompleted: 0,
    quarterCompleted: 0,
    quarterNumber: 1,
    yearPercentLeft: 0,
    daysLeftInMonth: 0,
    daysLeftInWeek: 0,
    daysLeftInQuarter: 0,
    hoursLeftToday: 0,
    daysCrossed: 0,
    daysCrossedInWeek: 0,
    daysCrossedInQuarter: 0,
    hoursCompleted: 0,
    officeHoursCompleted: 0,
    officeHoursLeft: 0,
  });

  // Remove font loading since we're using system fonts

  // Load saved settings on app start
  useEffect(() => {
    const loadSettings = async () => {
      try {
        // Add a small delay to ensure AsyncStorage is ready
        await new Promise(resolve => setTimeout(resolve, 100));
        
        const savedPerspective = await AsyncStorage.getItem("userPerspective");
        const savedTimeMode = await AsyncStorage.getItem("timeMode");
        const savedDisplayItems = await AsyncStorage.getItem("selectedDisplayItems");
        
        console.log("Loading settings - savedPerspective:", savedPerspective, "savedTimeMode:", savedTimeMode, "savedDisplayItems:", savedDisplayItems);
        
        if (savedPerspective && savedPerspective !== 'null') {
          console.log("Setting perspective to:", savedPerspective);
          debugSetPerspective(savedPerspective);
          setHasCompletedOnboarding(true);
        }
        
        if (savedTimeMode && savedTimeMode !== 'null') {
          console.log("Setting timeMode to:", savedTimeMode);
          setTimeMode(savedTimeMode);
        }
        
        if (savedDisplayItems) {
          console.log("Setting display items to:", JSON.parse(savedDisplayItems));
          setSelectedDisplayItems(JSON.parse(savedDisplayItems));
        }
      } catch (error) {
        console.error("Error loading settings:", error);
      }
    };
    loadSettings();
  }, [debugSetPerspective]);

  // Initialize AdMob (Android only)
  useEffect(() => {
    if (Platform.OS === 'android' && MobileAds) {
      MobileAds()
        .setRequestConfiguration({
          // Set your test device IDs here
          testDeviceIdentifiers: ['EMULATOR'],
        })
        .then(() => {
          // Initialize the Google Mobile Ads SDK
          return MobileAds().initialize();
        })
        .then(() => {
          console.log('AdMob initialized successfully');
        })
        .catch((error) => {
          console.error('AdMob initialization failed:', error);
        });

      // Set ad timeout fallback
      const timer = setTimeout(() => {
        if (!adLoaded) {
          setAdTimeout(true);
        }
      }, 12000); // 12 seconds timeout

      return () => clearTimeout(timer);
    }
  }, [adLoaded]);

  const calculateTimeProgress = useCallback(() => {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();
    const currentDate = now.getDate();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    // Year progress
    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear + 1, 0, 1);
    const yearTotal = endOfYear - startOfYear;
    const yearElapsed = now - startOfYear;
    const yearProgress = (yearElapsed / yearTotal) * 100;
    const yearCompleted = Math.round(yearProgress);
    const yearPercentLeft = Math.round(100 - yearProgress);

    // Month progress
    const startOfMonth = new Date(currentYear, currentMonth, 1);
    const endOfMonth = new Date(currentYear, currentMonth + 1, 1);
    const monthTotal = endOfMonth - startOfMonth;
    const monthElapsed = now - startOfMonth;
    const monthProgress = (monthElapsed / monthTotal) * 100;
    const monthCompleted = Math.round(monthProgress);
    const daysLeftInMonth = Math.ceil(
      (endOfMonth - now) / (1000 * 60 * 60 * 24),
    );
    const daysCrossed = currentDate - 1; // Days that have been completed

    // Day progress (24-hour mode)
    const startOfDay = new Date(currentYear, currentMonth, currentDate);
    const endOfDay = new Date(currentYear, currentMonth, currentDate + 1);
    const dayTotal = endOfDay - startOfDay;
    const dayElapsed = now - startOfDay;
    const dayProgress = (dayElapsed / dayTotal) * 100;
    const dayCompleted = Math.round(dayProgress);
    const hoursLeftToday = Math.ceil((endOfDay - now) / (1000 * 60 * 60));
    const hoursCompleted = currentHour + (currentMinute > 30 ? 1 : 0); // Round to nearest hour

    // Office hours progress (9-5 mode)
    const startOfOfficeDay = new Date(currentYear, currentMonth, currentDate, 9, 0);
    const endOfOfficeDay = new Date(currentYear, currentMonth, currentDate, 17, 0);
    const officeHoursTotal = 8; // 9 AM to 5 PM = 8 hours
    let officeHoursCompleted = 0;
    let officeHoursLeft = 8;

    if (now >= startOfOfficeDay && now <= endOfOfficeDay) {
      // Currently in office hours
      const officeElapsed = now - startOfOfficeDay;
      officeHoursCompleted = Math.min(Math.floor(officeElapsed / (1000 * 60 * 60)), 8);
      officeHoursLeft = officeHoursTotal - officeHoursCompleted;
    } else if (now > endOfOfficeDay) {
      // Office hours completed
      officeHoursCompleted = 8;
      officeHoursLeft = 0;
    } else {
      // Before office hours
      officeHoursCompleted = 0;
      officeHoursLeft = 8;
    }

    // Week progress (Monday-Sunday)
    const dayOfWeek = now.getDay(); // 0 = Sunday, 1 = Monday, etc.
    const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Convert to Monday = 0
    const startOfWeek = new Date(currentYear, currentMonth, currentDate - daysSinceMonday);
    const endOfWeek = new Date(startOfWeek.getTime() + 7 * 24 * 60 * 60 * 1000);
    const weekTotal = endOfWeek - startOfWeek;
    const weekElapsed = now - startOfWeek;
    const weekProgress = (weekElapsed / weekTotal) * 100;
    const weekCompleted = Math.round(weekProgress);
    const daysLeftInWeek = Math.ceil((endOfWeek - now) / (1000 * 60 * 60 * 24));
    const daysCrossedInWeek = Math.floor((now - startOfWeek) / (1000 * 60 * 60 * 24));

    // Quarter progress (Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec)
    const quarterStartMonth = Math.floor(currentMonth / 3) * 3; // 0, 3, 6, or 9
    const quarterNumber = Math.floor(currentMonth / 3) + 1; // 1, 2, 3, or 4
    const startOfQuarter = new Date(currentYear, quarterStartMonth, 1);
    const endOfQuarter = new Date(currentYear, quarterStartMonth + 3, 1);
    const quarterTotal = endOfQuarter - startOfQuarter;
    const quarterElapsed = now - startOfQuarter;
    const quarterProgress = (quarterElapsed / quarterTotal) * 100;
    const quarterCompleted = Math.round(quarterProgress);
    const daysLeftInQuarter = Math.ceil((endOfQuarter - now) / (1000 * 60 * 60 * 24));
    const daysCrossedInQuarter = Math.floor((now - startOfQuarter) / (1000 * 60 * 60 * 24));

    setTimeData({
      yearProgress,
      monthProgress,
      dayProgress,
      weekProgress,
      quarterProgress,
      yearCompleted,
      monthCompleted,
      dayCompleted,
      weekCompleted,
      quarterCompleted,
      quarterNumber,
      yearPercentLeft,
      daysLeftInMonth,
      daysLeftInWeek,
      daysLeftInQuarter,
      hoursLeftToday,
      daysCrossed,
      daysCrossedInWeek,
      daysCrossedInQuarter,
      hoursCompleted,
      officeHoursCompleted,
      officeHoursLeft,
    });
  }, []);

  useEffect(() => {
    calculateTimeProgress();
    const interval = setInterval(calculateTimeProgress, 60000); // Update every minute
    return () => clearInterval(interval);
  }, [calculateTimeProgress]);

  // Custom Events CRUD Functions
  const loadCustomEvents = useCallback(async () => {
    try {
      const savedEvents = await AsyncStorage.getItem('customEvents');
      if (savedEvents) {
        setCustomEvents(JSON.parse(savedEvents));
      }
    } catch (error) {
      console.error('Error loading custom events:', error);
    }
  }, []);

  const saveCustomEvents = useCallback(async (events) => {
    try {
      await AsyncStorage.setItem('customEvents', JSON.stringify(events));
      setCustomEvents(events);
    } catch (error) {
      console.error('Error saving custom events:', error);
    }
  }, []);

  const addCustomEvent = useCallback(async (event) => {
    try {
      const newEvent = {
        id: Date.now().toString(),
        name: event.name,
        date: event.date,
        createdAt: new Date().toISOString(),
      };
      const updatedEvents = [...customEvents, newEvent];
      await saveCustomEvents(updatedEvents);
      
      // Update widget after custom events are saved
      updateWidgets();
    } catch (error) {
      console.error('Error adding custom event:', error);
    }
  }, [customEvents, saveCustomEvents]);

  const deleteCustomEvent = useCallback(async (eventId) => {
    try {
      const updatedEvents = customEvents.filter(event => event.id !== eventId);
      await saveCustomEvents(updatedEvents);
      
      // Update widget after custom events are saved
      updateWidgets();
    } catch (error) {
      console.error('Error deleting custom event:', error);
    }
  }, [customEvents, saveCustomEvents]);

  const calculateCustomEventProgress = useCallback((event) => {
    const now = new Date();
    
    // Parse the date string (YYYY-MM-DD format)
    const dateParts = event.date.split('-');
    const eventDate = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));
    
    // Set both dates to start of day to avoid timezone issues
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const eventDay = new Date(eventDate.getFullYear(), eventDate.getMonth(), eventDate.getDate());
    
    const diffTime = eventDay.getTime() - today.getTime();
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
    
    // Format date as DD/MM/YYYY
    const formattedDate = `${String(eventDate.getDate()).padStart(2, '0')}/${String(eventDate.getMonth() + 1).padStart(2, '0')}/${eventDate.getFullYear()}`;
    
    return {
      daysLeft: diffDays,
      isPast: diffDays < 0,
      isToday: diffDays === 0,
      formattedDate,
    };
  }, []);

  // Load custom events on app start
  useEffect(() => {
    loadCustomEvents();
  }, [loadCustomEvents]);

  // Load SVG assets
  useEffect(() => {
    const loadSvgs = async () => {
      try {
        const headerAsset = Asset.fromModule(require('../../assets/svg/header-sunskybird.svg'));
        const bottomAsset = Asset.fromModule(require('../../assets/svg/bottom-mountain.svg'));
        
        await Promise.all([headerAsset.downloadAsync(), bottomAsset.downloadAsync()]);
        
        setHeaderSvgUri(headerAsset.localUri || headerAsset.uri);
        setBottomSvgUri(bottomAsset.localUri || bottomAsset.uri);
      } catch (error) {
        console.error('Error loading SVG assets:', error);
      }
    };
    loadSvgs();
  }, []);

  // Display Items Management
  const handleDisplayItemToggle = useCallback(async (itemType) => {
    await Haptics.selectionAsync();
    
    if (selectedDisplayItems.includes(itemType)) {
      // Remove item
      const updatedItems = selectedDisplayItems.filter(item => item !== itemType);
      setSelectedDisplayItems(updatedItems);
      await AsyncStorage.setItem('selectedDisplayItems', JSON.stringify(updatedItems));
      // Update widget when settings change
      updateWidgets();
    } else if (selectedDisplayItems.length < 3) {
      // Add item
      const updatedItems = [...selectedDisplayItems, itemType];
      setSelectedDisplayItems(updatedItems);
      await AsyncStorage.setItem('selectedDisplayItems', JSON.stringify(updatedItems));
      // Update widget when settings change
      updateWidgets();
    }
  }, [selectedDisplayItems]);


  // Add Event Handler
  const formatDateInput = useCallback((input) => {
    // Remove all non-digits
    const digitsOnly = input.replace(/\D/g, '');
    
    if (digitsOnly.length === 0) return '';
    
    // Handle different input lengths
    if (digitsOnly.length <= 2) {
      return digitsOnly;
    } else if (digitsOnly.length <= 4) {
      return `${digitsOnly.slice(0, 2)}/${digitsOnly.slice(2)}`;
    } else {
      const day = digitsOnly.slice(0, 2);
      const month = digitsOnly.slice(2, 4);
      const year = digitsOnly.slice(4, 8);
      return `${day}/${month}/${year}`;
    }
  }, []);

  const convertToISODate = useCallback((dateString) => {
    // Handle empty input
    if (!dateString) return '';
    
    // Extract digits
    const digits = dateString.replace(/\D/g, '');
    if (digits.length !== 8) return '';
    
    const day = parseInt(digits.slice(0, 2));
    const month = parseInt(digits.slice(2, 4)) - 1; // JS months are 0-based
    const year = parseInt(digits.slice(4, 8));
    
    // Validate date components
    if (month < 0 || month > 11) return '';
    if (day < 1 || day > 31) return '';
    if (year < 2000 || year > 2100) return '';
    
    // Create and validate date object
    const date = new Date(year, month, day);
    if (isNaN(date.getTime())) return '';
    
    // Return ISO format YYYY-MM-DD
    return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }, []);

  const handleAddEvent = useCallback(async () => {
    const isoDate = convertToISODate(newEventDate);
    if (newEventName.trim() && isoDate) {
      await addCustomEvent({
        name: newEventName.trim(),
        date: isoDate,
      });
      setNewEventName('');
      setNewEventDate('');
      setShowAddEvent(false);
    } else {
      Alert.alert(
        "Invalid Date",
        "Please enter a valid date in DD/MM/YYYY format",
        [{ text: "OK" }]
      );
    }
  }, [newEventName, newEventDate, addCustomEvent, convertToISODate]);

  // Weekly Notifications - Only schedule once on app start
  const scheduleWeeklyNotification = useCallback(async () => {
    try {
      // Cancel existing weekly notifications first to reschedule with new settings
      await Notifications.cancelAllScheduledNotificationsAsync();

      // Request notification permissions
      const { status } = await Notifications.requestPermissionsAsync();
      if (status !== 'granted') {
        console.log('Notification permission not granted');
        return;
      }

      // Calculate next Monday at 9 AM
      const now = new Date();
      const dayOfWeek = now.getDay(); // 0 = Sunday, 1 = Monday, etc.
      const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek; // Days until next Monday
      const nextMonday = new Date(now);
      nextMonday.setDate(now.getDate() + daysUntilMonday);
      nextMonday.setHours(9, 0, 0, 0);

      // If it's already past 9 AM on Monday, schedule for next Monday
      if (dayOfWeek === 1 && now.getHours() >= 9) {
        nextMonday.setDate(nextMonday.getDate() + 7);
      }

      // Generate dynamic message based on current selected display items
      const progressMessage = generateWeeklyProgressMessage();

      // Schedule weekly notification with dynamic content
      await Notifications.scheduleNotificationAsync({
        content: {
          title: "📅 Weekly Progress Update",
          body: progressMessage,
          data: { type: 'weekly_progress' },
        },
        trigger: {
          date: nextMonday,
          repeats: true,
        },
      });

      console.log('Weekly notification scheduled for:', nextMonday);
      console.log('Notification message:', progressMessage);
    } catch (error) {
      console.error('Error scheduling weekly notification:', error);
    }
  }, [generateWeeklyProgressMessage]);


  const generateWeeklyProgressMessage = useCallback(() => {
    const messages = [];
    
    // Calculate current time data for notifications
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();
    const currentDate = now.getDate();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    // Calculate current progress values
    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear + 1, 0, 1);
    const yearTotal = endOfYear - startOfYear;
    const yearElapsed = now - startOfYear;
    const yearCompleted = Math.round((yearElapsed / yearTotal) * 100);

    const startOfMonth = new Date(currentYear, currentMonth, 1);
    const endOfMonth = new Date(currentYear, currentMonth + 1, 1);
    const monthTotal = endOfMonth - startOfMonth;
    const monthElapsed = now - startOfMonth;
    const monthCompleted = Math.round((monthElapsed / monthTotal) * 100);
    const daysCrossed = currentDate - 1;
    const daysLeftInMonth = Math.floor((endOfMonth - now) / (1000 * 60 * 60 * 24));

    const startOfWeek = new Date(now);
    const dayOfWeek = now.getDay();
    const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    startOfWeek.setDate(now.getDate() - daysFromMonday);
    startOfWeek.setHours(0, 0, 0, 0);
    const daysCrossedInWeek = Math.floor((now - startOfWeek) / (1000 * 60 * 60 * 24));
    const daysLeftInWeek = 7 - daysCrossedInWeek;

    const quarterNumber = Math.floor(currentMonth / 3) + 1;
    const startOfQuarter = new Date(currentYear, (quarterNumber - 1) * 3, 1);
    const endOfQuarter = new Date(currentYear, quarterNumber * 3, 1);
    const quarterTotal = endOfQuarter - startOfQuarter;
    const quarterElapsed = now - startOfQuarter;
    const quarterWeeksCompleted = Math.floor(Math.floor((now - startOfQuarter) / (1000 * 60 * 60 * 24)) / 7);
    const quarterWeeksLeft = 13 - quarterWeeksCompleted;

    const hoursCompleted = currentHour + (currentMinute > 30 ? 1 : 0);
    const hoursLeftToday = 24 - hoursCompleted;
    
    // Office hours calculation
    const startOfOfficeDay = new Date(currentYear, currentMonth, currentDate, 9, 0);
    const endOfOfficeDay = new Date(currentYear, currentMonth, currentDate, 17, 0);
    let officeHoursCompleted = 0;
    let officeHoursLeft = 8;
    if (now >= startOfOfficeDay && now <= endOfOfficeDay) {
      const officeElapsed = now - startOfOfficeDay;
      officeHoursCompleted = Math.min(Math.floor(officeElapsed / (1000 * 60 * 60)), 8);
      officeHoursLeft = 8 - officeHoursCompleted;
    } else if (now > endOfOfficeDay) {
      officeHoursCompleted = 8;
      officeHoursLeft = 0;
    }
    
    selectedDisplayItems.forEach(itemType => {
      switch (itemType) {
        case 'today':
          if (timeMode === '9-5') {
            if (perspective === 'half-full') {
              if (officeHoursCompleted > 0) {
                messages.push(`${officeHoursCompleted} office hours done`);
              } else {
                messages.push('Office day starting');
              }
            } else {
              if (officeHoursLeft > 0) {
                messages.push(`${officeHoursLeft} office hours left`);
              } else {
                messages.push('Office day done');
              }
            }
          } else {
            if (perspective === 'half-full') {
              if (hoursCompleted > 0) {
                messages.push(`${hoursCompleted} hours done today`);
              } else {
                messages.push('Day starting');
              }
            } else {
              if (hoursLeftToday > 0) {
                messages.push(`${hoursLeftToday} hours left today`);
              } else {
                messages.push('Day done');
              }
            }
          }
          break;
        case 'week':
          if (perspective === 'half-full') {
            if (daysCrossedInWeek > 0) {
              messages.push(`${daysCrossedInWeek} days done this week`);
            } else {
              messages.push('Week starting');
            }
          } else {
            if (daysLeftInWeek > 0) {
              messages.push(`${daysLeftInWeek} days left this week`);
            } else {
              messages.push('Week done');
            }
          }
          break;
        case 'month':
          if (perspective === 'half-full') {
            if (daysCrossed > 0) {
              messages.push(`${daysCrossed} days done this month`);
            } else {
              messages.push('Month starting');
            }
          } else {
            if (daysLeftInMonth > 0) {
              messages.push(`${daysLeftInMonth} days left this month`);
            } else {
              messages.push('Month done');
            }
          }
          break;
        case 'quarter':
          if (perspective === 'half-full') {
            if (quarterWeeksCompleted > 0) {
              messages.push(`${quarterWeeksCompleted} weeks done Q${quarterNumber}`);
            } else {
              messages.push(`Q${quarterNumber} starting`);
            }
          } else {
            if (quarterWeeksLeft > 0) {
              messages.push(`${quarterWeeksLeft} weeks left Q${quarterNumber}`);
            } else {
              messages.push(`Q${quarterNumber} done`);
            }
          }
          break;
        case 'year':
          if (perspective === 'half-full') {
            if (yearCompleted > 0) {
              messages.push(`${yearCompleted}% done this year`);
            } else {
              messages.push('Year starting');
            }
          } else {
            const yearLeft = 100 - yearCompleted;
            if (yearLeft > 0) {
              messages.push(`${yearLeft}% left this year`);
            } else {
              messages.push('Year done');
            }
          }
          break;
        case 'custom':
          // For custom events, show actual event details
          if (customEvents.length > 0) {
            customEvents.forEach(event => {
              const eventDate = new Date(event.date);
              const daysDiff = Math.floor((eventDate - now) / (1000 * 60 * 60 * 24));
              
              if (daysDiff > 0) {
                messages.push(`${daysDiff} days for ${event.name}`);
              } else if (daysDiff === 0) {
                messages.push(`Today: ${event.name}`);
              } else {
                messages.push(`${-daysDiff} days since ${event.name}`);
              }
            });
          } else {
            messages.push('No custom events');
          }
          break;
      }
    });

    return messages.join(' • ');
  }, [selectedDisplayItems, timeMode, perspective, customEvents]);

  // Schedule notifications only once on app start
  useEffect(() => {
    if (hasCompletedOnboarding) {
      scheduleWeeklyNotification();
    }
  }, [scheduleWeeklyNotification, hasCompletedOnboarding]);

  const handlePerspectiveSelect = useCallback(async (selectedPerspective) => {
    await Haptics.selectionAsync();
    console.log("handlePerspectiveSelect called with:", selectedPerspective);
    debugSetPerspective(selectedPerspective);
    setHasCompletedOnboarding(true);

    // Save perspective to storage
    try {
      await AsyncStorage.setItem("userPerspective", selectedPerspective);
      console.log("Successfully saved perspective:", selectedPerspective);
      
      // Verify the save worked
      const verifySave = await AsyncStorage.getItem("userPerspective");
      console.log("Verification - saved value:", verifySave);
    } catch (error) {
      console.error("Error saving perspective:", error);
    }
  }, []);

  const handleTimeModeChange = useCallback(async (mode) => {
    await Haptics.selectionAsync();
    console.log("handleTimeModeChange called with:", mode);
    setTimeMode(mode);

    // Save time mode to storage
    try {
      await AsyncStorage.setItem("timeMode", mode);
      console.log("Successfully saved timeMode:", mode);
      
      // Verify the save worked
      const verifySave = await AsyncStorage.getItem("timeMode");
      console.log("Verification - saved timeMode:", verifySave);
      
      // Update widget when settings change
      updateWidgets();
    } catch (error) {
      console.error("Error saving time mode:", error);
    }
  }, []);

  const handlePerspectiveChange = useCallback(async (newPerspective) => {
    await Haptics.selectionAsync();
    console.log("handlePerspectiveChange called with:", newPerspective);
    debugSetPerspective(newPerspective);

    // Save perspective to storage
    try {
      await AsyncStorage.setItem("userPerspective", newPerspective);
      console.log("Successfully saved perspective in settings:", newPerspective);
      
      // Verify the save worked
      const verifySave = await AsyncStorage.getItem("userPerspective");
      console.log("Verification - saved value:", verifySave);
      
      // Update widget when settings change
      updateWidgets();
      setShowSettings(false);
    } catch (error) {
      console.error("Error saving perspective:", error);
    }
  }, []);

  const renderCustomEventCounter = useCallback((event, perspective, index) => {
    const progress = calculateCustomEventProgress(event);
    let label, total, completed, value, unit;
    
    label = event.name;
    
    if (progress.isPast) {
      // For past events, show days since as completed tally marks
      total = Math.abs(progress.daysLeft);
      completed = Math.abs(progress.daysLeft);
      value = Math.abs(progress.daysLeft);
      unit = "days ago";
    } else if (progress.isToday) {
      // For today's events, show as a single tally mark
      total = 1;
      completed = 1;
      value = "Today!";
      unit = "";
    } else {
      // For future events, show days left with no completed marks
      total = progress.daysLeft;
      completed = 0;
      value = progress.daysLeft;
      unit = "days left";
    }

    return (
      <TallyCounter
        key={`custom-${event.id}-${index}`}
        total={total}
        completed={completed}
        label={label}
        value={value}
        unit={unit}
      />
    );
  }, [calculateCustomEventProgress]);

  const renderTallyCounter = useCallback(
    (itemType, perspective) => {
      let label, value, unit, total, completed;
        const now = new Date();

      switch (itemType) {
        case 'today':
          label = "Today";
        if (timeMode === '9-5') {
            total = 8;
          completed = timeData.officeHoursCompleted;
            value = perspective === "half-full" ? timeData.officeHoursCompleted : timeData.officeHoursLeft;
            unit = perspective === "half-full" ? "office hours done" : "office hours remaining";
        } else {
            total = 24;
          completed = timeData.hoursCompleted;
            value = perspective === "half-full" ? timeData.hoursCompleted : timeData.hoursLeftToday;
            unit = perspective === "half-full" ? "hours done" : "hours remaining";
          }
          break;

        case 'week':
          label = "This Week";
          total = 7;
          completed = timeData.daysCrossedInWeek;
          value = perspective === "half-full" ? timeData.daysCrossedInWeek : timeData.daysLeftInWeek;
          unit = perspective === "half-full" ? "days done" : "days remaining";
          break;

        case 'month':
          label = "This Month";
          const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
          total = daysInMonth;
          completed = timeData.daysCrossed;
          value = perspective === "half-full" ? timeData.daysCrossed : timeData.daysLeftInMonth;
          unit = perspective === "half-full" ? "days done" : "days remaining";
          break;

        case 'quarter':
          label = `Q${timeData.quarterNumber}`;
          // Calculate weeks in current quarter (approximately 13 weeks)
          const quarterStartMonth = Math.floor(now.getMonth() / 3) * 3;
          const startOfQuarter = new Date(now.getFullYear(), quarterStartMonth, 1);
          const endOfQuarter = new Date(now.getFullYear(), quarterStartMonth + 3, 1);
          const actualQuarterDays = Math.floor((endOfQuarter - startOfQuarter) / (1000 * 60 * 60 * 24));
          const quarterWeeks = Math.ceil(actualQuarterDays / 7); // Convert days to weeks
          total = quarterWeeks;
          const weeksCompleted = Math.floor(timeData.daysCrossedInQuarter / 7);
          const weeksLeft = Math.ceil(timeData.daysLeftInQuarter / 7);
          completed = weeksCompleted;
          value = perspective === "half-full" ? weeksCompleted : weeksLeft;
          unit = perspective === "half-full" ? "weeks done" : "weeks remaining";
          break;

        case 'year':
          label = "This Year";
          total = 12;
          completed = new Date().getMonth() + 1;
          value = perspective === "half-full" ? timeData.yearCompleted : timeData.yearPercentLeft;
          unit = perspective === "half-full" ? "% done" : "% remaining";
          break;

        case 'custom':
          // For custom events, show the first event only (others will be separate items)
          if (customEvents.length === 0) {
            label = "Custom Events";
            total = 0;
            completed = 0;
            value = 0;
            unit = "No events";
          } else {
            // Show the first custom event
            const event = customEvents[0];
            const progress = calculateCustomEventProgress(event);
            label = event.name;
            
            if (progress.isPast) {
              total = Math.abs(progress.daysLeft) + 30;
              completed = Math.abs(progress.daysLeft);
              value = progress.daysLeft;
              unit = "days ago";
            } else {
              total = progress.daysLeft;
              completed = 0;
              value = progress.daysLeft;
              unit = progress.isToday ? "Today!" : "days left";
            }
          }
          break;

        default:
          return null;
      }

      return (
        <TallyCounter
          total={total}
          completed={completed}
          label={label}
          value={value}
          unit={unit}
        />
      );
    },
    [timeData, timeMode, customEvents, calculateCustomEventProgress],
  );

  // Remove font loading check since we're using system fonts

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />

      {/* 1. Header SVG - Full width, below status bar */}
      {hasCompletedOnboarding && headerSvgUri && (
        <View style={[styles.headerSvgContainer, { top: insets.top }]}>
          <Image
            source={{ uri: headerSvgUri }}
            style={styles.headerSvgFull}
            contentFit="cover"
          />
          {/* Settings Icon overlay */}
          <View style={[styles.headerIconOverlay, { top: 10 }]}>
            <SettingsIcon onPress={() => setShowSettingsScreen(true)} />
          </View>
        </View>
      )}

      {/* ScrollView for middle content */}
      <ScrollView
        style={[
          styles.scrollView,
          {
            paddingTop: hasCompletedOnboarding && headerSvgUri ? (insets.top + 200) : (insets.top + 40),
            paddingBottom: hasCompletedOnboarding && bottomSvgUri ? 250 : (insets.bottom + 40),
          },
        ]}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {!hasCompletedOnboarding ? (
          /* Onboarding Section */
          <View style={styles.onboardingSection}>
            <View style={styles.glassContainer}>
              <WaterGlassIcon isHalfFull={true} />
            </View>

            <Text style={styles.questionText}>
              How do you see this glass?{'\n'}Your perspective shapes how you'll track time.
            </Text>

            <View style={styles.perspectiveButtons}>
              <TouchableOpacity
                onPress={() => handlePerspectiveSelect("half-full")}
                style={[styles.perspectiveButton, styles.halfFullButton]}
              >
                <Text style={[styles.perspectiveButtonText, styles.halfFullButtonText]}>Half Full</Text>
              </TouchableOpacity>

              <TouchableOpacity
                onPress={() => handlePerspectiveSelect("half-empty")}
                style={[styles.perspectiveButton, styles.halfEmptyButton]}
              >
                <Text style={[styles.perspectiveButtonText, styles.halfEmptyButtonText]}>Half Empty</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          /* 2. Middle Sections - Progress Items */
          <View style={styles.progressSectionContainer}>
            <View style={[styles.progressSection, isSmallScreen && styles.progressSectionScaled]}>
              {selectedDisplayItems.map((itemType) => {
                if (itemType === 'custom') {
                  // For custom, show ALL custom events as separate items
                  return customEvents.map((event, index) => 
                    renderCustomEventCounter(event, perspective, index)
                  );
                } else {
                  return renderTallyCounter(itemType, perspective);
                }
              }).flat()}
            </View>
          </View>
        )}
      </ScrollView>

      {/* 3. Bottom Mountain SVG - Full width, touches both ends */}
      {hasCompletedOnboarding && bottomSvgUri && (
        <View style={[styles.bottomMountainContainer, { 
          bottom: Platform.OS === 'android' && BannerAd && !adTimeout ? 70 : 0
        }]}>
          <Image
            source={{ uri: bottomSvgUri }}
            style={styles.bottomMountainImageFull}
            contentFit="cover"
          />
        </View>
      )}

      {/* Settings Full Screen Modal */}
      <Modal
        visible={showSettingsScreen}
        animationType="slide"
        presentationStyle="fullScreen"
        onRequestClose={() => setShowSettingsScreen(false)}
      >
        <View style={styles.settingsModalContainer}>
          <View style={styles.settingsModalHeader}>
            <Text style={styles.settingsScreenTitle}>Settings</Text>
            <TouchableOpacity 
              onPress={() => setShowSettingsScreen(false)}
              style={styles.closeButton}
            >
              <Text style={styles.closeButtonText}>✕</Text>
            </TouchableOpacity>
          </View>

          <ScrollView 
            style={styles.settingsScreenContent}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.settingsScreenScrollContent}
          >
            {/* AdMob Banner in Settings (Android only) */}
            {Platform.OS === 'android' && (
              <View style={styles.settingsAdContainer}>
            {BannerAd ? (
              <BannerAd
                    unitId={"ca-app-pub-9087069694782013/2019418042"}
                    size={BannerAdSize.BANNER}
                    onAdLoaded={() => {
                      console.log('Settings banner ad loaded');
                    }}
                    onAdFailedToLoad={(error) => {
                      console.error('Settings banner ad failed to load:', error);
                    }}
                  />
                ) : (
                  <View style={styles.settingsAdPlaceholder}>
                    <Text style={styles.adPlaceholderText}>Ad (settings)</Text>
                  </View>
                )}
              </View>
            )}
            
            {/* Perspective Setting */}
            <View style={styles.settingSection}>
              <Text style={styles.settingLabel}>Your Mindset</Text>
              <View style={styles.settingButtons}>
                <TouchableOpacity
                  onPress={() => handlePerspectiveChange("half-full")}
                  style={[
                    styles.settingButton,
                    perspective === "half-full" && styles.settingButtonActive,
                  ]}
                >
                  <Text style={[
                    styles.settingButtonText,
                    perspective === "half-full" && styles.settingButtonTextActive,
                  ]}>
                    Half Full
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handlePerspectiveChange("half-empty")}
                  style={[
                    styles.settingButton,
                    perspective === "half-empty" && styles.settingButtonActive,
                  ]}
                >
                  <Text style={[
                    styles.settingButtonText,
                    perspective === "half-empty" && styles.settingButtonTextActive,
                  ]}>
                    Half Empty
                  </Text>
                </TouchableOpacity>
              </View>
            </View>

            {/* Time Mode Setting */}
            <View style={styles.settingSection}>
              <Text style={styles.settingLabel}>Daily Tracking</Text>
              <View style={styles.settingButtons}>
                <TouchableOpacity
                  onPress={() => handleTimeModeChange("24h")}
                  style={[
                    styles.settingButton,
                    timeMode === "24h" && styles.settingButtonActive,
                  ]}
                >
                  <Text style={[
                    styles.settingButtonText,
                    timeMode === "24h" && styles.settingButtonTextActive,
                  ]}>
                    24 Hours
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handleTimeModeChange("9-5")}
                  style={[
                    styles.settingButton,
                    timeMode === "9-5" && styles.settingButtonActive,
                  ]}
                >
                  <Text style={[
                    styles.settingButtonText,
                    timeMode === "9-5" && styles.settingButtonTextActive,
                  ]}>
                    9-5 Office Hours
                  </Text>
                </TouchableOpacity>
              </View>
            </View>

            {/* Customize Display Section */}
            <View style={styles.settingSection}>
              <Text style={styles.settingLabel}>Customize Display</Text>
              <Text style={styles.settingDescription}>Choose 3 items to display</Text>
              
              <View style={styles.displayItemsContainer}>
                {['today', 'week', 'month', 'quarter', 'year', 'custom'].map((itemType) => {
                  const isSelected = selectedDisplayItems.includes(itemType);
                  const isDisabled = !isSelected && selectedDisplayItems.length >= 3;
                  
                  return (
                    <TouchableOpacity
                      key={itemType}
                      onPress={() => handleDisplayItemToggle(itemType)}
                      style={[
                        styles.displayItemButton,
                        isDisabled && styles.displayItemButtonDisabled,
                      ]}
                      disabled={isDisabled}
                    >
                      <View style={[
                        styles.checkbox,
                        isSelected && styles.checkboxActive
                      ]}>
                        {isSelected && <Text style={styles.checkmark}>✓</Text>}
                      </View>
                      <Text style={[
                        styles.displayItemButtonText,
                        isDisabled && styles.displayItemButtonTextDisabled,
                      ]}>
                        {itemType === 'today' ? 'Today' :
                         itemType === 'week' ? 'This Week' :
                         itemType === 'month' ? 'This Month' :
                         itemType === 'quarter' ? `Q${timeData.quarterNumber}` :
                         itemType === 'year' ? 'This Year' :
                         'Custom Events'}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
              
              {/* Show custom event fields when custom is selected */}
              {selectedDisplayItems.includes('custom') && (
                <View style={styles.customEventFields}>
                  <Text style={styles.customEventFieldsTitle}>Add Custom Events</Text>
                  <TouchableOpacity
                    onPress={() => setShowAddEvent(true)}
                    style={styles.addEventButton}
                  >
                    <Text style={styles.addEventButtonText}>+ Add Event</Text>
                  </TouchableOpacity>
                  {customEvents.map((event) => {
                    const progress = calculateCustomEventProgress(event);
                    return (
                      <View key={event.id} style={styles.eventItem}>
                        <View style={styles.eventDetails}>
                          <Text style={styles.eventName}>{event.name}</Text>
                          <Text style={styles.eventDateText}>{progress.formattedDate}</Text>
                        </View>
                        <View style={styles.eventStatus}>
                          <Text style={[
                            styles.eventStatusText,
                            progress.isToday && styles.eventStatusToday,
                            progress.isPast && styles.eventStatusPast
                          ]}>
                            {progress.isToday ? 'Today!' :
                             progress.isPast ? `${Math.abs(progress.daysLeft)} days ago` :
                             `${progress.daysLeft} days left`}
                          </Text>
                          <TouchableOpacity
                            onPress={() => deleteCustomEvent(event.id)}
                            style={styles.deleteEventButton}
                          >
                            <Text style={styles.deleteEventButtonText}>×</Text>
                          </TouchableOpacity>
                        </View>
                      </View>
                    );
                  })}
                </View>
              )}
            </View>

            {/* Notification Settings */}
            <View style={styles.settingSection}>
              <Text style={styles.settingLabel}>Notifications</Text>
              <Text style={styles.settingDescription}>Weekly progress updates every Monday at 9 AM based on your selected display items</Text>
            </View>

            {/* Widget Sync Button */}
            <View style={styles.settingSection}>
              <TouchableOpacity 
                style={styles.syncButton}
                onPress={() => {
                  updateWidgets();
                  Haptics.selectionAsync();
                }}
              >
                <Text style={styles.syncButtonText}>🔄 Sync to Widgets</Text>
              </TouchableOpacity>
              <Text style={styles.settingDescription}>Manually update your home screen widgets with current settings</Text>
            </View>
          </ScrollView>
        </View>
      </Modal>

      {/* Add Event Modal */}
      <Modal
        visible={showAddEvent}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowAddEvent(false)}
      >
        <View style={styles.addEventModalOverlay}>
          <View style={styles.addEventModalContainer}>
            <View style={styles.addEventModalHeader}>
              <Text style={styles.addEventModalTitle}>Add Custom Event</Text>
              <TouchableOpacity 
                onPress={() => {
                  setShowAddEvent(false);
                  setNewEventName('');
                  setNewEventDate('');
                }}
                style={styles.closeButton}
              >
                <Text style={styles.closeButtonText}>✕</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.addEventModalContent}>
              <Text style={styles.addEventLabel}>Event Name</Text>
              <TextInput
                style={styles.addEventInput}
                placeholder="e.g., Birthday, Wedding, Deadline"
                placeholderTextColor="#999"
                value={newEventName}
                onChangeText={setNewEventName}
                autoFocus={true}
              />

              <Text style={[styles.addEventLabel, { marginTop: 20 }]}>Date (DD/MM/YYYY)</Text>
              <TextInput
                style={styles.addEventInput}
                placeholder="DD/MM/YYYY"
                placeholderTextColor="#999"
                value={newEventDate}
                onChangeText={(text) => {
                  const formatted = formatDateInput(text);
                  setNewEventDate(formatted);
                }}
                keyboardType="numeric"
                maxLength={10}
              />

              <TouchableOpacity
                onPress={handleAddEvent}
                style={[
                  styles.addEventSubmitButton,
                  (!newEventName.trim() || !newEventDate.trim()) && styles.addEventSubmitButtonDisabled
                ]}
                disabled={!newEventName.trim() || !newEventDate.trim()}
              >
                <Text style={styles.addEventSubmitButtonText}>Add Event</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* AdMob Banner (Android only) */}
      {Platform.OS === 'android' && (
        <View style={[styles.bannerContainer, { paddingBottom: Math.max(insets.bottom, 16) }]}>
          {BannerAd && !adTimeout ? (
            <BannerAd
              unitId={"ca-app-pub-9087069694782013/2019418042"}
              size={BannerAdSize.ANCHORED_ADAPTIVE_BANNER}
              onAdLoaded={() => {
                console.log('Banner ad loaded');
                setAdLoaded(true);
              }}
              onAdFailedToLoad={(error) => {
                console.error('Banner ad failed to load:', error);
                setAdTimeout(true);
              }}
            />
          ) : (
            <View style={styles.adPlaceholder}>
              <Text style={styles.adPlaceholderText}>Ad (test)</Text>
            </View>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#ffffff",
  },
  headerSvgContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 200,
    zIndex: 10,
    overflow: 'hidden',
    width: '100%',
  },
  headerSvgFull: {
    width: '100%',
    height: '100%',
    alignSelf: 'stretch',
  },
  headerIconOverlay: {
    position: 'absolute',
    right: 20,
    top: 10,
    zIndex: 11,
  },
  content: {
    flex: 1,
    paddingHorizontal: 32,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 40,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: "flex-start",
    paddingTop: 20,
    paddingBottom: 10,
  },
  settingsModalContainer: {
    flex: 1,
    backgroundColor: '#ffffff',
    paddingTop: Platform.OS === 'ios' ? 50 : 20,
  },
  settingsModalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  settingsScreenTitle: {
    fontFamily: 'Kalam-Bold',
    fontSize: 24,
    color: '#000000',
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    fontSize: 18,
    color: '#333333',
    fontWeight: '600',
  },
  settingsScreenContent: {
    flex: 1,
  },
  settingsScreenScrollContent: {
    paddingHorizontal: 24,
    paddingBottom: 20,
  },
  onboardingSection: {
    alignItems: "center",
  },
  glassContainer: {
    marginBottom: 50,
    alignItems: "center",
  },
  questionText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 22,
    marginBottom: 50,
    textAlign: "center",
    lineHeight: 32,
    color: "#222222",
  },
  perspectiveButtons: {
    flexDirection: "row",
    gap: 20,
  },
  perspectiveButton: {
    paddingHorizontal: 28,
    paddingVertical: 18,
    borderRadius: 30,
    borderWidth: 2,
    minWidth: 130,
    alignItems: "center",
  },
  halfFullButton: {
    backgroundColor: "#ffffff",
    borderColor: "#222222",
  },
  halfEmptyButton: {
    backgroundColor: "#222222",
    borderColor: "#222222",
  },
  perspectiveButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
  },
  halfFullButtonText: {
    color: "#222222", // Black text on white background
  },
  halfEmptyButtonText: {
    color: "#ffffff", // White text on black background
  },
  progressWrapper: {
    width: '100%',
    alignSelf: 'stretch',
  },
  topVisuals: {
    height: 150,
    marginBottom: 20,
    overflow: 'hidden',
  },
  headerSvg: {
    width: '100%',
    height: '100%',
  },
  bottomVisuals: {
    height: 150,
    marginTop: 20,
    overflow: 'hidden',
    alignSelf: 'stretch',
  },
  bottomSvg: {
    width: '100%',
    height: '100%',
  },
  bottomMountainContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 200,
    overflow: 'hidden',
    zIndex: 0,
    width: '100%',
  },
  bottomMountainImageFull: {
    width: '100%',
    height: '100%',
    alignSelf: 'stretch',
  },
  progressSectionContainer: {
    width: '100%',
    alignItems: 'center',
    marginTop: -30,
  },
  progressSection: {
    gap: 60,
    width: '100%',
  },
  progressSectionScaled: {
    transform: [{ scale: 0.8 }],
    width: '125%', // Compensate for 0.8 scale to maintain width
    marginVertical: -10,
  },
  tallyContainer: {
    gap: 16,
  },
  tallyHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  progressLabel: {
    fontFamily: 'Kalam-Regular',
    fontSize: 18,
    color: "#666666",
  },
  progressValue: {
    fontFamily: 'Kalam-Bold',
    fontSize: 18,
    color: "#222222",
  },
  tallyMarksContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 16,
    justifyContent: "flex-start",
  },
  tallyMark: {
    position: "relative",
    width: 4,
    height: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  tallyLine: {
    width: 3,
    height: 20,
    backgroundColor: "rgba(34, 34, 34, 0.65)",
    borderRadius: 1.5,
  },
  crossLine: {
    position: "absolute",
    width: 2.5,
    height: 24,
    backgroundColor: "rgba(34, 34, 34, 0.4)",
    borderRadius: 1,
    transform: [{ rotate: "45deg" }],
  },
  header: {
    position: "absolute",
    right: 20,
    zIndex: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  widgetButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  widgetButtonText: {
    fontSize: 18,
  },
  settingsButton: {
    padding: 8,
    borderRadius: 20,
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "center",
  },
  modalContent: {
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 24,
    margin: 20,
    maxWidth: 320,
    width: "90%",
    maxHeight: "80%",
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 4,
  },
  settingsScrollView: {
    maxHeight: 500,
  },
  settingsScrollContent: {
    paddingBottom: 20,
    flexGrow: 1,
  },
  modalTitle: {
    fontFamily: 'Kalam-Bold',
    fontSize: 20,
    color: "#000000",
    textAlign: "center",
    marginBottom: 24,
  },
  settingSection: {
    marginBottom: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#f0f0f0",
  },
  settingLabel: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: "#000000",
    marginBottom: 8,
    fontWeight: "600",
  },
  settingDescription: {
    fontFamily: 'Kalam-Regular',
    fontSize: 12,
    color: "#666666",
    marginBottom: 12,
  },
  settingButtons: {
    flexDirection: "row",
    gap: 12,
  },
  settingButton: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#000000",
    backgroundColor: "#ffffff",
    alignItems: "center",
  },
  settingButtonActive: {
    backgroundColor: "#000000",
  },
  settingButtonText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 12,
    color: "#000000",
  },
  settingButtonTextActive: {
    color: "#ffffff",
  },
  closeButton: {
    marginTop: 16,
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 6,
    backgroundColor: '#000000',
    alignItems: 'center',
  },
  closeButtonText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#ffffff',
  },
  syncButton: {
    marginTop: 16,
    marginBottom: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  syncButtonText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 16,
    color: '#000000',
    textDecorationLine: 'underline',
  },
  bannerContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#ffffff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    alignItems: 'center',
    paddingTop: 8,
    zIndex: 10,
  },
  adPlaceholder: {
    height: 50,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 16,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderStyle: 'dashed',
  },
  adPlaceholderText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#999999',
  },
  settingsAdContainer: {
    marginVertical: 16,
    alignItems: 'center',
    borderRadius: 8,
    overflow: 'hidden',
  },
  settingsAdPlaceholder: {
    height: 50,
    width: '100%',
    backgroundColor: '#f8f8f8',
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#e8e8e8',
    borderStyle: 'dashed',
  },
  settingDescription: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
  },
  displayItemsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    justifyContent: 'center',
  },
  displayItemButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
    backgroundColor: '#ffffff',
    marginBottom: 8,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: '#000000',
    marginRight: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxActive: {
    backgroundColor: '#000000',
  },
  checkmark: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  displayItemButtonDisabled: {
    opacity: 0.3,
  },
  displayItemButtonText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#000000',
  },
  displayItemButtonTextDisabled: {
    color: '#666666',
  },
  addEventButton: {
    backgroundColor: '#000000',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 6,
    alignItems: 'center',
    marginBottom: 12,
  },
  addEventButtonText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 12,
    color: '#ffffff',
  },
  customEventFields: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  customEventFieldsTitle: {
    fontFamily: 'Kalam-Regular',
    fontSize: 12,
    color: '#000000',
    marginBottom: 8,
    fontWeight: '600',
  },
  eventItem: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#f8f8f8',
    borderRadius: 8,
    marginBottom: 8,
  },
  eventDetails: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  eventName: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#222',
    flex: 1,
  },
  eventDateText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#666',
  },
  eventStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  eventStatusText: {
    fontFamily: 'Kalam-Regular',
    fontSize: 14,
    color: '#666',
  },
  eventStatusToday: {
    color: '#000000',
    fontWeight: 'bold',
  },
  eventStatusPast: {
    color: '#999',
  },
  deleteEventButton: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  deleteEventButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#ffffff',
  },
  inputContainer: {
    marginBottom: 20,
  },
  inputLabel: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#222',
    marginBottom: 8,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'Kalam-Regular',
    fontSize: 16,
    color: '#222',
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#f8f8f8',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  saveButton: {
    backgroundColor: '#000000',
  },
  cancelButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#666',
  },
  saveButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#fff',
  },
  notificationButton: {
    backgroundColor: '#000000',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 16,
  },
  notificationButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#ffffff',
  },
  addEventModalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  addEventModalContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    width: '100%',
    maxWidth: 400,
    maxHeight: '80%',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 8,
  },
  addEventModalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  addEventModalTitle: {
    fontFamily: 'Kalam-Bold',
    fontSize: 20,
    color: '#000000',
  },
  addEventModalContent: {
    padding: 20,
  },
  addEventLabel: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#222222',
    marginBottom: 8,
  },
  addEventInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'Kalam-Regular',
    fontSize: 16,
    color: '#222',
    backgroundColor: '#ffffff',
  },
  addEventSubmitButton: {
    backgroundColor: '#000000',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 24,
  },
  addEventSubmitButtonDisabled: {
    backgroundColor: '#ccc',
    opacity: 0.6,
  },
  addEventSubmitButtonText: {
    fontFamily: 'Kalam-Bold',
    fontSize: 16,
    color: '#ffffff',
  },
});
