import { useRef, useEffect, useState } from "react";
import { Play, Pause, SkipBack, SkipForward } from "lucide-react";
import { Button } from "./ui/button";
import { MarkerLine } from "./MarkerLine";
import type { Marker } from "../types";

interface WaveformPlayerProps {
  audioUrl: string;
  markers: Marker[];
  onTimeUpdate?: (currentTime: number) => void;
  seekToTime?: number | null;
  onMarkerPress: (marker: Marker) => void;
  onMarkerLongPress: (marker: Marker) => void;
  loopStart: number | null;
  loopEnd: number | null;
}

export function WaveformPlayer({
  audioUrl,
  markers,
  onTimeUpdate,
  seekToTime,
  onMarkerPress,
  onMarkerLongPress,
  loopStart,
  loopEnd,
}: WaveformPlayerProps) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [waveformData, setWaveformData] = useState<number[]>([]);

  // Generate waveform data
  useEffect(() => {
    const generateWaveform = async () => {
      try {
        const response = await fetch(audioUrl);
        const arrayBuffer = await response.arrayBuffer();
        const audioContext = new AudioContext();
        const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);

        const rawData = audioBuffer.getChannelData(0);
        const samples = 200; // Number of bars in waveform
        const blockSize = Math.floor(rawData.length / samples);
        const filteredData = [];

        for (let i = 0; i < samples; i++) {
          const blockStart = blockSize * i;
          let sum = 0;
          for (let j = 0; j < blockSize; j++) {
            sum += Math.abs(rawData[blockStart + j]);
          }
          filteredData.push(sum / blockSize);
        }

        // Normalize the data
        const max = Math.max(...filteredData);
        const normalizedData = filteredData.map((n) => n / max);
        setWaveformData(normalizedData);
      } catch (error) {
        console.error("Error generating waveform:", error);
        // Fallback to random waveform
        const fallbackData = Array.from({ length: 200 }, () => Math.random());
        setWaveformData(fallbackData);
      }
    };

    generateWaveform();
  }, [audioUrl]);

  // Draw waveform
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || waveformData.length === 0) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();

    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);

    const width = rect.width;
    const height = rect.height;
    const barWidth = width / waveformData.length;
    const progressPercentage = duration > 0 ? currentTime / duration : 0;

    // Clear canvas
    ctx.clearRect(0, 0, width, height);

    // Draw waveform bars
    waveformData.forEach((value, index) => {
      const barHeight = value * height * 0.8;
      const x = index * barWidth;
      const y = (height - barHeight) / 2;

      // Color based on progress and loop range
      const barProgress = index / waveformData.length;
      const barTime = barProgress * duration;
      
      let fillColor = "#d1d5db"; // Default gray
      
      // Check if in loop range
      if (loopStart !== null && loopEnd !== null && barTime >= loopStart && barTime <= loopEnd) {
        fillColor = barProgress <= progressPercentage ? "#3b82f6" : "#93c5fd"; // Blue or light blue
      } else if (barProgress <= progressPercentage) {
        fillColor = "#3b82f6"; // Blue for played
      }
      
      ctx.fillStyle = fillColor;
      ctx.fillRect(x, y, Math.max(barWidth - 1, 1), barHeight);
    });

    // Draw current position line
    const currentX = progressPercentage * width;
    ctx.strokeStyle = "#1d4ed8";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(currentX, 0);
    ctx.lineTo(currentX, height);
    ctx.stroke();
  }, [waveformData, currentTime, duration, loopStart, loopEnd]);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const updateTime = () => {
      setCurrentTime(audio.currentTime);
      onTimeUpdate?.(audio.currentTime);
      
      // Check if we need to loop
      if (loopEnd !== null && audio.currentTime >= loopEnd) {
        if (loopStart !== null) {
          audio.currentTime = loopStart;
        } else {
          audio.pause();
          setIsPlaying(false);
        }
      }
    };

    const updateDuration = () => {
      setDuration(audio.duration);
    };

    const handleEnded = () => {
      setIsPlaying(false);
    };

    audio.addEventListener("timeupdate", updateTime);
    audio.addEventListener("loadedmetadata", updateDuration);
    audio.addEventListener("ended", handleEnded);

    return () => {
      audio.removeEventListener("timeupdate", updateTime);
      audio.removeEventListener("loadedmetadata", updateDuration);
      audio.removeEventListener("ended", handleEnded);
    };
  }, [onTimeUpdate, loopStart, loopEnd]);

  useEffect(() => {
    if (seekToTime !== null && seekToTime !== undefined && audioRef.current) {
      audioRef.current.currentTime = Math.max(0, seekToTime);
      audioRef.current.play();
      setIsPlaying(true);
    }
  }, [seekToTime]);

  const togglePlayPause = () => {
    const audio = audioRef.current;
    if (!audio) return;

    if (isPlaying) {
      audio.pause();
    } else {
      audio.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleWaveformClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const container = containerRef.current;
    const audio = audioRef.current;
    if (!container || !audio) return;

    const rect = container.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const percentage = x / rect.width;
    const newTime = percentage * duration;

    audio.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const skipBackward = () => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.currentTime = Math.max(0, audio.currentTime - 5);
  };

  const skipForward = () => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.currentTime = Math.min(duration, audio.currentTime + 5);
  };

  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div className="space-y-4">
      <audio ref={audioRef} src={audioUrl} />

      {/* Controls */}
      <div className="flex items-center justify-center gap-2">
        <Button variant="outline" size="icon" onClick={skipBackward}>
          <SkipBack className="w-4 h-4" />
        </Button>
        <Button size="icon" onClick={togglePlayPause} className="w-12 h-12">
          {isPlaying ? (
            <Pause className="w-5 h-5" />
          ) : (
            <Play className="w-5 h-5" />
          )}
        </Button>
        <Button variant="outline" size="icon" onClick={skipForward}>
          <SkipForward className="w-4 h-4" />
        </Button>
      </div>

      {/* Time display */}
      <div className="flex justify-between text-sm text-gray-600">
        <span>{formatTime(currentTime)}</span>
        <span>{formatTime(duration)}</span>
      </div>

      {/* Waveform with markers */}
      <div
        ref={containerRef}
        className="relative cursor-pointer"
        onClick={handleWaveformClick}
      >
        <canvas
          ref={canvasRef}
          className="w-full h-32 rounded"
          style={{ display: "block" }}
        />
        {/* Marker lines */}
        {markers.map((marker) => {
          const markerPercentage = duration > 0 ? (marker.time / duration) * 100 : 0;
          return (
            <MarkerLine
              key={marker.id}
              marker={marker}
              leftPercentage={markerPercentage}
              onPress={onMarkerPress}
              onLongPress={onMarkerLongPress}
            />
          );
        })}
      </div>
    </div>
  );
}