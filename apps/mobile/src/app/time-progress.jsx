import React, { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
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
  });

  const [fontsLoaded] = useFonts({
    Kalam_300Light,
    Kalam_400Regular,
    Kalam_700Bold,
  });

  // Load saved perspective on app start
  useEffect(() => {
    const loadPerspective = async () => {
      try {
        const savedPerspective = await AsyncStorage.getItem("userPerspective");
        if (savedPerspective) {
          setPerspective(savedPerspective);
          setHasCompletedOnboarding(true);
        }
      } catch (error) {
        console.error("Error loading perspective:", error);
      }
    };
    loadPerspective();
  }, []);

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

    // Day progress
    const startOfDay = new Date(currentYear, currentMonth, currentDate);
    const endOfDay = new Date(currentYear, currentMonth, currentDate + 1);
    const dayTotal = endOfDay - startOfDay;
    const dayElapsed = now - startOfDay;
    const dayProgress = (dayElapsed / dayTotal) * 100;
    const dayCompleted = Math.round(dayProgress);
    const hoursLeftToday = Math.ceil((endOfDay - now) / (1000 * 60 * 60));
    const hoursCompleted = currentHour + (currentMinute > 30 ? 1 : 0); // Round to nearest hour

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
        // Today
        total = 24;
        completed = timeData.hoursCompleted; // Always show hours completed as crossed
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
    [timeData],
  );

  if (!fontsLoaded) {
    return null;
  }

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />

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
                  timeData.hoursCompleted,
                  "hours completed",
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
                  timeData.hoursLeftToday,
                  "hours left",
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
    backgroundColor: "rgba(34, 34, 34, 0.7)",
    borderRadius: 1,
    transform: [{ rotate: "45deg" }],
  },
});
