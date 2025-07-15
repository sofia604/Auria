import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import commands from '../assets/commands.json';

const circleSize = 80;
const SERVER_URL = 'http://192.168.4.2:3000/execute-sequence'; // 👈 your PC's IP

export default function GameScreen() {
  const [score, setScore] = useState(0);
  const [position, setPosition] = useState({ x: 100, y: 100 });
  const [timeLeft, setTimeLeft] = useState(30);
  const [gameOver, setGameOver] = useState(false);
  const [layout, setLayout] = useState<{ width: number; height: number } | null>(null);
  const [temp_movements,settemp_movements] = useState<string[]>([])

  //useEffect(() => {
  //  let temp_temp_movements: string[] = []
  //  commands.forEach(mov =>{
  //    temp_temp_movements.push(mov.data);
  //  })
  //  console.log(temp_temp_movements)
  //  settemp_movements(temp_temp_movements)
  //},[])

  useEffect(() => {
    if (timeLeft === 0) {
      setGameOver(true);
      return;
    }

    const timer = setInterval(() => {
      setTimeLeft((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [timeLeft]);

  useEffect(() => {
    if (gameOver) return;
    
    // Extract data values from commands.json
    let temp_movements = commands.mainData.map((cmd: any) => cmd.data);
    let flag = 0;
    console.log(temp_movements[0])
    const interval = setInterval(() => {
      if (flag < temp_movements.length) {
        fetch(SERVER_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ data: temp_movements[flag] }),
        })
          .then((res) => res.json())
          .then((data) => console.log('Robot Response:', data))
          .catch((err) => console.log('Error sending to server:', err));
        
        flag++;
      } else {
        // Reset flag when all movements are sent
        flag = 0;
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [gameOver]);

  const moveCircle = () => {
    if (!layout) return;

    const maxX = layout.width - circleSize;
    const maxY = layout.height - circleSize;

    const newX = Math.random() * maxX;
    const newY = Math.random() * maxY;

    setPosition({ x: newX, y: newY });
  };

  const handleTap = () => {
    if (gameOver) return;
    setScore(score + 1);
    moveCircle();
  };

  return (
    <View
      style={styles.container}
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        setLayout({ width, height });
      }}
    >
      <Text style={styles.header}>🎯 Tap the Circle</Text>
      <Text style={styles.info}>Score: {score} | Time: {timeLeft}s</Text>

      {layout && !gameOver && (
        <TouchableOpacity
          onPress={handleTap}
          style={[
            styles.circle,
            { top: position.y, left: position.x },
          ]}
        />
      )}

      {gameOver && (
        <Text style={styles.gameOver}>Game Over! Final Score: {score}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f7f7f7',
    paddingTop: 60,
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  info: {
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 20,
  },
  circle: {
    position: 'absolute',
    width: circleSize,
    height: circleSize,
    borderRadius: circleSize / 2,
    backgroundColor: '#3498db',
  },
  gameOver: {
    fontSize: 22,
    color: '#e74c3c',
    marginTop: 20,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});
