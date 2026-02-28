import { useState } from "react";
import { Plus } from "lucide-react";
import { Button } from "./ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "./ui/dialog";
import { Input } from "./ui/input";
import { Label } from "./ui/label";

interface AddMarkerDialogProps {
  currentTime: number;
  onAddMarker: (name: string, time: number) => void;
}

export function AddMarkerDialog({
  currentTime,
  onAddMarker,
}: AddMarkerDialogProps) {
  const [open, setOpen] = useState(false);
  const [markerName, setMarkerName] = useState("");
  const [markerTime, setMarkerTime] = useState("");

  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    const ms = Math.floor((time % 1) * 10);
    return `${minutes}:${seconds.toString().padStart(2, "0")}.${ms}`;
  };

  const handleOpenChange = (newOpen: boolean) => {
    setOpen(newOpen);
    if (newOpen) {
      setMarkerTime(formatTime(currentTime));
      setMarkerName("");
    }
  };

  const parseTime = (timeStr: string): number => {
    const parts = timeStr.split(":");
    if (parts.length !== 2) return currentTime;

    const minutes = parseInt(parts[0]) || 0;
    const secondsParts = parts[1].split(".");
    const seconds = parseInt(secondsParts[0]) || 0;
    const ms = secondsParts[1] ? parseInt(secondsParts[1]) / 10 : 0;

    return minutes * 60 + seconds + ms;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!markerName.trim()) return;

    const time = parseTime(markerTime);
    onAddMarker(markerName.trim(), time);
    setOpen(false);
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button className="w-full">
          <Plus className="w-4 h-4 mr-2" />
          Add Marker at Current Time
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add New Marker</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="marker-name">Marker Name</Label>
            <Input
              id="marker-name"
              placeholder="e.g., Chorus start, Jump sequence..."
              value={markerName}
              onChange={(e) => setMarkerName(e.target.value)}
              autoFocus
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="marker-time">Time (mm:ss.s)</Label>
            <Input
              id="marker-time"
              placeholder="0:00.0"
              value={markerTime}
              onChange={(e) => setMarkerTime(e.target.value)}
            />
          </div>
          <Button type="submit" className="w-full">
            Add Marker
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
