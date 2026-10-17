import math
import struct
import wave
import os
import random

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    # Normalize and clamp to 16-bit PCM
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.95:
        samples = [s * (0.95 / max_val) for s in samples]

    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        frames = bytearray()
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767)))
            frames.extend(struct.pack('<h', val))
        wav_file.writeframes(frames)
    print(f"Generated: {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

out_dir = "assets/music/crossword"
os.makedirs(out_dir, exist_ok=True)

# 1. Letter Tap Sounds (Pentatonic ascending C5, D5, E5, G5, A5, C6, D6, E6)
# Warm marimba / wooden kalimba chime with tactile transient click
tap_freqs = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]

for idx, freq in enumerate(tap_freqs):
    duration = 0.22
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        
        # Exponential decay envelope
        env = math.exp(-18 * t)
        
        # Fundamental + woody harmonics
        fundamental = math.sin(2 * math.pi * freq * t)
        h2 = 0.35 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-28 * t)
        h3 = 0.15 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-38 * t)
        
        # Woody transient click at start
        click = 0.4 * (random.random() * 2 - 1) * math.exp(-220 * t) if t < 0.02 else 0.0
        
        val = env * (fundamental + h2 + h3) + click
        samples.append(val * 0.8)
        
    write_wav(os.path.join(out_dir, f"cw_letter_tap_{idx + 1}.wav"), samples)

# Default letter tap
write_wav(os.path.join(out_dir, "cw_letter_tap.wav"), samples)

# 2. Word Match Sound (Sparkling harp / chime arpeggio: C5 -> E5 -> G5 -> C6 -> E6 + shimmer)
match_duration = 0.85
match_total = int(SAMPLE_RATE * match_duration)
match_samples = [0.0] * match_total
chord_notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]

for n_idx, n_freq in enumerate(chord_notes):
    start_t = n_idx * 0.065
    start_sample = int(start_t * SAMPLE_RATE)
    
    for i in range(start_sample, match_total):
        t = (i - start_sample) / SAMPLE_RATE
        env = math.exp(-5.5 * t)
        
        # Bell-like chime with subtle vibrato
        vibrato = 1.0 + 0.003 * math.sin(2 * math.pi * 6 * t)
        tone = math.sin(2 * math.pi * n_freq * vibrato * t)
        tone += 0.4 * math.sin(2 * math.pi * n_freq * 2.01 * t) * math.exp(-9 * t)
        tone += 0.2 * math.sin(2 * math.pi * n_freq * 3.0 * t) * math.exp(-14 * t)
        
        # Sparkle high chime
        shimmer = 0.15 * math.sin(2 * math.pi * n_freq * 4.0 * t) * math.exp(-12 * t)
        
        match_samples[i] += env * (tone + shimmer) * 0.35

write_wav(os.path.join(out_dir, "cw_word_match.wav"), match_samples)

# 3. Tile Land Snap Sound (Crisp tactile wooden snap / ceramic lock)
land_duration = 0.12
land_total = int(SAMPLE_RATE * land_duration)
land_samples = []

for i in range(land_total):
    t = i / SAMPLE_RATE
    # Sharp initial click
    click = (random.random() * 2 - 1) * math.exp(-180 * t)
    # Resonant hollow wood pop
    thud = math.sin(2 * math.pi * 380 * t) * math.exp(-45 * t)
    # Secondary high transient
    snap = math.sin(2 * math.pi * 1450 * t) * math.exp(-85 * t) * 0.5
    
    land_samples.append((click * 0.5 + thud * 0.5 + snap * 0.4) * 0.85)

write_wav(os.path.join(out_dir, "cw_tile_land.wav"), land_samples)

# 4. Word Not Found / Invalid (Friendly soft wooden bonk / double boing)
nf_duration = 0.35
nf_total = int(SAMPLE_RATE * nf_duration)
nf_samples = [0.0] * nf_total

for sub_idx, f in enumerate([320.0, 240.0]):
    start_sample = int(sub_idx * 0.11 * SAMPLE_RATE)
    for i in range(start_sample, nf_total):
        t = (i - start_sample) / SAMPLE_RATE
        env = math.exp(-16 * t)
        # Pitch dip for funny cute rejection
        pitch = f * (1.0 - 0.25 * t)
        tone = math.sin(2 * math.pi * pitch * t)
        harmonic = 0.3 * math.sin(2 * math.pi * pitch * 2 * t) * math.exp(-22 * t)
        nf_samples[i] += env * (tone + harmonic) * 0.45

write_wav(os.path.join(out_dir, "cw_not_found.wav"), nf_samples)

# 5. Shuffle Wheel Sound (Gentle wooden card/tile flutter whoosh)
shuf_duration = 0.38
shuf_total = int(SAMPLE_RATE * shuf_duration)
shuf_samples = []

for i in range(shuf_total):
    t = i / SAMPLE_RATE
    # Arc envelope (rise then fall)
    env = math.sin(math.pi * (t / shuf_duration))
    # Soft filtered noise
    noise = (random.random() * 2 - 1) * env * 0.35
    # Rapid flutter clicks (cards/tiles shuffling)
    flutter = math.sin(2 * math.pi * 28 * t) * math.sin(2 * math.pi * 650 * t) * env * 0.3
    # Subtle airy resonance
    air = math.sin(2 * math.pi * 420 * t) * env * 0.2
    
    shuf_samples.append((noise + flutter + air) * 0.8)

write_wav(os.path.join(out_dir, "cw_shuffle.wav"), shuf_samples)

