import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const TimeProgressWidget = ({ isCompact = false, onPress }) => {
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
  const [perspective, setPerspective] = useState('half-full');
  const [timeMode, setTimeMode] = useState('24h');
  const [selectedDisplayItems, setSelectedDisplayItems] = useState(['today', 'month', 'year']);
  const [customEvents, setCustomEvents] = useState([]);

  useEffect(() => {
    loadSettings();
    calculateTimeProgress();
    
    // Update every minute and reload settings every 5 minutes
    const timeInterval = setInterval(calculateTimeProgress, 60000);
    const settingsInterval = setInterval(loadSettings, 300000); // 5 minutes
    
    return () => {
      clearInterval(timeInterval);
      clearInterval(settingsInterval);
    };
  }, []);

  const loadSettings = async () => {
    try {
      const savedPerspective = await AsyncStorage.getItem('userPerspective');
      const savedTimeMode = await AsyncStorage.getItem('timeMode');
      const savedDisplayItems = await AsyncStorage.getItem('selectedDisplayItems');
      const savedCustomEvents = await AsyncStorage.getItem('customEvents');
      
      if (savedPerspective) setPerspective(savedPerspective);
      if (savedTimeMode) setTimeMode(savedTimeMode);
      if (savedDisplayItems) setSelectedDisplayItems(JSON.parse(savedDisplayItems));
      if (savedCustomEvents) setCustomEvents(JSON.parse(savedCustomEvents));
    } catch (error) {
      console.log('Error loading settings:', error);
    }
  };

  const calculateTimeProgress = () => {
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
  };

  const renderProgressItem = (itemType) => {
    let label, progress, completed, total, unit;

    switch (itemType) {
      case 'today':
        label = "Today";
        if (timeMode === '9-5') {
          total = 8;
          completed = timeData.officeHoursCompleted;
          progress = timeData.dayProgress;
          unit = perspective === "half-full" ? "hours done" : "hours left";
        } else {
          total = 24;
          completed = timeData.hoursCompleted;
          progress = timeData.dayProgress;
          unit = perspective === "half-full" ? "hours done" : "hours left";
        }
        break;
      case 'week':
        label = "This Week";
        total = 7;
        completed = timeData.daysCrossedInWeek;
        progress = timeData.weekProgress;
        unit = perspective === "half-full" ? "days done" : "days left";
        break;
      case 'month':
        label = "This Month";
        const now = new Date();
        const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
        total = daysInMonth;
        completed = timeData.daysCrossed;
        progress = timeData.monthProgress;
        unit = perspective === "half-full" ? "days done" : "days left";
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
        completed = weeksCompleted;
        progress = timeData.quarterProgress;
        unit = perspective === "half-full" ? "weeks done" : "weeks left";
        break;
      case 'year':
        label = "This Year";
        total = 100;
        completed = timeData.yearCompleted;
        progress = timeData.yearProgress;
        unit = perspective === "half-full" ? "% done" : "% left";
        break;
      case 'custom':
        // For custom events, show the first custom event or a summary
        if (customEvents.length === 0) {
          label = "Custom Events";
          total = 0;
          completed = 0;
          progress = 0;
          unit = "No events";
        } else {
          const firstEvent = customEvents[0];
          const now = new Date();
          const eventDate = new Date(firstEvent.date);
          const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          const eventDay = new Date(eventDate.getFullYear(), eventDate.getMonth(), eventDate.getDate());
          
          const diffTime = eventDay - today;
          const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
          
          label = firstEvent.name;
          total = 365; // Approximate days in a year
          completed = diffDays < 0 ? Math.abs(diffDays) : 365 - diffDays;
          progress = Math.max(0, Math.min(100, (completed / total) * 100));
          unit = diffDays === 0 ? "Today!" : 
                 diffDays < 0 ? "days ago" : "days left";
        }
        break;
      default:
        return null;
    }

    const displayValue = perspective === "half-full" ? completed : (total - completed);
    const displayText = `${displayValue}/${total} ${unit}`;

    return (
      <View key={itemType} style={styles.progressItem}>
        <Text style={[styles.progressLabel, isCompact && styles.compactLabel]}>
          {label}
        </Text>
        <Text style={[styles.progressText, isCompact && styles.compactText]}>
          {displayText}
        </Text>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { 
                width: `${progress}%`,
                backgroundColor: getProgressColor(progress)
              }
            ]} 
          />
        </View>
      </View>
    );
  };

  const getProgressColor = (progress) => {
    if (perspective === 'half-empty') {
      return progress > 75 ? '#ff6b6b' : progress > 50 ? '#ffa726' : '#4caf50';
    } else {
      return progress > 75 ? '#4caf50' : progress > 50 ? '#ffa726' : '#ff6b6b';
    }
  };

  const WidgetContent = () => {
    // Limit items based on widget size
    const maxItems = isCompact ? 2 : 3;
    const displayItems = selectedDisplayItems.slice(0, maxItems);
    
    return (
      <View style={[styles.widgetContainer, isCompact && styles.compactContainer]}>
        <Text style={[styles.title, isCompact && styles.compactTitle]}>
          Time Progress
        </Text>
        
        {displayItems.map(itemType => renderProgressItem(itemType))}
        
        {!isCompact && (
          <Text style={styles.perspectiveText}>
            {perspective === 'half-full' ? 'Half Full' : 'Half Empty'} • {timeMode}
          </Text>
        )}
      </View>
    );
  };

  if (isCompact) {
    return (
      <TouchableOpacity onPress={onPress} style={styles.widgetTouchable}>
        <WidgetContent />
      </TouchableOpacity>
    );
  }

  return <WidgetContent />;
};

const styles = StyleSheet.create({
  widgetContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
    minWidth: 280,
  },
  compactContainer: {
    padding: 12,
    minWidth: 200,
  },
  title: {
    fontSize: 18,
    fontFamily: 'Kalam-Bold',
    color: '#333',
    marginBottom: 12,
    textAlign: 'center',
  },
  compactTitle: {
    fontSize: 14,
    marginBottom: 8,
  },
  progressItem: {
    marginBottom: 12,
  },
  progressLabel: {
    fontSize: 14,
    fontFamily: 'Kalam-Regular',
    color: '#666',
    marginBottom: 4,
  },
  compactLabel: {
    fontSize: 12,
  },
  progressText: {
    fontSize: 12,
    fontFamily: 'Kalam-Regular',
    color: '#333',
    marginBottom: 6,
  },
  compactText: {
    fontSize: 10,
  },
  progressBar: {
    height: 6,
    backgroundColor: '#e0e0e0',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
  },
  perspectiveText: {
    fontSize: 10,
    fontFamily: 'Kalam-Regular',
    color: '#999',
    textAlign: 'center',
    marginTop: 8,
  },
  widgetTouchable: {
    borderRadius: 16,
  },
});

export default TimeProgressWidget;
