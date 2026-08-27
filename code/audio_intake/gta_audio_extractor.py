#!/usr/bin/env python3
"""
GTA San Andreas Audio Bank Parser & Sound Extractor.
Extracts individual sounds from raw GTA SA pak files (GENRL, SCRIPT, FEET, etc.)
and generates standard RIFF/WAVE files with exact headers.
"""

import os
from pathlib import Path
import struct
import wave
from typing import Dict, List, Optional

PAK_NAMES = ["FEET", "GENRL", "PAIN_A", "SCRIPT", "SPC_EA", "SPC_FA", "SPC_GA", "SPC_NA", "SPC_PA"]


class GTAAudioBankReader:
    def __init__(self, gta_audio_dir: Path):
        self.root_dir = gta_audio_dir.resolve()
        self.config_dir = None
        self.sfx_dir = None
        self.streams_dir = None

        # Search for CONFIG and SFX recursively
        for dirpath, dirnames, filenames in os.walk(self.root_dir):
            p = Path(dirpath)
            if p.name == "CONFIG" and not self.config_dir:
                self.config_dir = p
            elif p.name == "SFX" and not self.sfx_dir:
                self.sfx_dir = p
            elif p.name == "streams" and not self.streams_dir:
                self.streams_dir = p

        if not self.config_dir or not self.sfx_dir:
            raise ValueError(f"Could not locate CONFIG and SFX folders under {self.root_dir}")

        self._load_bank_lookup()

    def _load_bank_lookup(self):
        bank_lkup_file = self.config_dir / "BankLkup.dat"
        data = bank_lkup_file.read_bytes()
        self.banks = []
        total_records = len(data) // 12
        for i in range(total_records):
            f1, offset, size = struct.unpack("<III", data[i*12:(i+1)*12])
            pak_index = f1 & 0xFF
            pak_name = PAK_NAMES[pak_index] if pak_index < len(PAK_NAMES) else f"PAK_{pak_index}"
            self.banks.append({
                "bank_id": i,
                "pak_index": pak_index,
                "pak_name": pak_name,
                "offset": offset,
                "size": size
            })

    def get_banks_for_pak(self, pak_name: str) -> List[Dict]:
        return [b for b in self.banks if b["pak_name"] == pak_name]

    def read_bank_sounds(self, bank_id: int) -> List[Dict]:
        if bank_id < 0 or bank_id >= len(self.banks):
            return []
        b_info = self.banks[bank_id]
        pak_file_path = self.sfx_dir / b_info["pak_name"]
        if not pak_file_path.exists():
            return []

        with open(pak_file_path, "rb") as f:
            f.seek(b_info["offset"])
            header = f.read(4)
            if len(header) < 4:
                return []
            sound_count, _ = struct.unpack("<HH", header)

            table_entries = []
            for s in range(sound_count):
                entry = f.read(12)
                if len(entry) < 12:
                    break
                s_off, loop_off, sample_rate, headroom = struct.unpack("<IIHH", entry)
                table_entries.append({
                    "sound_index": s,
                    "sound_offset": s_off,
                    "loop_offset": loop_off,
                    "sample_rate": sample_rate,
                    "headroom": headroom
                })

            # Calculate sound byte sizes based on subsequent sound offsets and bank size
            for i in range(len(table_entries)):
                curr_off = table_entries[i]["sound_offset"]
                if i + 1 < len(table_entries):
                    next_off = table_entries[i + 1]["sound_offset"]
                    sound_size = next_off - curr_off
                else:
                    sound_size = b_info["size"] - curr_off

                table_entries[i]["size_bytes"] = max(0, sound_size)
                if table_entries[i]["sample_rate"] > 0:
                    table_entries[i]["duration_sec"] = round(sound_size / (table_entries[i]["sample_rate"] * 2), 4)
                else:
                    table_entries[i]["duration_sec"] = 0.0

            return table_entries

    def extract_sound_wav(self, bank_id: int, sound_index: int, output_wav_path: Path) -> Optional[Path]:
        sounds = self.read_bank_sounds(bank_id)
        if sound_index < 0 or sound_index >= len(sounds):
            return None

        sound = sounds[sound_index]
        b_info = self.banks[bank_id]
        pak_file_path = self.sfx_dir / b_info["pak_name"]

        with open(pak_file_path, "rb") as f:
            f.seek(b_info["offset"] + sound["sound_offset"])
            raw_pcm = f.read(sound["size_bytes"])

        if not raw_pcm or sound["sample_rate"] <= 0:
            return None

        output_wav_path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(output_wav_path), "wb") as wf:
            wf.setnchannels(1)  # Mono 16-bit PCM
            wf.setsampwidth(2)
            wf.setframerate(sound["sample_rate"])
            wf.writeframes(raw_pcm)

        return output_wav_path


if __name__ == "__main__":
    gta_path = Path("/Volumes/YBF_Storage/128309-originalnaya-papka-audio-ot-rockstar-games-gtasa")
    reader = GTAAudioBankReader(gta_path)
    print(f"Loaded GTA reader with {len(reader.banks)} banks across {len(PAK_NAMES)} paks.")
