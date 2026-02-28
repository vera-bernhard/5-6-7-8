import { Music2, Play, Trash2, Plus } from "lucide-react";
import { Button } from "./ui/button";
import { Card } from "./ui/card";
import type { AudioLibraryItem } from "../types";

interface LibraryProps {
  items: AudioLibraryItem[];
  currentItemId: string | null;
  onSelectItem: (item: AudioLibraryItem) => void;
  onDeleteItem: (id: string) => void;
  onAddNew: () => void;
}

export function Library({
  items,
  currentItemId,
  onSelectItem,
  onDeleteItem,
  onAddNew,
}: LibraryProps) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Your Library</h2>
        <Button onClick={onAddNew} size="sm">
          <Plus className="w-4 h-4 mr-1" />
          Add New
        </Button>
      </div>

      {items.length === 0 ? (
        <Card className="p-8 text-center">
          <Music2 className="w-12 h-12 mx-auto mb-3 text-gray-400" />
          <p className="text-gray-500 mb-4">No audio files yet</p>
          <Button onClick={onAddNew}>
            <Plus className="w-4 h-4 mr-2" />
            Upload Your First Track
          </Button>
        </Card>
      ) : (
        <div className="space-y-2">
          {items.map((item) => (
            <Card
              key={item.id}
              className={`p-3 cursor-pointer transition-all ${
                currentItemId === item.id
                  ? "ring-2 ring-blue-500 bg-blue-50"
                  : "hover:bg-gray-50"
              }`}
              onClick={() => onSelectItem(item)}
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                    currentItemId === item.id
                      ? "bg-blue-500 text-white"
                      : "bg-gray-100"
                  }`}
                >
                  <Music2 className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium truncate">{item.fileName}</p>
                  <p className="text-sm text-gray-500">
                    {item.markers.length} marker{item.markers.length !== 1 ? "s" : ""}
                  </p>
                </div>
                {currentItemId === item.id && (
                  <Play className="w-5 h-5 text-blue-500 flex-shrink-0" />
                )}
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={(e) => {
                    e.stopPropagation();
                    onDeleteItem(item.id);
                  }}
                >
                  <Trash2 className="w-4 h-4 text-red-500" />
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
