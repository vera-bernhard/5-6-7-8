import { useState } from "react";
import { Settings, Plus, X } from "lucide-react";
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

interface SettingsDialogProps {
  offsetOptions: number[];
  onUpdateOffsetOptions: (options: number[]) => void;
}

export function SettingsDialog({
  offsetOptions,
  onUpdateOffsetOptions,
}: SettingsDialogProps) {
  const [open, setOpen] = useState(false);
  const [newOffset, setNewOffset] = useState("");

  const handleAddOffset = () => {
    const value = parseInt(newOffset);
    if (value > 0 && !offsetOptions.includes(value)) {
      const updated = [...offsetOptions, value].sort((a, b) => a - b);
      onUpdateOffsetOptions(updated);
      setNewOffset("");
    }
  };

  const handleRemoveOffset = (offset: number) => {
    onUpdateOffsetOptions(offsetOptions.filter((o) => o !== offset));
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="icon">
          <Settings className="w-5 h-5" />
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Settings</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label className="text-base mb-2 block">Offset Options (seconds)</Label>
            <p className="text-sm text-gray-500 mb-3">
              Configure which offset options appear when long-pressing a marker
            </p>
            <div className="space-y-2 mb-3">
              {offsetOptions.map((offset) => (
                <div
                  key={offset}
                  className="flex items-center justify-between p-2 bg-gray-50 rounded"
                >
                  <span>{offset} seconds</span>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleRemoveOffset(offset)}
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <Input
                type="number"
                placeholder="Add new offset..."
                value={newOffset}
                onChange={(e) => setNewOffset(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    handleAddOffset();
                  }
                }}
              />
              <Button onClick={handleAddOffset}>
                <Plus className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
