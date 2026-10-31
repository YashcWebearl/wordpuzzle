import math
import struct
import wave
import os
import random

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.95:
        samples = [s * (0.95 / max_val) for s in samples]

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit PCM
        wav_file.setframerate(SAMPLE_RATE)
        
        frames = bytearray()
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767)))
            frames.extend(struct.pack('<h', val))
        wav_file.writeframes(frames)
    print(f"Generated: {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

out_dir = "assets/music/balloon"
os.makedirs(out_dir, exist_ok=True)

# 1. Ascending Balloon Pop Chimes (8 levels: C5, D5, E5, G5, A5, C6, D6, E6)
# Rubbery bouncy bubble pop transient + sweet crystalline chime
pop_notes = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]

for idx, freq in enumerate(pop_notes):
    duration = 0.28
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        
        # Rubber "plop/bop" attack in first 20ms: pitch sweeps quickly downwards
        pitch_mult = 1.0 + (0.5 * math.exp(-120 * t))
        current_freq = freq * pitch_mult
        
        # Fast bell decay envelope
        env = math.exp(-11 * t)
        
        # Fundamental tone
        tone = math.sin(2 * math.pi * current_freq * t)
        
        # Soft warm harmonics
        h2 = 0.30 * math.sin(2 * math.pi * current_freq * 2.0 * t) * math.exp(-18 * t)
        h3 = 0.12 * math.sin(2 * math.pi * current_freq * 3.0 * t) * math.exp(-25 * t)
        
        # Rubber balloon surface pop transient at t < 0.012
        pop_transient = 0.45 * math.sin(2 * math.pi * 320 * t) * math.exp(-190 * t) if t < 0.02 else 0.0
        
        val = env * (tone + h2 + h3) + pop_transient
        samples.append(val * 0.85)
        
    write_wav(os.path.join(out_dir, f"balloon_pop_{idx + 1}.wav"), samples)

# Default pop
write_wav(os.path.join(out_dir, "balloon_pop.wav"), samples)

# 2. Balloon Burst / Explosion Pop (Dramatic balloon pop!)
# Sharp high pressure snap + tearing transient + deep air shockwave
burst_duration = 0.32
burst_total = int(SAMPLE_RATE * burst_duration)
burst_samples = []

for i in range(burst_total):
    t = i / SAMPLE_RATE
    # Sharp initial rupture spike & noise
    noise = (random.random() * 2 - 1) * math.exp(-45 * t)
    # High rubber snap (2400Hz)
    snap = math.sin(2 * math.pi * 2400 * t) * math.exp(-120 * t) * 0.7
    # Deep pressure displacement thump (70Hz down to 40Hz)
    thump = math.sin(2 * math.pi * (70 - 25 * t) * t) * math.exp(-22 * t) * 0.85
    # Elastic tearing texture
    tear = (random.random() * 2 - 1) * math.sin(2 * math.pi * 850 * t) * math.exp(-60 * t) * 0.4
    
    val = (noise * 0.6 + snap + thump + tear) * 0.95
    burst_samples.append(val)

write_wav(os.path.join(out_dir, "balloon_burst.wav"), burst_samples)

# 3. Balloon Flying Tile Arc Whistle (Smooth airy rising whoosh as tile glides up)
fly_duration = 0.32
fly_total = int(SAMPLE_RATE * fly_duration)
fly_samples = []

for i in range(fly_total):
    t = i / SAMPLE_RATE
    progress = t / fly_duration
    # Rising frequency from 450Hz to 950Hz
    f = 450 + 500 * (progress ** 1.5)
    env = math.sin(math.pi * progress)  # Smooth swell and release
    tone = math.sin(2 * math.pi * f * t) * 0.45
    h2 = math.sin(2 * math.pi * f * 2.0 * t) * 0.15
    air = (random.random() * 2 - 1) * 0.22 * env
    
    val = env * (tone + h2) + air
    fly_samples.append(val * 0.8)

write_wav(os.path.join(out_dir, "balloon_fly.wav"), fly_samples)

# 4. Combo & Praise Badge Chime (Celestial star chime arpeggio)
praise_duration = 0.70
praise_total = int(SAMPLE_RATE * praise_duration)
praise_samples = [0.0] * praise_total
praise_notes = [659.25, 830.61, 987.77, 1318.51, 1661.22] # E major sparkle

for p_idx, p_f in enumerate(praise_notes):
    start_t = p_idx * 0.055
    start_s = int(start_t * SAMPLE_RATE)
    for i in range(start_s, praise_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-6.5 * t)
        tone = math.sin(2 * math.pi * p_f * t)
        shimmer = 0.3 * math.sin(2 * math.pi * p_f * 2.01 * t) * math.exp(-12 * t)
        praise_samples[i] += env * (tone + shimmer) * 0.30

write_wav(os.path.join(out_dir, "balloon_praise.wav"), praise_samples)

