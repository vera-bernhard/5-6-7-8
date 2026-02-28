import { useState, useEffect } from "react";
import { Music2, ArrowLeft, Library as LibraryIcon, XCircle } from "lucide-react";
import { AudioUploader } from "./components/AudioUploader";
import { WaveformPlayer } from "./components/WaveformPlayer";
import { MarkersListView } from "./components/MarkersListView";
import { AddMarkerDialog } from "./components/AddMarkerDialog";
import { MarkerActionsDialog } from "./components/MarkerActionsDialog";
import { SettingsDialog } from "./components/SettingsDialog";
import { Library } from "./components/Library";
import { Card } from "./components/ui/card";
import { Button } from "./components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./components/ui/tabs";
import type { Marker, AudioLibraryItem } from "./types";

function App() {
  const [library, setLibrary] = useState<AudioLibraryItem[]>([]);
  const [currentItem, setCurrentItem] = useState<AudioLibraryItem | null>(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [seekToTime, setSeekToTime] = useState<number | null>(null);
  const [offsetOptions, setOffsetOptions] = useState<number[]>([5, 10, 15]);
  const [actionsDialogOpen, setActionsDialogOpen] = useState(false);
  const [selectedMarker, setSelectedMarker] = useState<Marker | null>(null);
  const [activeTab, setActiveTab] = useState<"player" | "library">("library");
  const [loopStart, setLoopStart] = useState<string | null>(null);
  const [loopEnd, setLoopEnd] = useState<string | null>(null);

  // Load library and settings from localStorage
  useEffect(() => {
    const savedLibrary = localStorage.getItem("audioLibrary");
    if (savedLibrary) {
      try {
        const items = JSON.parse(savedLibrary);
        setLibrary(items);
        if (items.length > 0) {
          setCurrentItem(items[0]);
          setActiveTab("player");
        }
      } catch (error) {
        console.error("Failed to load library:", error);
      }
    }

    const savedOffsets = localStorage.getItem("offsetOptions");
    if (savedOffsets) {
      try {
        setOffsetOptions(JSON.parse(savedOffsets));
      } catch (error) {
        console.error("Failed to load offset options:", error);
      }
    }
  }, []);

  // Save library to localStorage
  useEffect(() => {
    if (library.length > 0) {
      localStorage.setItem("audioLibrary", JSON.stringify(library));
    }
  }, [library]);

  // Save offset options to localStorage
  useEffect(() => {
    localStorage.setItem("offsetOptions", JSON.stringify(offsetOptions));
  }, [offsetOptions]);

  const handleAudioUpload = async (file: File) => {
    // Convert file to base64
    const reader = new FileReader();
    reader.onload = (e) => {
      const audioData = e.target?.result as string;
      const newItem: AudioLibraryItem = {
        id: Date.now().toString(),
        fileName: file.name,
        audioData,
        markers: [],
        createdAt: Date.now(),
      };
      const updatedLibrary = [...library, newItem];
      setLibrary(updatedLibrary);
      setCurrentItem(newItem);
      setActiveTab("player");
    };
    reader.readAsDataURL(file);
  };

  const handleSelectLibraryItem = (item: AudioLibraryItem) => {
    setCurrentItem(item);
    setActiveTab("player");
  };

  const handleDeleteLibraryItem = (id: string) => {
    const updatedLibrary = library.filter((item) => item.id !== id);
    setLibrary(updatedLibrary);
    if (currentItem?.id === id) {
      setCurrentItem(updatedLibrary.length > 0 ? updatedLibrary[0] : null);
      if (updatedLibrary.length === 0) {
        setActiveTab("library");
      }
    }
  };

  const handleAddMarker = (name: string, time: number) => {
    if (!currentItem) return;

    const newMarker: Marker = {
      id: Date.now().toString(),
      name,
      time,
    };

    const updatedItem = {
      ...currentItem,
      markers: [...currentItem.markers, newMarker],
    };

    setCurrentItem(updatedItem);
    setLibrary(
      library.map((item) => (item.id === currentItem.id ? updatedItem : item))
    );
  };

  const handleDeleteMarker = (markerId: string) => {
    if (!currentItem) return;

    const updatedItem = {
      ...currentItem,
      markers: currentItem.markers.filter((m) => m.id !== markerId),
    };

    setCurrentItem(updatedItem);
    setLibrary(
      library.map((item) => (item.id === currentItem.id ? updatedItem : item))
    );
  };

  const handleMarkerPress = (marker: Marker) => {
    setSeekToTime(marker.time);
    setTimeout(() => setSeekToTime(null), 100);
  };

  const handleMarkerLongPress = (marker: Marker) => {
    setSelectedMarker(marker);
    setActionsDialogOpen(true);
  };

  const handleJumpExact = () => {
    if (!selectedMarker) return;
    setSeekToTime(selectedMarker.time);
    setTimeout(() => setSeekToTime(null), 100);
  };

  const handleJumpWithOffset = (offset: number) => {
    if (!selectedMarker) return;
    const jumpTime = Math.max(0, selectedMarker.time - offset);
    setSeekToTime(jumpTime);
    setTimeout(() => setSeekToTime(null), 100);
  };

  const handleSetLoopStart = () => {
    if (!selectedMarker) return;
    setLoopStart(loopStart === selectedMarker.id ? null : selectedMarker.id);
  };

  const handleSetLoopEnd = () => {
    if (!selectedMarker) return;
    setLoopEnd(loopEnd === selectedMarker.id ? null : selectedMarker.id);
  };

  const handleClearLoop = () => {
    setLoopStart(null);
    setLoopEnd(null);
  };

  const handleDeleteMarkerFromDialog = () => {
    if (!selectedMarker) return;
    handleDeleteMarker(selectedMarker.id);
  };

  const getLoopStartTime = (): number | null => {
    if (!loopStart || !currentItem) return null;
    const marker = currentItem.markers.find((m) => m.id === loopStart);
    return marker ? marker.time : null;
  };

  const getLoopEndTime = (): number | null => {
    if (!loopEnd || !currentItem) return null;
    const marker = currentItem.markers.find((m) => m.id === loopEnd);
    return marker ? marker.time : null;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-md mx-auto h-screen flex flex-col">
        {/* Header */}
        <div className="bg-white border-b px-4 py-4 flex-shrink-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Music2 className="w-6 h-6 text-blue-600" />
              <h1 className="text-xl">Dance Practice</h1>
            </div>
            <SettingsDialog
              offsetOptions={offsetOptions}
              onUpdateOffsetOptions={setOffsetOptions}
            />
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 min-h-0">
          <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as any)} className="h-full flex flex-col">
            <TabsList className="mx-4 mt-4 grid w-auto grid-cols-2 flex-shrink-0">
              <TabsTrigger value="library">
                <LibraryIcon className="w-4 h-4 mr-2" />
                Library
              </TabsTrigger>
              <TabsTrigger value="player" disabled={!currentItem}>
                <Music2 className="w-4 h-4 mr-2" />
                Player
              </TabsTrigger>
            </TabsList>

            <TabsContent value="library" className="flex-1 p-4 overflow-auto">
              <Library
                items={library}
                currentItemId={currentItem?.id || null}
                onSelectItem={handleSelectLibraryItem}
                onDeleteItem={handleDeleteLibraryItem}
                onAddNew={() => {}}
              />
              <div className="mt-4">
                <AudioUploader onAudioUpload={handleAudioUpload} />
              </div>
            </TabsContent>

            <TabsContent value="player" className="flex-1 p-4 flex flex-col min-h-0 overflow-auto">
              {currentItem && (
                <>
                  {/* Current Track Info */}
                  <Card className="p-3 mb-4 flex-shrink-0">
                    <div className="flex items-center gap-2">
                      <Music2 className="w-5 h-5 text-blue-600 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{currentItem.fileName}</p>
                        <p className="text-sm text-gray-500">
                          {currentItem.markers.length} marker{currentItem.markers.length !== 1 ? "s" : ""}
                        </p>
                      </div>
                    </div>
                  </Card>

                  {/* Loop indicator */}
                  {(loopStart || loopEnd) && (
                    <Card className="p-3 mb-4 bg-blue-50 border-blue-200 flex-shrink-0">
                      <div className="flex items-center gap-2">
                        <div className="flex-1">
                          <p className="text-sm font-medium text-blue-900">
                            Loop Range Active
                          </p>
                          <p className="text-xs text-blue-700">
                            {loopStart &&
                              currentItem.markers.find((m) => m.id === loopStart)
                                ?.name}{" "}
                            →{" "}
                            {loopEnd &&
                              currentItem.markers.find((m) => m.id === loopEnd)?.name}
                          </p>
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={handleClearLoop}
                        >
                          <XCircle className="w-4 h-4" />
                        </Button>
                      </div>
                    </Card>
                  )}

                  {/* Add Marker Button */}
                  <div className="mb-4 flex-shrink-0">
                    <AddMarkerDialog
                      currentTime={currentTime}
                      onAddMarker={handleAddMarker}
                    />
                  </div>

                  {/* Waveform Player */}
                  <Card className="p-4 mb-4 flex-shrink-0">
                    <WaveformPlayer
                      audioUrl={currentItem.audioData}
                      markers={currentItem.markers}
                      onTimeUpdate={setCurrentTime}
                      seekToTime={seekToTime}
                      onMarkerPress={handleMarkerPress}
                      onMarkerLongPress={handleMarkerLongPress}
                      loopStart={getLoopStartTime()}
                      loopEnd={getLoopEndTime()}
                    />
                  </Card>

                  {/* Markers List */}
                  <Card className="p-4 flex-shrink-0">
                    <h3 className="font-semibold mb-3">Markers</h3>
                    <MarkersListView
                      markers={currentItem.markers}
                      onMarkerPress={handleMarkerPress}
                      onMarkerLongPress={handleMarkerLongPress}
                      loopStart={loopStart}
                      loopEnd={loopEnd}
                    />
                  </Card>
                </>
              )}
            </TabsContent>
          </Tabs>
        </div>

        {/* Offset Dialog */}
        <MarkerActionsDialog
          open={actionsDialogOpen}
          onOpenChange={setActionsDialogOpen}
          marker={selectedMarker}
          offsetOptions={offsetOptions}
          onJumpExact={handleJumpExact}
          onJumpWithOffset={handleJumpWithOffset}
          onSetLoopStart={handleSetLoopStart}
          onSetLoopEnd={handleSetLoopEnd}
          onDeleteMarker={handleDeleteMarkerFromDialog}
          isLoopStart={selectedMarker?.id === loopStart}
          isLoopEnd={selectedMarker?.id === loopEnd}
        />
      </div>
    </div>
  );
}

export default App;