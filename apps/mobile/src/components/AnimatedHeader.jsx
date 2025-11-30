import React, { useEffect, useRef, useState } from 'react';
import { View, Animated, Dimensions, StyleSheet } from 'react-native';
import { Image } from 'expo-image';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');
const HEADER_HEIGHT = 200;

const AnimatedHeader = () => {
  // Sun rotation for circular animation (slower)
  const sunRotation = useRef(new Animated.Value(0)).current;

  // Cloud state - we'll maintain at least 4-6 clouds always visible
  const [clouds, setClouds] = useState([]);
  const cloudRefs = useRef({});

  // Bird group visibility states for random appearances
  const [showBirdGroup1, setShowBirdGroup1] = useState(false);
  const [showBirdGroup2, setShowBirdGroup2] = useState(false);
  const [showBirdGroup3, setShowBirdGroup3] = useState(false);
  const [showBirdGroup4, setShowBirdGroup4] = useState(false);
  const [showBirdGroup5, setShowBirdGroup5] = useState(false);
  const [showBirdGroup6, setShowBirdGroup6] = useState(false);

  // Bird group positions
  const birdGroup1X = useRef(new Animated.Value(0)).current;
  const birdGroup2X = useRef(new Animated.Value(0)).current;
  const birdGroup3X = useRef(new Animated.Value(0)).current;
  const birdGroup3Y = useRef(new Animated.Value(0)).current;
  const birdGroup4X = useRef(new Animated.Value(0)).current;
  const birdGroup5X = useRef(new Animated.Value(0)).current;
  const birdGroup6X = useRef(new Animated.Value(0)).current;
  const birdGroup6Y = useRef(new Animated.Value(0)).current;

  // Cloud configurations with variations
  const cloudVariations = [
    { source: require('../../assets/svg/cloud-1.svg'), baseWidth: 120, baseHeight: 60 },
    { source: require('../../assets/svg/cloud-2.svg'), baseWidth: 100, baseHeight: 50 },
    { source: require('../../assets/svg/cloud-3.svg'), baseWidth: 110, baseHeight: 55 },
  ];

  // Function to create a cloud with random properties
  const createCloud = (id, index = 0, totalClouds = 6) => {
    const variation = cloudVariations[Math.floor(Math.random() * cloudVariations.length)];
    const sizeMultiplier = 0.7 + Math.random() * 0.6; // 0.7x to 1.3x size variation
    const width = variation.baseWidth * sizeMultiplier;
    const height = variation.baseHeight * sizeMultiplier;
    
    // Distribute Y positions evenly across header height to avoid clustering
    const top = (index / (totalClouds - 1)) * (HEADER_HEIGHT - height - 20) + 10;
    
    // Alternate directions for visual interest: mostly left to right, some right to left
    const direction = index % 3 === 0 ? 'rightToLeft' : 'leftToRight';
    
    // Vary speed - ensure clouds don't move in sync
    const baseDuration = 35000 + (index * 3000); // Stagger durations
    const duration = baseDuration + (Math.random() * 8000 - 4000); // Add variation
    
    // Starting position based on direction
    const startX = direction === 'leftToRight' 
      ? -width - 50 // Start off-screen left
      : screenWidth + 50; // Start off-screen right
    
    return {
      id,
      source: variation.source,
      width,
      height,
      top,
      direction,
      duration,
      startX,
      opacity: 0.65 + Math.random() * 0.25, // 0.65 to 0.9 opacity
    };
  };

  // Function to animate a single cloud
  const animateCloud = (cloud) => {
    const animatedValue = cloudRefs.current[cloud.id];
    if (!animatedValue) return;

    // Set initial position
    animatedValue.setValue(cloud.startX);

    // Determine end position based on direction
    const endX = cloud.direction === 'leftToRight'
      ? screenWidth + cloud.width + 50 // Move off-screen right
      : -cloud.width - 50; // Move off-screen left

    // Create animation
    const animation = Animated.timing(animatedValue, {
      toValue: endX,
      duration: cloud.duration,
      useNativeDriver: true,
    });

    // Start animation and loop
    animation.start(() => {
      // When animation completes, reset and restart
      animatedValue.setValue(cloud.startX);
      animateCloud(cloud);
    });
  };

  // Initialize clouds
  useEffect(() => {
    // Create 6 clouds initially to ensure at least 4 are always visible
    const initialClouds = [];
    const totalClouds = 6;
    
    for (let i = 0; i < totalClouds; i++) {
      const cloud = createCloud(`cloud-${i}`, i, totalClouds);
      initialClouds.push(cloud);
      
      // Create animated value for this cloud
      cloudRefs.current[cloud.id] = new Animated.Value(cloud.startX);
      
      // Stagger start times so clouds are distributed across screen
      // This ensures at least 4 clouds are always visible
      setTimeout(() => {
        animateCloud(cloud);
      }, i * 2500); // 2.5 second delay between each cloud
    }

    setClouds(initialClouds);

    // Sun circular rotation - SLOW continuous 360 degree rotation (60 seconds per rotation)
    Animated.loop(
      Animated.timing(sunRotation, {
        toValue: 1,
        duration: 60000, // 60 seconds per rotation
        useNativeDriver: true,
      })
    ).start();

    // Random bird appearances
    const showRandomBirds = () => {
      const delay = 3000 + Math.random() * 5000;
      
      setTimeout(() => {
        const groupNum = Math.floor(Math.random() * 6) + 1;
        
        switch (groupNum) {
          case 1:
            if (!showBirdGroup1) {
              setShowBirdGroup1(true);
              birdGroup1X.setValue(-100);
              Animated.timing(birdGroup1X, {
                toValue: screenWidth + 300,
                duration: 12000 + Math.random() * 8000,
                useNativeDriver: true,
              }).start(() => {
                setShowBirdGroup1(false);
              });
            }
            break;
          case 2:
            if (!showBirdGroup2) {
              setShowBirdGroup2(true);
              birdGroup2X.setValue(-100);
              Animated.timing(birdGroup2X, {
                toValue: screenWidth + 300,
                duration: 10000 + Math.random() * 6000,
                useNativeDriver: true,
              }).start(() => {
                setShowBirdGroup2(false);
              });
            }
            break;
          case 3:
            if (!showBirdGroup3) {
              setShowBirdGroup3(true);
              birdGroup3X.setValue(-100);
              birdGroup3Y.setValue(-70);
              Animated.parallel([
                Animated.timing(birdGroup3X, {
                  toValue: screenWidth + 200,
                  duration: 14000 + Math.random() * 6000,
                  useNativeDriver: true,
                }),
                Animated.timing(birdGroup3Y, {
                  toValue: 150,
                  duration: 14000 + Math.random() * 6000,
                  useNativeDriver: true,
                }),
              ]).start(() => {
                setShowBirdGroup3(false);
              });
            }
            break;
          case 4:
            if (!showBirdGroup4) {
              setShowBirdGroup4(true);
              birdGroup4X.setValue(-120);
              Animated.timing(birdGroup4X, {
                toValue: screenWidth + 300,
                duration: 11000 + Math.random() * 7000,
                useNativeDriver: true,
              }).start(() => {
                setShowBirdGroup4(false);
              });
            }
            break;
          case 5:
            if (!showBirdGroup5) {
              setShowBirdGroup5(true);
              birdGroup5X.setValue(-80);
              Animated.timing(birdGroup5X, {
                toValue: screenWidth + 250,
                duration: 13000 + Math.random() * 5000,
                useNativeDriver: true,
              }).start(() => {
                setShowBirdGroup5(false);
              });
            }
            break;
          case 6:
            if (!showBirdGroup6) {
              setShowBirdGroup6(true);
              birdGroup6X.setValue(-90);
              birdGroup6Y.setValue(-50);
              Animated.parallel([
                Animated.timing(birdGroup6X, {
                  toValue: screenWidth + 200,
                  duration: 15000 + Math.random() * 5000,
                  useNativeDriver: true,
                }),
                Animated.timing(birdGroup6Y, {
                  toValue: 120,
                  duration: 15000 + Math.random() * 5000,
                  useNativeDriver: true,
                }),
              ]).start(() => {
                setShowBirdGroup6(false);
              });
            }
            break;
        }
        
        showRandomBirds();
      }, delay);
    };

    showRandomBirds();
  }, []);

  const spin = sunRotation.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <View style={styles.container}>
      {/* Sun - centered with rotation */}
      <Animated.View
        style={[
          styles.sun,
          {
            transform: [{ rotate: spin }],
          },
        ]}
      >
        <Image
          source={require('../../assets/svg/sun.svg')}
          style={{ width: 80, height: 80 }}
          contentFit="contain"
        />
      </Animated.View>

      {/* Clouds - always at least 4 visible */}
      {clouds.map((cloud) => {
        const animatedValue = cloudRefs.current[cloud.id];
        if (!animatedValue) return null;

        return (
          <Animated.View
            key={cloud.id}
            style={[
              styles.cloud,
              {
                top: cloud.top,
                width: cloud.width,
                height: cloud.height,
                opacity: cloud.opacity,
                transform: [{ translateX: animatedValue }],
              },
            ]}
          >
            <Image
              source={cloud.source}
              style={{ width: cloud.width, height: cloud.height }}
              contentFit="contain"
            />
          </Animated.View>
        );
      })}

      {/* Bird Groups - Random appearances */}
      {showBirdGroup1 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 8}
          offsetX={birdGroup1X}
          offsetY={new Animated.Value(Math.random() * 40 - 70)}
          startX={-100}
        />
      )}
      {showBirdGroup2 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 4}
          offsetX={birdGroup2X}
          offsetY={new Animated.Value(Math.random() * 40 - 50)}
          startX={-100}
        />
      )}
      {showBirdGroup3 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 2}
          offsetX={birdGroup3X}
          offsetY={birdGroup3Y}
          startX={-100}
          startY={-70}
        />
      )}
      {showBirdGroup4 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 6}
          offsetX={birdGroup4X}
          offsetY={new Animated.Value(Math.random() * 50 - 60)}
          startX={-120}
        />
      )}
      {showBirdGroup5 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 3}
          offsetX={birdGroup5X}
          offsetY={new Animated.Value(Math.random() * 40 - 40)}
          startX={-80}
        />
      )}
      {showBirdGroup6 && (
        <BirdGroup
          size={Math.floor(Math.random() * 3) + 2}
          offsetX={birdGroup6X}
          offsetY={birdGroup6Y}
          startX={-90}
          startY={-50}
        />
      )}
    </View>
  );
};

