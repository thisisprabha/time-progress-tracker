import { useColorScheme } from 'react-native';

export const lightColors = {
  // Core colors
  navy: '#0F142B',
  primaryBlue: '#007BFF',
  statusGreen: '#17C964',
  lightGrey: '#8F94A2',
  borderGrey: '#EDEFF4',
  white: '#FFFFFF',
  
  // Task manager specific
  progressTrack: '#E6EEFF',
  addButtonDark: '#0060F0',
  shadowColor: 'rgba(16, 20, 43, 0.06)',
  
  // Create event specific
  primary: '#0066FF',
  textMain: '#101322',
  textSecondary: '#8F93A3',
  border: '#E9EBF0',
  divider: '#F1F3F5',
  surface: '#FFFFFF',
  
  // Daily schedule specific
  canvasWhite: '#FFFFFF',
  textInk: '#111727',
  subtleGrey: '#AEB4C1',
  dividerGrey: '#E9ECF1',
  lightCardGrey: '#F4F6FA',
  charcoalCard: '#5F6368',
  emerald: '#05C168',
  shadowTint: 'rgba(0,0,0,0.06)',
};

export const darkColors = {
  // Core colors
  navy: 'rgba(255, 255, 255, 0.87)', // 87% white for primary text
  primaryBlue: '#4A9EFF', // Slightly brighter and less saturated blue
  statusGreen: '#2DD55B', // Brighter green for dark mode
  lightGrey: 'rgba(255, 255, 255, 0.65)', // 65% white for secondary text
  borderGrey: '#2A2A2A', // Dark border color
  white: '#121212', // Dark background
  
  // Task manager specific
  progressTrack: '#1E3A5F', // Darker blue track
  addButtonDark: '#3A8BFF', // Adjusted for dark mode
  shadowColor: 'rgba(0, 0, 0, 0.25)', // Darker shadow for dark mode
  cardBackground: '#1E1E1E', // Elevated surface
  divider: '#2A2A2A', // Dark divider
  
  // Create event specific
  primary: '#4A9EFF',
  textMain: 'rgba(255, 255, 255, 0.87)',
  textSecondary: 'rgba(255, 255, 255, 0.65)',
  border: '#2A2A2A',
  divider: '#262626',
  surface: '#121212',
  
  // Daily schedule specific
  canvasWhite: '#121212',
  textInk: 'rgba(255, 255, 255, 0.87)',
  subtleGrey: 'rgba(255, 255, 255, 0.65)',
  dividerGrey: '#2A2A2A',
  lightCardGrey: '#1E1E1E',
  charcoalCard: '#6A6A6A',
  emerald: '#2DD55B',
  shadowTint: 'rgba(0,0,0,0.25)',
  cardBackground: '#1E1E1E',
};

export const useTheme = () => {
  const colorScheme = useColorScheme();
  return colorScheme === 'dark' ? darkColors : lightColors;
};