# 6. Hint Reveal Sound (Magical fairy sparkle shimmer)
hint_duration = 0.65
hint_total = int(SAMPLE_RATE * hint_duration)
hint_samples = [0.0] * hint_total
hint_pitches = [1046.50, 1318.51, 1567.98, 2093.00, 2637.02]

for h_idx, h_f in enumerate(hint_pitches):
    start_sample = int(h_idx * 0.05 * SAMPLE_RATE)
    for i in range(start_sample, hint_total):
        t = (i - start_sample) / SAMPLE_RATE
        env = math.exp(-7.0 * t)
        sine = math.sin(2 * math.pi * h_f * t)
        shimmer = 0.3 * math.sin(2 * math.pi * (h_f * 2.02) * t) * math.exp(-12 * t)
        hint_samples[i] += env * (sine + shimmer) * 0.28

write_wav(os.path.join(out_dir, "cw_hint.wav"), hint_samples)

# 7. Level Win / Fanfare (Grand uplifting victory fanfare with bright chords)
win_duration = 1.6
win_total = int(SAMPLE_RATE * win_duration)
win_samples = [0.0] * win_total

# Rapid uplifting fanfare motif: C4 -> E4 -> G4 -> C5 -> G4 -> C5 (sustained chord)
motif = [
    (0.00, 523.25, 0.18),  # C5
    (0.12, 659.25, 0.18),  # E5
    (0.24, 783.99, 0.18),  # G5
    (0.36, 1046.50, 0.25), # C6
    (0.52, 880.00, 0.20),  # A5
    (0.68, 1046.50, 0.90), # C6 grand
    (0.68, 1318.51, 0.90), # E6 grand
    (0.68, 1567.98, 0.90), # G6 grand
]

for start_t, f, dur in motif:
    start_s = int(start_t * SAMPLE_RATE)
    decay_rate = 5.0 if dur > 0.4 else 12.0
    
    for i in range(start_s, win_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-decay_rate * t)
        # Bright brassy bell tone
        v1 = math.sin(2 * math.pi * f * t)
        v2 = 0.45 * math.sin(2 * math.pi * f * 2.0 * t) * math.exp(-decay_rate * 1.5 * t)
        v3 = 0.25 * math.sin(2 * math.pi * f * 3.0 * t) * math.exp(-decay_rate * 2.2 * t)
        sparkle = 0.15 * math.sin(2 * math.pi * f * 4.02 * t) * math.exp(-decay_rate * 2.5 * t)
        
        win_samples[i] += env * (v1 + v2 + v3 + sparkle) * 0.22

write_wav(os.path.join(out_dir, "cw_winner.wav"), win_samples)

# 8. Golden Coin Sound (Crisp double metallic ting-ting)
coin_duration = 0.55
coin_total = int(SAMPLE_RATE * coin_duration)
coin_samples = [0.0] * coin_total

for c_idx, t_offset in enumerate([0.0, 0.10]):
    start_s = int(t_offset * SAMPLE_RATE)
    f1 = 2800.0 if c_idx == 0 else 3450.0
    f2 = f1 * 1.48
    
    for i in range(start_s, coin_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-11.0 * t)
        ring1 = math.sin(2 * math.pi * f1 * t)
        ring2 = 0.4 * math.sin(2 * math.pi * f2 * t)
        sparkle = 0.2 * math.sin(2 * math.pi * (f1 * 2.1) * t) * math.exp(-22 * t)
        coin_samples[i] += env * (ring1 + ring2 + sparkle) * 0.42

write_wav(os.path.join(out_dir, "cw_coin.wav"), coin_samples)

# 9. Button Tap Sound (Juicy 3D bubble pop)
btn_duration = 0.09
btn_total = int(SAMPLE_RATE * btn_duration)
btn_samples = []

for i in range(btn_total):
    t = i / SAMPLE_RATE
    env = math.exp(-42 * t)
    # Downward pitch sweep for snappy pop
    freq = 680 * math.exp(-25 * t) + 180
    pop = math.sin(2 * math.pi * freq * t)
    transient = (random.random() * 2 - 1) * math.exp(-160 * t) * 0.2
    btn_samples.append((pop + transient) * env * 0.8)

write_wav(os.path.join(out_dir, "cw_button.wav"), btn_samples)

# 10. Countdown Tension Tick (Crisp wooden clock tick)
tick_duration = 0.12
tick_total = int(SAMPLE_RATE * tick_duration)
tick_samples = []

for i in range(tick_total):
    t = i / SAMPLE_RATE
    env = math.exp(-55 * t)
    click = (random.random() * 2 - 1) * math.exp(-250 * t) * 0.6
    body = math.sin(2 * math.pi * 920 * t) * math.exp(-60 * t) * 0.5
    tick_samples.append((click + body) * env * 0.8)

write_wav(os.path.join(out_dir, "cw_countdown.wav"), tick_samples)

# 11. Game Over / Defeat Chime (Soft descending minor triad chime)
go_duration = 0.8
go_total = int(SAMPLE_RATE * go_duration)
go_samples = [0.0] * go_total
go_notes = [587.33, 523.25, 440.00, 392.00] # D5 -> C5 -> A4 -> G4

for idx, f in enumerate(go_notes):
    start_s = int(idx * 0.14 * SAMPLE_RATE)
    for i in range(start_s, go_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-7.0 * t)
        sine = math.sin(2 * math.pi * f * t)
        overtone = 0.25 * math.sin(2 * math.pi * f * 2.0 * t) * math.exp(-12 * t)
        go_samples[i] += env * (sine + overtone) * 0.35

write_wav(os.path.join(out_dir, "cw_game_over.wav"), go_samples)

print("All crossword sounds generated successfully!")
