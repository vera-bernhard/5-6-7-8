export interface Marker {
  id: string;
  time: number;
  name: string;
}

export interface AudioLibraryItem {
  id: string;
  fileName: string;
  audioData: string; // base64 encoded audio data
  markers: Marker[];
  createdAt: number;
}
