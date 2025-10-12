import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const TimeProgressWidget = ({ isCompact = false, onPress }) => {
  const [timeData, setTimeData] = useState({
    todayProgress: 0,
    monthProgress: 0,
    yearProgress: 0,
    todayCompleted: 0,
    todayTotal: 24,
    monthCompleted: 0,
    monthTotal: 30,
    yearCompleted: 0,
    yearTotal: 365
  });
  const [perspective, setPerspective] = useState('half-full');
  const [timeMode, setTimeMode] = useState('24h');

  useEffect(() => {
    loadSettings();
    calculateTimeProgress();
    
    // Update every minute
    const interval = setInterval(calculateTimeProgress, 60000);
    return () => clearInterval(interval);
  }, []);

  const loadSettings = async () => {
    try {
      const savedPerspective = await AsyncStorage.getItem('userPerspective');
      const savedTimeMode = await AsyncStorage.getItem('timeMode');
      
      if (savedPerspective) setPerspective(savedPerspective);
      if (savedTimeMode) setTimeMode(savedTimeMode);
    } catch (error) {
      console.log('Error loading settings:', error);
    }
  };

  const calculateTimeProgress = () => {
    const now = new Date();
    
    // Today calculation
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);
    
    let todayCompleted, todayTotal;
    
    if (timeMode === '9-5') {
      // 9 AM to 5 PM (8 hours)
      const workStart = new Date(startOfDay.getTime() + 9 * 60 * 60 * 1000);
      const workEnd = new Date(startOfDay.getTime() + 17 * 60 * 60 * 1000);
      
      if (now < workStart) {
        todayCompleted = 0;
      } else if (now > workEnd) {
        todayCompleted = 8;
      } else {
        todayCompleted = (now - workStart) / (60 * 60 * 1000);
      }
      todayTotal = 8;
    } else {
      // 24 hours
      todayCompleted = (now - startOfDay) / (60 * 60 * 1000);
      todayTotal = 24;
    }
    
    // Month calculation
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    const monthCompleted = now.getDate() - 1;
    const monthTotal = endOfMonth.getDate();
    
    // Year calculation
    const startOfYear = new Date(now.getFullYear(), 0, 1);
    const endOfYear = new Date(now.getFullYear() + 1, 0, 1);
    const yearCompleted = Math.floor((now - startOfYear) / (24 * 60 * 60 * 1000));
    const yearTotal = Math.floor((endOfYear - startOfYear) / (24 * 60 * 60 * 1000));
    
    const todayProgress = Math.min((todayCompleted / todayTotal) * 100, 100);
    const monthProgress = Math.min((monthCompleted / monthTotal) * 100, 100);
    const yearProgress = Math.min((yearCompleted / yearTotal) * 100, 100);
    
    setTimeData({
      todayProgress,
      monthProgress,
      yearProgress,
      todayCompleted: Math.floor(todayCompleted),
      todayTotal,
      monthCompleted,
      monthTotal,
      yearCompleted,
      yearTotal
    });
  };

  const getProgressText = (progress, completed, total, label) => {
    if (perspective === 'half-empty') {
      const remaining = total - completed;
      return `${remaining} ${label} left`;
    } else {
      return `${completed}/${total} ${label}`;
    }
  };

  const getProgressColor = (progress) => {
    if (perspective === 'half-empty') {
      return progress > 75 ? '#ff6b6b' : progress > 50 ? '#ffa726' : '#4caf50';
    } else {
      return progress > 75 ? '#4caf50' : progress > 50 ? '#ffa726' : '#ff6b6b';
    }
  };

  const WidgetContent = () => (
    <View style={[styles.widgetContainer, isCompact && styles.compactContainer]}>
      <Text style={[styles.title, isCompact && styles.compactTitle]}>
        Time Progress
      </Text>
      
      <View style={styles.progressItem}>
        <Text style={[styles.progressLabel, isCompact && styles.compactLabel]}>
          Today
        </Text>
        <Text style={[styles.progressText, isCompact && styles.compactText]}>
          {getProgressText(
            timeData.todayProgress,
            timeData.todayCompleted,
            timeData.todayTotal,
            timeMode === '9-5' ? 'hours' : 'hours'
          )}
        </Text>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { 
                width: `${timeData.todayProgress}%`,
                backgroundColor: getProgressColor(timeData.todayProgress)
              }
            ]} 
          />
        </View>
      </View>
      
      <View style={styles.progressItem}>
        <Text style={[styles.progressLabel, isCompact && styles.compactLabel]}>
          Month
        </Text>
        <Text style={[styles.progressText, isCompact && styles.compactText]}>
          {getProgressText(
            timeData.monthProgress,
            timeData.monthCompleted,
            timeData.monthTotal,
            'days'
          )}
        </Text>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { 
                width: `${timeData.monthProgress}%`,
                backgroundColor: getProgressColor(timeData.monthProgress)
              }
            ]} 
          />
        </View>
      </View>
      
      <View style={styles.progressItem}>
        <Text style={[styles.progressLabel, isCompact && styles.compactLabel]}>
          Year
        </Text>
        <Text style={[styles.progressText, isCompact && styles.compactText]}>
          {getProgressText(
            timeData.yearProgress,
            timeData.yearCompleted,
            timeData.yearTotal,
            'days'
          )}
        </Text>
        <View style={styles.progressBar}>
          <View 
            style={[
              styles.progressFill, 
              { 
                width: `${timeData.yearProgress}%`,
                backgroundColor: getProgressColor(timeData.yearProgress)
              }
            ]} 
          />
        </View>
      </View>
      
      {!isCompact && (
        <Text style={styles.perspectiveText}>
          {perspective === 'half-full' ? 'Half Full' : 'Half Empty'} • {timeMode}
        </Text>
      )}
    </View>
  );

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
