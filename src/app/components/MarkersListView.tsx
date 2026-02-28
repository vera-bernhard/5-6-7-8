import { useRef, useCallback } from "react";
import { Play, MoreVertical } from "lucide-react";
import { Card } from "./ui/card";
import type { Marker } from "../types";

interface MarkersListViewProps {
  markers: Marker[];
  onMarkerPress: (marker: Marker) => void;
  onMarkerLongPress: (marker: Marker) => void;
  loopStart: string | null;
  loopEnd: string | null;
}

export function MarkersListView({
  markers,
  onMarkerPress,
  onMarkerLongPress,
  loopStart,
  loopEnd,
}: MarkersListViewProps) {
  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const sortedMarkers = [...markers].sort((a, b) => a.time - b.time);

  if (markers.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500 text-sm">
        No markers yet. Add markers at key moments.
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {sortedMarkers.map((marker) => {
        const isLoopStart = loopStart === marker.id;
        const isLoopEnd = loopEnd === marker.id;
        const isInLoop = loopStart && loopEnd;

        return (
          <MarkerItem
            key={marker.id}
            marker={marker}
            onPress={onMarkerPress}
            onLongPress={onMarkerLongPress}
            isLoopStart={isLoopStart}
            isLoopEnd={isLoopEnd}
            formatTime={formatTime}
          />
        );
      })}
    </div>
  );
}

interface MarkerItemProps {
  marker: Marker;
  onPress: (marker: Marker) => void;
  onLongPress: (marker: Marker) => void;
  isLoopStart: boolean;
  isLoopEnd: boolean;
  formatTime: (time: number) => string;
}

function MarkerItem({
  marker,
  onPress,
  onLongPress,
  isLoopStart,
  isLoopEnd,
  formatTime,
}: MarkerItemProps) {
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const isLongPressRef = useRef(false);

  const handleStart = useCallback(() => {
    isLongPressRef.current = false;
    timerRef.current = setTimeout(() => {
      isLongPressRef.current = true;
      onLongPress(marker);
    }, 500);
  }, [marker, onLongPress]);

  const handleEnd = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    if (!isLongPressRef.current) {
      onPress(marker);
    }
  }, [marker, onPress]);

  const handleCancel = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    isLongPressRef.current = false;
  }, []);

  return (
    <Card
      className={`p-3 cursor-pointer transition-all active:scale-98 ${
        isLoopStart || isLoopEnd
          ? "ring-2 ring-blue-500 bg-blue-50"
          : "hover:bg-gray-50"
      }`}
      onMouseDown={handleStart}
      onMouseUp={handleEnd}
      onMouseLeave={handleCancel}
      onTouchStart={handleStart}
      onTouchEnd={handleEnd}
      onTouchCancel={handleCancel}
    >
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
          <Play className="w-4 h-4 text-blue-600" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="font-medium truncate">{marker.name}</div>
          <div className="text-sm text-gray-500">{formatTime(marker.time)}</div>
          {isLoopStart && (
            <div className="text-xs text-blue-600 font-medium">Loop Start</div>
          )}
          {isLoopEnd && (
            <div className="text-xs text-blue-600 font-medium">Loop End</div>
          )}
        </div>
        <MoreVertical className="w-5 h-5 text-gray-400 flex-shrink-0" />
      </div>
    </Card>
  );
}