# 5. Balloon Rocket Take-off Lift-Off (Celebratory upward rushing sweep + victory chime)
takeoff_duration = 1.15
takeoff_total = int(SAMPLE_RATE * takeoff_duration)
takeoff_samples = [0.0] * takeoff_total

for i in range(takeoff_total):
    t = i / takeoff_total
    t_sec = i / SAMPLE_RATE
    # Accelerating upward wind whoosh (120Hz -> 1400Hz)
    sweep_freq = 120 + 1280 * (t ** 2.2)
    env = max(0.0, math.sin(math.pi * t))
    whoosh = math.sin(2 * math.pi * sweep_freq * t_sec) * (env ** 1.3) * 0.55
    air = (random.random() * 2 - 1) * 0.28 * (env ** 1.1)
    takeoff_samples[i] += (whoosh + air) * 0.75

# Add victory chord chime at 0.35s
chord = [523.25, 659.25, 783.99, 1046.50]
for c_f in chord:
    start_s = int(0.32 * SAMPLE_RATE)
    for i in range(start_s, takeoff_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-4.2 * t)
        takeoff_samples[i] += env * math.sin(2 * math.pi * c_f * t) * 0.18

write_wav(os.path.join(out_dir, "balloon_takeoff.wav"), takeoff_samples)

# 6. Comedic Fall / Defeat Drop (Cartoon slide whistle drop downwards)
fall_duration = 0.85
fall_total = int(SAMPLE_RATE * fall_duration)
fall_samples = []

for i in range(fall_total):
    t = i / SAMPLE_RATE
    progress = max(0.0, min(1.0, t / fall_duration))
    # Pitch slides down from 1100Hz to 180Hz
    freq = 1100 - 920 * (progress ** 0.85)
    # Comic vibrato wobble
    wobble = 1.0 + 0.04 * math.sin(2 * math.pi * 14 * t)
    env = max(0.0, math.sin(math.pi * progress)) ** 0.8
    tone = math.sin(2 * math.pi * freq * wobble * t) * env * 0.65
    
    # Soft sad puff at end
    puff = (random.random() * 2 - 1) * math.exp(-15 * (fall_duration - t)) * 0.25 if t > 0.65 else 0.0
    fall_samples.append((tone + puff) * 0.85)

write_wav(os.path.join(out_dir, "balloon_fall.wav"), fall_samples)

# 7. Balloon Extra Life Inflate Sound (Rubber squeak + pneumatic puff pump)
inflate_duration = 0.38
inflate_total = int(SAMPLE_RATE * inflate_duration)
inflate_samples = []

for i in range(inflate_total):
    t = i / SAMPLE_RATE
    # High rubber stretch squeak (700Hz to 1500Hz) with rapid FM chirp
    freq = 700 + 800 * (t / inflate_duration)
    fm = math.sin(2 * math.pi * 55 * t) * 0.2
    env = math.sin(math.pi * (t / inflate_duration))
    squeak = math.sin(2 * math.pi * freq * (1 + fm) * t) * env * 0.55
    air_puff = (random.random() * 2 - 1) * env * 0.3
    inflate_samples.append((squeak + air_puff) * 0.8)

write_wav(os.path.join(out_dir, "balloon_inflate.wav"), inflate_samples)

# 8. Danger Heartbeat Tension Pulse (Low suspenseful double thump)
danger_duration = 0.60
danger_total = int(SAMPLE_RATE * danger_duration)
danger_samples = [0.0] * danger_total

# Lub-dub at t=0.0 and t=0.18
for beat_idx, beat_t in enumerate([0.0, 0.17]):
    start_s = int(beat_t * SAMPLE_RATE)
    for i in range(start_s, danger_total):
        t = (i - start_s) / SAMPLE_RATE
        env = math.exp(-22 * t)
        thump = math.sin(2 * math.pi * (62 - 15 * t) * t)
        sub = 0.5 * math.sin(2 * math.pi * (38 - 10 * t) * t)
        danger_samples[i] += (thump + sub) * env * 0.75

write_wav(os.path.join(out_dir, "balloon_danger.wav"), danger_samples)

# 9. Wrong Tile Tap Squeak (Dull rubber squeak before balloon bursts)
wrong_duration = 0.24
wrong_total = int(SAMPLE_RATE * wrong_duration)
wrong_samples = []

for i in range(wrong_total):
    t = i / SAMPLE_RATE
    # Pitch drops 260Hz to 130Hz
    freq = 260 - 130 * (t / wrong_duration)
    env = math.exp(-15 * t)
    squeak = math.sin(2 * math.pi * freq * t) * env * 0.7
    thud = math.sin(2 * math.pi * 95 * t) * math.exp(-35 * t) * 0.5
    wrong_samples.append((squeak + thud) * 0.8)

write_wav(os.path.join(out_dir, "balloon_wrong.wav"), wrong_samples)

print("All Balloon Rescue bespoke sounds successfully generated!")
