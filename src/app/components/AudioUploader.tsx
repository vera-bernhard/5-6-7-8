import { Upload } from "lucide-react";
import { Button } from "./ui/button";

interface AudioUploaderProps {
  onAudioUpload: (file: File) => void;
}

export function AudioUploader({ onAudioUpload }: AudioUploaderProps) {
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && file.type.startsWith("audio/")) {
      onAudioUpload(file);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center p-8 border-2 border-dashed rounded-lg">
      <Upload className="w-12 h-12 mb-4 text-gray-400" />
      <p className="mb-4 text-center text-gray-600">
        Upload your dance music to start adding markers
      </p>
      <label htmlFor="audio-upload">
        <Button asChild>
          <span>
            Choose Audio File
            <input
              id="audio-upload"
              type="file"
              accept="audio/*"
              onChange={handleFileChange}
              className="hidden"
            />
          </span>
        </Button>
      </label>
    </div>
  );
}
