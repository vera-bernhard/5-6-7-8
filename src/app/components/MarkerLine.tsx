import { useRef, useCallback } from "react";
import type { Marker } from "../types";

interface MarkerLineProps {
  marker: Marker;
  leftPercentage: number;
  onPress: (marker: Marker) => void;
  onLongPress: (marker: Marker) => void;
}

export function MarkerLine({
  marker,
  leftPercentage,
  onPress,
  onLongPress,
}: MarkerLineProps) {
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const isLongPressRef = useRef(false);

  const handleStart = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      e.stopPropagation();
      isLongPressRef.current = false;
      timerRef.current = setTimeout(() => {
        isLongPressRef.current = true;
        onLongPress(marker);
      }, 500);
    },
    [marker, onLongPress]
  );

  const handleEnd = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      e.stopPropagation();
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
      if (!isLongPressRef.current) {
        onPress(marker);
      }
    },
    [marker, onPress]
  );

  const handleCancel = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    isLongPressRef.current = false;
  }, []);

  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div
      className="absolute top-0 bottom-0 cursor-pointer group z-10"
      style={{ left: `${leftPercentage}%` }}
      onMouseDown={handleStart}
      onMouseUp={handleEnd}
      onMouseLeave={handleCancel}
      onTouchStart={handleStart}
      onTouchEnd={handleEnd}
      onTouchCancel={handleCancel}
    >
      {/* Vertical line */}
      <div className="absolute top-0 bottom-0 w-1 bg-red-500 shadow-lg transform -translate-x-1/2 group-hover:w-1.5 transition-all" />
      
      {/* Marker label on hover */}
      <div className="absolute bottom-full mb-2 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap">
        <div className="bg-gray-900 text-white text-xs px-2 py-1 rounded shadow-lg">
          <div className="font-medium">{marker.name}</div>
          <div className="text-gray-300">{formatTime(marker.time)}</div>
        </div>
        {/* Arrow */}
        <div className="absolute top-full left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-gray-900" />
      </div>
    </div>
  );
}