// Bird Group Component
const BirdGroup = ({ size, offsetX, offsetY, startX, startY = 0 }) => {
  const birdPositions = Array.from({ length: size }, (_, index) => {
    const randomOffset = Math.random() * 30 - 15;
    const patternOffset = Math.sin(index * 0.5) * 8;
    return randomOffset + patternOffset;
  });

  return (
    <Animated.View
      style={{
        position: 'absolute',
        transform: [
          { translateX: offsetX },
          { translateY: offsetY },
        ],
      }}
    >
      {Array.from({ length: size }, (_, index) => (
        <Animated.Text
          key={index}
          style={[
            styles.bird,
            {
              left: startX + index * 4,
              top: startY + birdPositions[index],
            },
          ]}
        >
          •
        </Animated.Text>
      ))}
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: HEADER_HEIGHT,
    backgroundColor: '#ffffff',
    overflow: 'hidden',
    position: 'relative',
  },
  sun: {
    position: 'absolute',
    top: '50%',
    left: '50%',
    marginLeft: -40,
    marginTop: -40,
    zIndex: 1,
  },
  cloud: {
    position: 'absolute',
    zIndex: 2,
  },
  bird: {
    position: 'absolute',
    fontSize: 6,
    color: 'rgba(0, 0, 0, 0.7)',
    fontFamily: 'Sabdevi-Regular',
  },
});

export default AnimatedHeader;
