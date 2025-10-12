import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import TimeProgressWidget from '../components/TimeProgressWidget';

const WidgetDemo = () => {
  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>Widget Preview</Text>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Compact Widget</Text>
        <Text style={styles.description}>
          Perfect for home screen widgets
        </Text>
        <TimeProgressWidget isCompact={true} />
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Full Widget</Text>
        <Text style={styles.description}>
          Complete view with all details
        </Text>
        <TimeProgressWidget isCompact={false} />
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>How to Add Widget</Text>
        <Text style={styles.instructions}>
          1. Open this app in your browser{'\n'}
          2. Tap "Add to Home Screen"{'\n'}
          3. Choose widget size{'\n'}
          4. Enjoy your time progress widget!
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  header: {
    fontSize: 24,
    fontFamily: 'Kalam-Bold',
    color: '#333',
    textAlign: 'center',
    marginBottom: 20,
  },
  section: {
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: 'Kalam-Bold',
    color: '#333',
    marginBottom: 8,
  },
  description: {
    fontSize: 14,
    fontFamily: 'Kalam-Regular',
    color: '#666',
    marginBottom: 12,
  },
  instructions: {
    fontSize: 14,
    fontFamily: 'Kalam-Regular',
    color: '#333',
    lineHeight: 20,
  },
});

export default WidgetDemo;
