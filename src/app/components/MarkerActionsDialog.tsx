import { Play, Repeat, XCircle, Trash2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "./ui/dialog";
import { Button } from "./ui/button";
import { Separator } from "./ui/separator";
import type { Marker } from "../types";

interface MarkerActionsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  marker: Marker | null;
  offsetOptions: number[];
  onJumpExact: () => void;
  onJumpWithOffset: (offset: number) => void;
  onSetLoopStart: () => void;
  onSetLoopEnd: () => void;
  onDeleteMarker: () => void;
  isLoopStart: boolean;
  isLoopEnd: boolean;
}

export function MarkerActionsDialog({
  open,
  onOpenChange,
  marker,
  offsetOptions,
  onJumpExact,
  onJumpWithOffset,
  onSetLoopStart,
  onSetLoopEnd,
  onDeleteMarker,
  isLoopStart,
  isLoopEnd,
}: MarkerActionsDialogProps) {
  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const handleAction = (action: () => void) => {
    action();
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{marker?.name}</DialogTitle>
          <p className="text-sm text-gray-500">
            {marker && formatTime(marker.time)}
          </p>
        </DialogHeader>
        <div className="space-y-1">
          {/* Jump options */}
          <Button
            variant="ghost"
            className="w-full justify-start"
            onClick={() => handleAction(onJumpExact)}
          >
            <Play className="w-4 h-4 mr-3" />
            Jump to exact time
          </Button>
          {offsetOptions.map((offset) => {
            const offsetTime = marker ? Math.max(0, marker.time - offset) : 0;
            return (
              <Button
                key={offset}
                variant="ghost"
                className="w-full justify-start"
                onClick={() => handleAction(() => onJumpWithOffset(offset))}
              >
                <Play className="w-4 h-4 mr-3" />
                <span className="flex-1 text-left">
                  Jump {offset}s before
                </span>
                <span className="text-gray-500 text-sm">
                  {formatTime(offsetTime)}
                </span>
              </Button>
            );
          })}

          <Separator className="my-2" />

          {/* Loop options */}
          <Button
            variant="ghost"
            className="w-full justify-start"
            onClick={() => handleAction(onSetLoopStart)}
          >
            <Repeat className="w-4 h-4 mr-3" />
            {isLoopStart ? "Remove as loop start" : "Set as loop start"}
          </Button>
          <Button
            variant="ghost"
            className="w-full justify-start"
            onClick={() => handleAction(onSetLoopEnd)}
          >
            <Repeat className="w-4 h-4 mr-3" />
            {isLoopEnd ? "Remove as loop end" : "Set as loop end"}
          </Button>

          <Separator className="my-2" />

          {/* Delete */}
          <Button
            variant="ghost"
            className="w-full justify-start text-red-600 hover:text-red-700 hover:bg-red-50"
            onClick={() => handleAction(onDeleteMarker)}
          >
            <Trash2 className="w-4 h-4 mr-3" />
            Delete marker
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
