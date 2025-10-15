import React, { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  Modal,
  Platform,
} from "react-native";
import Svg, { Path } from "react-native-svg";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import * as Haptics from "expo-haptics";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  useFonts,
  Kalam_300Light,
  Kalam_400Regular,
  Kalam_700Bold,
} from "@expo-google-fonts/kalam";

// Conditionally import AdMob for Android only
let MobileAds, BannerAd, BannerAdSize, TestIds;
if (Platform.OS === 'android') {
  const GoogleMobileAds = require('react-native-google-mobile-ads');
  MobileAds = GoogleMobileAds.MobileAds;
  BannerAd = GoogleMobileAds.BannerAd;
  BannerAdSize = GoogleMobileAds.BannerAdSize;
  TestIds = GoogleMobileAds.TestIds;
}

const { width: screenWidth } = Dimensions.get("window");

const WaterGlassIcon = ({ isHalfFull = true }) => (
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
);

const SettingsIcon = ({ onPress }) => (
  <TouchableOpacity onPress={onPress} style={styles.settingsButton}>
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
);

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

  const [perspective, setPerspective] = useState(null); // 'half-full' or 'half-empty'
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [timeMode, setTimeMode] = useState('24h'); // '24h' or '9-5'
  const [adLoaded, setAdLoaded] = useState(false);
  const [adTimeout, setAdTimeout] = useState(false);
  const [timeData, setTimeData] = useState({
    yearProgress: 0,
    monthProgress: 0,
    dayProgress: 0,
    yearCompleted: 0,
    monthCompleted: 0,
    dayCompleted: 0,
    yearPercentLeft: 0,
    daysLeftInMonth: 0,
    hoursLeftToday: 0,
    daysCrossed: 0,
    hoursCompleted: 0,
    officeHoursCompleted: 0,
    officeHoursLeft: 0,
  });

  const [fontsLoaded] = useFonts({
    Kalam_300Light,
    Kalam_400Regular,
    Kalam_700Bold,
  });

  // Load saved settings on app start
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const savedPerspective = await AsyncStorage.getItem("userPerspective");
        const savedTimeMode = await AsyncStorage.getItem("timeMode");
        
        if (savedPerspective) {
          setPerspective(savedPerspective);
          setHasCompletedOnboarding(true);
        }
        
        if (savedTimeMode) {
          setTimeMode(savedTimeMode);
        }
      } catch (error) {
        console.error("Error loading settings:", error);
      }
    };
    loadSettings();
  }, []);

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

    setTimeData({
      yearProgress,
      monthProgress,
      dayProgress,
      yearCompleted,
      monthCompleted,
      dayCompleted,
      yearPercentLeft,
      daysLeftInMonth,
      hoursLeftToday,
      daysCrossed,
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

  const handlePerspectiveSelect = useCallback(async (selectedPerspective) => {
    await Haptics.selectionAsync();
    setPerspective(selectedPerspective);
    setHasCompletedOnboarding(true);

    // Save perspective to storage
    try {
      await AsyncStorage.setItem("userPerspective", selectedPerspective);
    } catch (error) {
      console.error("Error saving perspective:", error);
    }
  }, []);

  const handleTimeModeChange = useCallback(async (mode) => {
    await Haptics.selectionAsync();
    setTimeMode(mode);
    setShowSettings(false);

    // Save time mode to storage
    try {
      await AsyncStorage.setItem("timeMode", mode);
    } catch (error) {
      console.error("Error saving time mode:", error);
    }
  }, []);

  const handlePerspectiveChange = useCallback(async (newPerspective) => {
    await Haptics.selectionAsync();
    setPerspective(newPerspective);
    setShowSettings(false);

    // Save perspective to storage
    try {
      await AsyncStorage.setItem("userPerspective", newPerspective);
    } catch (error) {
      console.error("Error saving perspective:", error);
    }
  }, []);

  const renderTallyCounter = useCallback(
    (label, value, unit, perspective) => {
      let total, completed;

      if (label === "This Year") {
        total = 12;
        completed = new Date().getMonth() + 1; // Always show months completed as crossed
      } else if (label === "This Month") {
        const now = new Date();
        const daysInMonth = new Date(
          now.getFullYear(),
          now.getMonth() + 1,
          0,
        ).getDate();
        total = daysInMonth;
        completed = timeData.daysCrossed; // Always show days completed as crossed
      } else {
        // Today - depends on time mode
        if (timeMode === '9-5') {
          total = 8; // Office hours
          completed = timeData.officeHoursCompleted;
        } else {
          total = 24; // 24-hour mode
          completed = timeData.hoursCompleted;
        }
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
    [timeData, timeMode],
  );

  if (!fontsLoaded) {
    return null;
  }

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />

      {/* Settings Icon */}
      {hasCompletedOnboarding && (
        <View style={[styles.header, { top: insets.top + 10 }]}>
          <SettingsIcon onPress={() => setShowSettings(true)} />
        </View>
      )}

      <View
        style={[
          styles.content,
          {
            paddingTop: insets.top + 40,
            paddingBottom: insets.bottom + 40,
          },
        ]}
      >
        {!hasCompletedOnboarding ? (
          /* Onboarding Section */
          <View style={styles.onboardingSection}>
            <View style={styles.glassContainer}>
              <WaterGlassIcon isHalfFull={true} />
            </View>

            <Text style={styles.questionText}>
              Is this glass half full or half empty?
            </Text>

            <View style={styles.perspectiveButtons}>
              <TouchableOpacity
                onPress={() => handlePerspectiveSelect("half-full")}
                style={[styles.perspectiveButton, styles.halfFullButton]}
              >
                <Text style={styles.perspectiveButtonText}>Half Full</Text>
              </TouchableOpacity>

              <TouchableOpacity
                onPress={() => handlePerspectiveSelect("half-empty")}
                style={[styles.perspectiveButton, styles.halfEmptyButton]}
              >
                <Text style={styles.perspectiveButtonText}>Half Empty</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          /* Progress Section with Tally Marks */
          <View style={styles.progressSection}>
            {perspective === "half-full" ? (
              <>
                {renderTallyCounter(
                  "Today",
                  timeMode === '9-5' ? timeData.officeHoursCompleted : timeData.hoursCompleted,
                  timeMode === '9-5' ? "office hours completed" : "hours completed",
                  perspective,
                )}

                {renderTallyCounter(
                  "This Month",
                  timeData.daysCrossed,
                  "days crossed",
                  perspective,
                )}

                {renderTallyCounter(
                  "This Year",
                  timeData.yearCompleted,
                  "% completed",
                  perspective,
                )}
              </>
            ) : (
              <>
                {renderTallyCounter(
                  "Today",
                  timeMode === '9-5' ? timeData.officeHoursLeft : timeData.hoursLeftToday,
                  timeMode === '9-5' ? "office hours left" : "hours left",
                  perspective,
                )}

                {renderTallyCounter(
                  "This Month",
                  timeData.daysLeftInMonth,
                  "days left",
                  perspective,
                )}

                {renderTallyCounter(
                  "This Year",
                  timeData.yearPercentLeft,
                  "% left",
                  perspective,
                )}
              </>
            )}
          </View>
        )}
      </View>

      {/* Settings Modal */}
      <Modal
        visible={showSettings}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setShowSettings(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Settings</Text>
            
            {/* Perspective Setting */}
            <View style={styles.settingSection}>
              <Text style={styles.settingLabel}>Glass Perspective</Text>
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
              <Text style={styles.settingLabel}>Today's Time Mode</Text>
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

            <TouchableOpacity
              onPress={() => setShowSettings(false)}
              style={styles.closeButton}
            >
              <Text style={styles.closeButtonText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* AdMob Banner (Android only) */}
      {Platform.OS === 'android' && (
        <View style={[styles.bannerContainer, { paddingBottom: Math.max(insets.bottom, 16) }]}>
          {BannerAd && !adTimeout ? (
            <BannerAd
              unitId={TestIds.BANNER}
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
  content: {
    flex: 1,
    paddingHorizontal: 32,
    justifyContent: "center",
  },
  onboardingSection: {
    alignItems: "center",
  },
  glassContainer: {
    marginBottom: 50,
    alignItems: "center",
  },
  questionText: {
    fontFamily: "Kalam_400Regular",
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
    fontFamily: "Kalam_700Bold",
    fontSize: 16,
    color: "#222222",
  },
  progressSection: {
    gap: 60,
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
    fontFamily: "Kalam_400Regular",
    fontSize: 18,
    color: "#666666",
  },
  progressValue: {
    fontFamily: "Kalam_700Bold",
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
    borderRadius: 20,
    padding: 30,
    margin: 20,
    maxWidth: 320,
    width: "90%",
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 8,
  },
  modalTitle: {
    fontFamily: "Kalam_700Bold",
    fontSize: 24,
    color: "#222222",
    textAlign: "center",
    marginBottom: 30,
  },
  settingSection: {
    marginBottom: 25,
  },
  settingLabel: {
    fontFamily: "Kalam_400Regular",
    fontSize: 16,
    color: "#666666",
    marginBottom: 12,
  },
  settingButtons: {
    flexDirection: "row",
    gap: 12,
  },
  settingButton: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: "#e0e0e0",
    backgroundColor: "#ffffff",
    alignItems: "center",
  },
  settingButtonActive: {
    borderColor: "#222222",
    backgroundColor: "#222222",
  },
  settingButtonText: {
    fontFamily: "Kalam_400Regular",
    fontSize: 14,
    color: "#666666",
  },
  settingButtonTextActive: {
    fontFamily: "Kalam_700Bold",
    color: "#ffffff",
  },
  closeButton: {
    marginTop: 20,
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 25,
    backgroundColor: "#f5f5f5",
    alignItems: "center",
  },
  closeButtonText: {
    fontFamily: "Kalam_700Bold",
    fontSize: 16,
    color: "#222222",
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
    fontFamily: 'Kalam_400Regular',
    fontSize: 14,
    color: '#999999',
  },
});
