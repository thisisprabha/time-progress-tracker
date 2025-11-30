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
  useColorScheme,
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
import AnimatedHeader from '../components/AnimatedHeader';
import { Lock } from 'lucide-react-native';

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

// Helper component to render text - using system font for now
const SmartText = ({ style, children, ...props }) => {
  return <Text style={style} {...props}>{children}</Text>;
};

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

// Helper function to add double spaces between words
const addDoubleSpaces = (text) => {
  return text.replace(/\s+/g, '  ');
};

const TallyCounter = ({ total, completed, label, value, unit, themeColors }) => {
  const renderTallyMark = (index, isCrossed) => (
    <View key={index} style={styles.tallyMark}>
      {/* Vertical line */}
      <View style={[styles.tallyLine, { backgroundColor: themeColors.textSecondary }]} />
      {/* Cross line if completed */}
      {isCrossed && <View style={[styles.crossLine, { backgroundColor: themeColors.textSecondary }]} />}
    </View>
  );

  return (
    <View style={styles.tallyContainer}>
      <View style={styles.tallyHeader}>
        <Text style={[styles.progressLabel, { color: themeColors.textSecondary }]}>{addDoubleSpaces(label)}</Text>
        <View style={{ flexDirection: 'row', alignItems: 'baseline' }}>
          <Text style={[styles.progressValueBold, { color: themeColors.text }]}>{value}</Text>
          {unit && <Text style={[styles.progressValueBold, { color: themeColors.text }]}>  {addDoubleSpaces(unit)}</Text>}
        </View>
      </View>
      <View style={styles.tallyMarksContainer}>
        {Array.from({ length: total }, (_, index) =>
          renderTallyMark(index, index < completed),
        )}
      </View>
    </View>
  );
};

const EmptyCustomEventsView = ({ onPress, themeColors }) => (
  <TouchableOpacity onPress={onPress} style={styles.emptyEventContainer}>
    <View style={styles.emptyEventContent}>
      <Lock size={24} color={themeColors.textSecondary} style={{ opacity: 0.5, marginBottom: 8 }} />
      <View style={{ alignItems: 'center' }}>
        <Text style={[styles.emptyEventText, { color: themeColors.textSecondary }]}>Create custom events</Text>
        <Text style={[styles.emptyEventText, { color: themeColors.textSecondary }]}>to track</Text>
      </View>
      <View style={styles.addYoursButton}>
        <Text style={styles.addYoursText}>Add yours</Text>
      </View>
    </View>
  </TouchableOpacity>
);

