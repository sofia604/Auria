import React, { useRef, useState } from 'react';
import { View, StyleSheet, Text } from 'react-native';
import { Video, AVPlaybackStatus, ResizeMode } from 'expo-av';
import commands from '../assets/commands.json';

const SERVER_URL = 'http://192.168.4.2:3000/execute-sequence';

export default function VideoControlScreen() {
  const videoRef = useRef<Video>(null);
  const [firedIndexes, setFiredIndexes] = useState<number[]>([]);

  const handlePlaybackStatusUpdate = (status: AVPlaybackStatus) => {
    if (!status.isLoaded || !status.isPlaying) return;

    const currentTime = status.positionMillis / 1000;

    commands.mainData.forEach((cmd, index) => {
      if (
        !firedIndexes.includes(index) &&
        currentTime >= cmd.time
      ) {
        fetch(SERVER_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ data: cmd.data }),
        })
          .then((res) => res.json())
          .then((data) => console.log(`Trigger ${index} fired:`, data))
          .catch((err) => console.error(`Trigger ${index} error:`, err));

        setFiredIndexes((prev) => [...prev, index]);
      }
    });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>🎬 Robot-Controlled Video</Text>
      <Video
        ref={videoRef}
        source={require('../assets/images/my-video.mp4')}
        style={styles.video}
        resizeMode={ResizeMode.CONTAIN}
        useNativeControls
        shouldPlay
        onPlaybackStatusUpdate={handlePlaybackStatusUpdate}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 40,
  },
  title: {
    color: '#fff',
    fontSize: 20,
    marginBottom: 10,
  },
  video: {
    width: '100%',
    height: 300,
  },
});