export default function TimeProgressScreen() {
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  // Force light theme - disable dark mode
  const isDark = false;
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
  const [customEvents, setCustomEvents] = useState([]);
  const [selectedDisplayItems, setSelectedDisplayItems] = useState(['today']);
  const [showAddEvent, setShowAddEvent] = useState(false);
  const [newEventName, setNewEventName] = useState('');
  const [newEventDate, setNewEventDate] = useState('');
  const [showWidgetPrompt, setShowWidgetPrompt] = useState(false);
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
        const widgetPromptShown = await AsyncStorage.getItem("widgetPromptShown");

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

        // Check if widget prompt should be shown (first time after onboarding)
        if (!widgetPromptShown && savedPerspective && savedPerspective !== 'null') {
          setShowWidgetPrompt(true);
        }

        // Update widgets on app start to ensure they have latest data
        if (savedPerspective && savedPerspective !== 'null') {
          updateWidgets();
        }
      } catch (error) {
        console.error("Error loading settings:", error);
      }
    };
    loadSettings();
  }, [debugSetPerspective]);

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
        const events = JSON.parse(savedEvents);
        setCustomEvents(events);
        // Schedule notifications for loaded events
        await scheduleEventNotifications(events);
      }
    } catch (error) {
      console.error('Error loading custom events:', error);
    }
  }, [scheduleEventNotifications]);

  const saveCustomEvents = useCallback(async (events) => {
    try {
      await AsyncStorage.setItem('customEvents', JSON.stringify(events));
      setCustomEvents(events);
    } catch (error) {
      console.error('Error saving custom events:', error);
    }
  }, []);

  // Schedule day-before notifications for custom events
  const scheduleEventNotifications = useCallback(async (events) => {
    try {
      // Cancel all existing event notifications (keep only weekly notifications)
      const allNotifications = await Notifications.getAllScheduledNotificationsAsync();
      for (const notification of allNotifications) {
        if (notification.content.data?.type === 'event_reminder') {
          await Notifications.cancelScheduledNotificationAsync(notification.identifier);
        }
      }

      // Schedule new notifications for each event
      for (const event of events) {
        const dateParts = event.date.split('-');
        const eventDate = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));

        // Calculate day before event at 9 AM
        const dayBefore = new Date(eventDate);
        dayBefore.setDate(eventDate.getDate() - 1);
        dayBefore.setHours(9, 0, 0, 0);

        // Only schedule if day before is in the future
        const now = new Date();
        if (dayBefore > now) {
          await Notifications.scheduleNotificationAsync({
            content: {
              title: "📅 Upcoming Event",
              body: `${event.name} is tomorrow`,
              data: { type: 'event_reminder', eventId: event.id },
            },
            trigger: {
              date: dayBefore,
            },
          });
          console.log(`Scheduled notification for ${event.name} on ${dayBefore}`);
        }
      }
    } catch (error) {
      console.error('Error scheduling event notifications:', error);
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

      // Schedule notifications for all events
      await scheduleEventNotifications(updatedEvents);

      // If custom events count + custom display item = 3, remove other display items
      const currentItems = selectedDisplayItems.includes('custom')
        ? selectedDisplayItems
        : [...selectedDisplayItems, 'custom'];

      // Count total display items (custom events count as separate items)
      const totalDisplayCount = updatedEvents.length + (currentItems.filter(item => item !== 'custom').length);

      if (totalDisplayCount > 3) {
        // Keep only 'custom' and remove others to maintain max 3
        const newDisplayItems = ['custom'];
        await AsyncStorage.setItem('selectedDisplayItems', JSON.stringify(newDisplayItems));
        setSelectedDisplayItems(newDisplayItems);
      } else if (!selectedDisplayItems.includes('custom')) {
        // Add 'custom' if not already present
        const newDisplayItems = [...selectedDisplayItems, 'custom'];
        await AsyncStorage.setItem('selectedDisplayItems', JSON.stringify(newDisplayItems));
        setSelectedDisplayItems(newDisplayItems);
      }

      // Update widget after custom events are saved
      updateWidgets();
    } catch (error) {
      console.error('Error adding custom event:', error);
    }
  }, [customEvents, saveCustomEvents, selectedDisplayItems, scheduleEventNotifications]);

  const deleteCustomEvent = useCallback(async (eventId) => {
    try {
      const updatedEvents = customEvents.filter(event => event.id !== eventId);
      await saveCustomEvents(updatedEvents);

      // Reschedule notifications for remaining events
      await scheduleEventNotifications(updatedEvents);

      // Update widget after custom events are saved
      updateWidgets();
    } catch (error) {
      console.error('Error deleting custom event:', error);
    }
  }, [customEvents, saveCustomEvents, scheduleEventNotifications]);

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

    // Calculate weeks for events > 30 days
    const weeksLeft = Math.ceil(Math.abs(diffDays) / 7);
    const useWeeks = Math.abs(diffDays) > 30;

    // Format date as DD/MM/YYYY
    const formattedDate = `${String(eventDate.getDate()).padStart(2, '0')}/${String(eventDate.getMonth() + 1).padStart(2, '0')}/${eventDate.getFullYear()}`;

    return {
      daysLeft: diffDays,
      weeksLeft: weeksLeft,
      useWeeks: useWeeks,
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
            unit = perspective === "half-full" ? "office  hrs  gone" : "office  hrs  only  left";
          } else {
            total = 24;
            completed = timeData.hoursCompleted;
            value = perspective === "half-full" ? timeData.hoursCompleted : timeData.hoursLeftToday;
            unit = perspective === "half-full" ? "hrs  gone" : "hrs  only  left";
          }
          break;

        case 'week':
          label = "This Week";
          total = 7;
          completed = timeData.daysCrossedInWeek;
          value = perspective === "half-full" ? timeData.daysCrossedInWeek : timeData.daysLeftInWeek;
          unit = perspective === "half-full" ? "d  gone" : "d  only  left";
          break;

        case 'month':
          label = "This Month";
          const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
          total = daysInMonth;
          completed = timeData.daysCrossed;
          value = perspective === "half-full" ? timeData.daysCrossed : timeData.daysLeftInMonth;
          unit = perspective === "half-full" ? "d  gone" : "d  only  left";
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
          unit = perspective === "half-full" ? "wk  gone" : "wk  only  left";
          break;

        case 'year':
          label = "This Year";
          total = 12;
          completed = new Date().getMonth() + 1;
          value = perspective === "half-full" ? timeData.yearCompleted : timeData.yearPercentLeft;
          unit = perspective === "half-full" ? "%  gone" : "%  only  left";
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
              if (progress.useWeeks) {
                total = progress.weeksLeft;
                completed = progress.weeksLeft;
                value = progress.weeksLeft;
                unit = "wk  ago";
              } else {
                total = Math.abs(progress.daysLeft);
                completed = Math.abs(progress.daysLeft);
                value = Math.abs(progress.daysLeft);
                unit = "d  ago";
              }
            } else {
              if (progress.useWeeks) {
                total = progress.weeksLeft;
                completed = 0;
                value = progress.weeksLeft;
                unit = "wk  only  left";
              } else {
                total = progress.daysLeft;
                completed = 0;
                value = progress.daysLeft;
                unit = progress.isToday ? "Today!" : "d  only  left";
              }
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
          themeColors={themeColors}
        />
      );
    },
    [timeData, timeMode, customEvents, calculateCustomEventProgress, themeColors],
  );

  // Remove font loading check since we're using system fonts

  // Theme colors based on system theme
  const themeColors = {
    background: isDark ? '#000000' : '#ffffff',
    text: isDark ? '#ffffff' : '#000000',
    textSecondary: isDark ? '#cccccc' : '#666666',
    border: isDark ? '#333333' : '#e0e0e0',
  };

  // Update render functions to use themeColors (defined above)
  const renderCustomEventCounterWithTheme = useCallback((event, perspective, index) => {
    const progress = calculateCustomEventProgress(event);
    let label, total, completed, value, unit;

    label = event.name;

    if (progress.isPast) {
      // For past events, use weeks if > 30 days, otherwise days
      if (progress.useWeeks) {
        total = progress.weeksLeft;
        completed = progress.weeksLeft;
        value = progress.weeksLeft;
        unit = "weeks ago";
      } else {
        total = Math.abs(progress.daysLeft);
        completed = Math.abs(progress.daysLeft);
        value = Math.abs(progress.daysLeft);
        unit = "days ago";
      }
    } else if (progress.isToday) {
      // For today's events, show as a single tally mark
      total = 1;
      completed = 1;
      value = "Today!";
      unit = "";
    } else {
      // For future events, use weeks if > 30 days, otherwise days
      if (progress.useWeeks) {
        total = progress.weeksLeft;
        completed = 0;
        value = progress.weeksLeft;
        unit = "weeks left";
      } else {
        total = progress.daysLeft;
        completed = 0;
        value = progress.daysLeft;
        unit = "days left";
      }
    }

    return (
      <TallyCounter
        key={`custom-${event.id}-${index}`}
        total={total}
        completed={completed}
        label={label}
        value={value}
        unit={unit}
        themeColors={themeColors}
      />
    );
  }, [calculateCustomEventProgress, themeColors]);

  const renderTallyCounterWithTheme = useCallback(
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
            unit = perspective === "half-full" ? "office  hrs  gone" : "office  hrs  only  left";
          } else {
            total = 24;
            completed = timeData.hoursCompleted;
            value = perspective === "half-full" ? timeData.hoursCompleted : timeData.hoursLeftToday;
            unit = perspective === "half-full" ? "hrs  gone" : "hrs  only  left";
          }
          break;

        case 'week':
          label = "This Week";
          total = 7;
          completed = timeData.daysCrossedInWeek;
          value = perspective === "half-full" ? timeData.daysCrossedInWeek : timeData.daysLeftInWeek;
          unit = perspective === "half-full" ? "d  gone" : "d  only  left";
          break;

        case 'month':
          label = "This Month";
          const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
          total = daysInMonth;
          completed = timeData.daysCrossed;
          value = perspective === "half-full" ? timeData.daysCrossed : timeData.daysLeftInMonth;
          unit = perspective === "half-full" ? "d  gone" : "d  only  left";
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
          unit = perspective === "half-full" ? "wk  gone" : "wk  only  left";
          break;

        case 'year':
          label = "This Year";
          total = 12;
          completed = new Date().getMonth() + 1;
          value = perspective === "half-full" ? timeData.yearCompleted : timeData.yearPercentLeft;
          unit = perspective === "half-full" ? "%  gone" : "%  only  left";
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
              if (progress.useWeeks) {
                total = progress.weeksLeft;
                completed = progress.weeksLeft;
                value = progress.weeksLeft;
                unit = "wk  ago";
              } else {
                total = Math.abs(progress.daysLeft);
                completed = Math.abs(progress.daysLeft);
                value = Math.abs(progress.daysLeft);
                unit = "d  ago";
              }
            } else {
              if (progress.useWeeks) {
                total = progress.weeksLeft;
                completed = 0;
                value = progress.weeksLeft;
                unit = "wk  only  left";
              } else {
                total = progress.daysLeft;
                completed = 0;
                value = progress.daysLeft;
                unit = progress.isToday ? "Today!" : "d  only  left";
              }
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
          themeColors={themeColors}
        />
      );
    },
    [timeData, timeMode, customEvents, calculateCustomEventProgress, themeColors, perspective],
  );

  return (
    <View style={[styles.container, { backgroundColor: themeColors.background }]}>
      <StatusBar style={isDark ? "light" : "dark"} />

      {/* 1. Animated Header - Full width, below status bar */}
      {hasCompletedOnboarding && (
        <View style={[styles.headerSvgContainer, { top: insets.top + 10 }]}>
          <AnimatedHeader />
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
            paddingBottom: insets.bottom + 40,
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

            <SmartText style={[styles.questionText, { color: themeColors.text }]}>
              How do you see this glass?{'\n'}Your perspective shapes how you'll track time.
            </SmartText>

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
              {(() => {
                // Calculate rendered items
                const renderedItems = [];

                selectedDisplayItems.forEach(itemType => {
                  if (itemType === 'custom') {
                    customEvents.forEach((event, index) => {
                      renderedItems.push(renderCustomEventCounterWithTheme(event, perspective, index));
                    });
                  } else {
                    renderedItems.push(renderTallyCounterWithTheme(itemType, perspective));
                  }
                });

                // Always show 3 cards total - fill remaining with unlock cards
                const slotsNeeded = 3 - renderedItems.length;
                for (let i = 0; i < slotsNeeded; i++) {
                  renderedItems.push(
                    <EmptyCustomEventsView
                      key={`empty-${i}`}
                      onPress={() => setShowAddEvent(true)}
                      themeColors={themeColors}
                    />
                  );
                }

                return renderedItems;
              })()}
            </View>
          </View>
        )}
      </ScrollView>

      {/* 3. Bottom Mountain SVG - Hidden for now */}
      {/* {hasCompletedOnboarding && bottomSvgUri && (
        <View style={[styles.bottomMountainContainer]}>
          <Image
            source={{ uri: bottomSvgUri }}
            style={[
              styles.bottomMountainImageFull, 
              { 
                opacity: 0.5,
                tintColor: isDark ? '#ffffff' : undefined // Invert black to white in dark mode
              }
            ]}
            contentFit="cover"
          />
        </View>
      )} */}

      {/* Widget Prompt Modal - Shows on first settings open */}
      <Modal
        visible={showWidgetPrompt}
        transparent={true}
        animationType="fade"
        onRequestClose={() => {
          setShowWidgetPrompt(false);
          AsyncStorage.setItem("widgetPromptShown", "true");
        }}
      >
        <View style={styles.widgetPromptOverlay}>
          <View style={[styles.widgetPromptContainer, { backgroundColor: themeColors.background, borderColor: themeColors.border }]}>
            <Text style={[styles.widgetPromptTitle, { color: themeColors.text }]}>
              Widgets Keep You Motivated
            </Text>
            <Text style={[styles.widgetPromptText, { color: themeColors.textSecondary }]}>
              To add widget: Long press home screen → Widgets → Time Progress Tracker → Select widget size
            </Text>
            <TouchableOpacity
              style={[styles.widgetPromptButton, { backgroundColor: themeColors.text, borderColor: themeColors.border }]}
              onPress={() => {
                setShowWidgetPrompt(false);
                AsyncStorage.setItem("widgetPromptShown", "true");
                // Dismiss prompt - user needs to manually add widget from home screen
                // Long press home screen → Widgets → Time Progress Tracker
              }}
            >
              <Text style={[styles.widgetPromptButtonText, { color: themeColors.background }]}>
                Got It
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.widgetPromptDismiss}
              onPress={() => {
                setShowWidgetPrompt(false);
                AsyncStorage.setItem("widgetPromptShown", "true");
              }}
            >
              <Text style={[styles.widgetPromptDismissText, { color: themeColors.textSecondary }]}>
                Dismiss
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Settings Full Screen Modal */}
      <Modal
        visible={showSettingsScreen}
        animationType="slide"
        presentationStyle="fullScreen"
        onRequestClose={() => setShowSettingsScreen(false)}
      >
        <View style={[styles.settingsModalContainer, { backgroundColor: themeColors.background }]}>
          <View style={[styles.settingsModalHeader, { borderBottomColor: themeColors.border }]}>
            <SmartText style={[styles.settingsScreenTitle, { color: themeColors.text }]}>Settings</SmartText>
            <TouchableOpacity
              onPress={() => setShowSettingsScreen(false)}
              style={styles.closeButton}
            >
              <Text style={[styles.closeButtonText, { color: themeColors.text }]}>✕</Text>
            </TouchableOpacity>
          </View>

          <ScrollView
            style={styles.settingsScreenContent}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.settingsScreenScrollContent}
          >

            {/* Perspective Setting */}
            <View style={styles.settingSection}>
              <SmartText style={[styles.settingSectionHeading, { color: themeColors.text }]}>Your  Mindset</SmartText>
              <View style={styles.settingButtons}>
                <TouchableOpacity
                  onPress={() => handlePerspectiveChange("half-full")}
                  style={[
                    styles.settingButton,
                    {
                      backgroundColor: perspective === "half-full" ? 'transparent' : themeColors.border,
                      borderColor: perspective === "half-full" ? themeColors.text : themeColors.border,
                      borderWidth: perspective === "half-full" ? 2 : 1,
                    },
                  ]}
                >
                  <SmartText style={[
                    styles.settingButtonText,
                    { color: perspective === "half-full" ? themeColors.text : themeColors.textSecondary },
                  ]}>
                    Half Full
                  </SmartText>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handlePerspectiveChange("half-empty")}
                  style={[
                    styles.settingButton,
                    {
                      backgroundColor: perspective === "half-empty" ? 'transparent' : themeColors.border,
                      borderColor: perspective === "half-empty" ? themeColors.text : themeColors.border,
                      borderWidth: perspective === "half-empty" ? 2 : 1,
                    },
                  ]}
                >
                  <SmartText style={[
                    styles.settingButtonText,
                    { color: perspective === "half-empty" ? themeColors.text : themeColors.textSecondary },
                  ]}>
                    Half Empty
                  </SmartText>
                </TouchableOpacity>
              </View>
            </View>

            {/* Time Mode Setting */}
            <View style={styles.settingSection}>
              <SmartText style={[styles.settingSectionHeading, { color: themeColors.text }]}>Daily  Tracking</SmartText>
              <View style={styles.settingButtons}>
                <TouchableOpacity
                  onPress={() => handleTimeModeChange("24h")}
                  style={[
                    styles.settingButton,
                    {
                      backgroundColor: timeMode === "24h" ? 'transparent' : themeColors.border,
                      borderColor: timeMode === "24h" ? themeColors.text : themeColors.border,
                      borderWidth: timeMode === "24h" ? 2 : 1,
                    },
                  ]}
                >
                  <SmartText style={[
                    styles.settingButtonText,
                    { color: timeMode === "24h" ? themeColors.text : themeColors.textSecondary },
                  ]}>
                    24 Hours
                  </SmartText>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handleTimeModeChange("9-5")}
                  style={[
                    styles.settingButton,
                    {
                      backgroundColor: timeMode === "9-5" ? 'transparent' : themeColors.border,
                      borderColor: timeMode === "9-5" ? themeColors.text : themeColors.border,
                      borderWidth: timeMode === "9-5" ? 2 : 1,
                    },
                  ]}
                >
                  <SmartText style={[
                    styles.settingButtonText,
                    { color: timeMode === "9-5" ? themeColors.text : themeColors.textSecondary },
                  ]}>
                    9-5 Office Hours
                  </SmartText>
                </TouchableOpacity>
              </View>
            </View>

            {/* Customize Display Section */}
            <View style={styles.settingSection}>
              <SmartText style={[styles.settingSectionHeading, { color: themeColors.text }]}>Customize  Display</SmartText>
              <SmartText style={[styles.settingDescriptionSmall, { color: themeColors.textSecondary }]}>Today  is  always  shown.  Choose  2  more  items.</SmartText>

              <View style={styles.displayItemsContainer}>
                {['today', 'week', 'month', 'quarter', 'year', 'custom'].map((itemType) => {
                  const isSelected = selectedDisplayItems.includes(itemType);
                  const isToday = itemType === 'today';
                  const isDisabled = isToday || (!isSelected && selectedDisplayItems.length >= 3);

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
                        isSelected && styles.displayItemButtonTextBold,
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
                              progress.isPast ? (progress.useWeeks ? `${progress.weeksLeft} weeks ago` : `${Math.abs(progress.daysLeft)} days ago`) :
                                (progress.useWeeks ? `${progress.weeksLeft} weeks left` : `${progress.daysLeft} days left`)}
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
              <SmartText style={[styles.settingSectionHeading, { color: themeColors.text }]}>Notifications</SmartText>
              <SmartText style={[styles.settingDescriptionSmall, { color: themeColors.textSecondary }]}>Weekly  progress  updates  every  Monday  at  9  AM  based  on  your  selected  display  items</SmartText>
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
                <SmartText style={[styles.syncButtonText, { color: themeColors.text }]}>🔄 Sync to Widgets</SmartText>
              </TouchableOpacity>
              <SmartText style={[styles.settingDescriptionSmall, { color: themeColors.textSecondary }]}>Manually  update  your  home  screen  widgets  with  current  settings</SmartText>
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
                <Text style={[styles.closeButtonText, { color: themeColors.text }]}>✕</Text>
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
    justifyContent: "center",
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 23.4, // 39 * 0.6 = 23.4
    color: '#000000',
  },
  closeButton: {
    width: 32,
    height: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    fontSize: 20,
    color: '#000000',
    fontWeight: '400',
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 18, // 30 * 0.6 = 18
    marginBottom: 50,
    textAlign: "center",
    lineHeight: 27, // 18 * 1.5 = 27
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 15, // 25 * 0.6 = 15
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
  svgTintOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    width: '100%',
    height: '100%',
  },
  progressSectionContainer: {
    width: '100%',
    alignItems: 'center',
    marginTop: -30,
  },
  widgetPromptOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  widgetPromptContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    padding: 24,
    width: '100%',
    maxWidth: 400,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  widgetPromptTitle: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 22.4, // 32 * 0.7 = 22.4
    color: '#000000',
    marginBottom: 12,
    textAlign: 'center',
  },
  widgetPromptText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.3, // 19 * 0.7 = 13.3
    color: '#666666',
    marginBottom: 24,
    textAlign: 'center',
    lineHeight: 17, // 14 * 1.2 = 16.8
  },
  widgetPromptButton: {
    backgroundColor: '#000000',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#000000',
  },
  widgetPromptButtonText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 15.4, // 22 * 0.7 = 15.4
    color: '#ffffff',
  },
  widgetPromptDismiss: {
    alignItems: 'center',
    paddingVertical: 8,
  },
  widgetPromptDismissText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.3, // 19 * 0.7 = 13.3
    color: '#666666',
    textDecorationLine: 'underline',
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 17.5, // 25 * 0.7 = 17.5
    color: "#666666",
  },
  progressValueBold: {
    fontFamily: 'Sabdevi-Bold',
    fontSize: 17.5, // 25 * 0.7 = 17.5
    color: "#222222",
  },
  progressValueRegular: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 17.5, // 25 * 0.7 = 17.5
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
    fontSize: 25,
  },
  settingsButton: {
    padding: 8,
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 28,
    color: "#000000",
    textAlign: "center",
    marginBottom: 24,
  },
  settingSection: {
    marginBottom: 20,
    paddingBottom: 16,
  },
  settingSectionHeading: {
    fontFamily: 'Sabdevi-Bold',
    fontSize: 11.4, // 19 * 0.6 = 11.4
    color: '#000000',
    marginBottom: 12,
  },
  settingLabel: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
    color: "#000000",
    marginBottom: 8,
    fontWeight: "600",
  },
  settingDescription: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 9.6, // 16 * 0.6 = 9.6
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 9.6, // 16 * 0.6 = 9.6
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
    color: '#ffffff',
  },
  syncButton: {
    marginTop: 16,
    marginBottom: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  syncButtonText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 19,
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
  },
  settingDescriptionSmall: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.3, // 19 * 0.7 = 13.3
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
    lineHeight: 20, // 13.3 * 1.5 = 19.95 ≈ 20
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
    fontSize: 19,
    fontWeight: 'bold',
  },
  displayItemButtonDisabled: {
    opacity: 0.3,
  },
  displayItemButtonText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
    color: '#000000',
  },
  displayItemButtonTextBold: {
    fontFamily: 'Sabdevi-Bold',
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 9.6, // 16 * 0.6 = 9.6
    color: '#ffffff',
  },
  customEventFields: {
    marginTop: 12,
    paddingTop: 12,
  },
  customEventFieldsTitle: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 9.6, // 16 * 0.6 = 9.6
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#222',
    flex: 1,
  },
  eventDateText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
    color: '#666',
  },
  eventStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  eventStatusText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 11.4, // 19 * 0.6 = 11.4
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#ffffff',
  },
  inputContainer: {
    marginBottom: 20,
  },
  inputLabel: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#222',
    marginBottom: 8,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#666',
  },
  saveButtonText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
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
    fontFamily: 'Sabdevi-Regular',
    fontSize: 16.8, // 28 * 0.6 = 16.8
    color: '#000000',
  },
  addEventModalContent: {
    padding: 20,
  },
  addEventLabel: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#222222',
    marginBottom: 8,
  },
  addEventInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13.2, // 22 * 0.6 = 13.2
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
    fontFamily: 'Sabdevi-Regular', // Using system font
    fontSize: 13.2, // 22 * 0.6 = 13.2
    color: '#ffffff',
  },
  emptyEventContainer: {
    padding: 16,
    borderRadius: 12,
    backgroundColor: 'rgba(0,0,0,0.03)',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.05)',
    borderStyle: 'dashed',
  },
  emptyEventContent: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
  },
  emptyEventText: {
    fontFamily: 'Sabdevi-Regular',
    fontSize: 13,
    textAlign: 'center',
    opacity: 0.6,
  },
  addYoursButton: {
    marginTop: 12,
    backgroundColor: '#000000',
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 16,
  },
  addYoursText: {
    fontFamily: 'Sabdevi-Bold',
    fontSize: 12,
    color: '#ffffff',
  },
});
