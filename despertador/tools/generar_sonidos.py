#!/usr/bin/env python3
"""Genera los sonidos originales del despertador (sin derechos de terceros).

Uso:  python3 generar_sonidos.py <carpeta_salida>
Crea taiko.ogg, epico.ogg y amanecer.ogg (requiere numpy y ffmpeg).
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def t_axis(sec):
    return np.arange(int(sec * SR)) / SR


def lowpass(x, cutoff):
    """Filtro pasa-bajos de un polo (vectorizado por bloques)."""
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    b = 1 - a
    for i in range(len(x)):
        acc = b * x[i] + a * acc
        y[i] = acc
    return y


def place(buf, snd, at):
    i = int(at * SR)
    j = min(len(buf), i + len(snd))
    if i < len(buf):
        buf[i:j] += snd[: j - i]


def normalize(x, peak=0.89):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def save(name, left, right, out_dir):
    stereo = np.stack([left, right], axis=1)
    stereo = normalize(stereo)
    pcm = (stereo * 32767).astype(np.int16)
    wav_path = os.path.join(out_dir, name + ".wav")
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    ogg_path = os.path.join(out_dir, name + ".ogg")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
         "-c:a", "libvorbis", "-q:a", "4", ogg_path],
        check=True,
    )
    os.remove(wav_path)
    print("ok", ogg_path, os.path.getsize(ogg_path) // 1024, "KB")


# ---------------------------------------------------------------- TAIKO
def taiko_hit(strength=1.0, size=1.0):
    d = 1.4
    t = t_axis(d)
    f0 = 95 / size
    freq = f0 * (1 + 0.9 * np.exp(-t * 30))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    body = np.sin(phase) * np.exp(-t * 3.2 * size)
    body += 0.35 * np.sin(phase * 1.52) * np.exp(-t * 6)
    skin = rng.standard_normal(len(t)) * np.exp(-t * 55)
    skin = lowpass(skin, 1800)
    return (body + 0.9 * skin) * strength


def kane_hit(strength=0.25):
    t = t_axis(0.35)
    s = sum(np.sin(2 * np.pi * f * t) for f in (2350, 3170, 4420))
    return s * np.exp(-t * 22) * strength


def gen_taiko():
    bpm = 104
    beat = 60 / bpm
    bars = 16
    length = bars * 4 * beat + 1.5
    L = np.zeros(int(length * SR))
    R = np.zeros_like(L)
    big = taiko_hit(1.0, 0.8)
    mid = taiko_hit(0.65, 1.0)
    small = taiko_hit(0.45, 1.4)
    kane = kane_hit()
    # patrones de 8 corcheas: 2 = odaiko, 1 = tambor medio, 0 = silencio
    patterns = [
        [2, 0, 0, 0, 1, 0, 0, 0],
        [2, 0, 0, 1, 2, 0, 1, 0],
        [2, 0, 1, 0, 2, 1, 1, 0],
        [2, 1, 1, 1, 2, 1, 2, 1],
    ]
    for bar in range(bars):
        level = min(3, bar // 4)
        pat = patterns[level]
        for half in range(2):
            for k, v in enumerate(pat):
                at = (bar * 4) * beat + (half * 8 + k) * beat / 4
                pan = 0.5 + 0.25 * np.sin(k)
                if v == 2:
                    place(L, big * (1 - pan * 0.4), at)
                    place(R, big * (0.6 + pan * 0.4), at)
                elif v == 1:
                    snd = mid if k % 2 == 0 else small
                    place(L, snd * pan, at)
                    place(R, snd * (1 - pan), at)
        # kane (campana metálica) en cada negra desde la mitad
        if bar >= 6:
            for q in range(4):
                place(L, kane * 0.8, (bar * 4 + q) * beat)
                place(R, kane, (bar * 4 + q) * beat + 0.01)
    # cierre con redoble final
    end = bars * 4 * beat
    for i in range(8):
        place(L, small, end - 1.0 + i * 0.12)
        place(R, small, end - 1.0 + i * 0.12)
    return L, R


# ---------------------------------------------------------------- ÉPICO
def saw_pad(freqs, dur, attack=3.0):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for f in freqs:
        for det in (-0.35, 0.0, 0.4):
            ff = f * (1 + det / 100)
            ph = (ff * t + rng.random()) % 1.0
            out += 2 * ph - 1
    out /= len(freqs) * 3
    env = np.minimum(1, t / attack) * np.minimum(1, (dur - t) / 1.0)
    return out * env


def timpani(strength=1.0):
    t = t_axis(2.0)
    f = 73.4 * (1 + 0.08 * np.exp(-t * 12))
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) + 0.4 * np.sin(ph * 1.5) + 0.2 * np.sin(ph * 2)
    n = lowpass(rng.standard_normal(len(t)), 900) * np.exp(-t * 25)
    return (s * np.exp(-t * 2.2) + n) * strength


def gen_epico():
    # progresión en Re menor: Dm - Bb - F - C, cada vez más densa
    chords = [
        [73.42, 146.83, 220.0, 293.66],
        [58.27, 116.54, 233.08, 293.66],
        [87.31, 174.61, 220.0, 349.23],
        [65.41, 130.81, 196.0, 329.63],
    ]
    seg = 5.0
    rounds = 2
    length = seg * len(chords) * rounds + 2
    L = np.zeros(int(length * SR))
    R = np.zeros_like(L)
    tim = timpani()
    for r in range(rounds):
        for i, ch in enumerate(chords):
            at = (r * len(chords) + i) * seg
            freqs = ch + ([c * 2 for c in ch[1:]] if r == 1 else [])
            pad = saw_pad(freqs, seg + 1.0, attack=1.5 if r else 3.0)
            pad = lowpass(pad, 900 + 900 * r + 300 * i)
            place(L, pad * 0.9, at)
            place(R, pad * 0.9, at + 0.012)
            hits = [0, 2.5] if r == 0 else [0, 1.25, 2.5, 3.75, 4.375]
            for h in hits:
                place(L, tim * (0.6 + 0.3 * r), at + h)
                place(R, tim * (0.6 + 0.3 * r), at + h)
    # melodía de metales en la segunda vuelta
    melody = [(293.66, 2.0), (349.23, 1.0), (440.0, 2.0), (392.0, 1.0),
              (349.23, 2.0), (440.0, 2.0), (587.33, 3.0), (523.25, 3.0),
              (440.0, 4.0)]
    at = seg * len(chords)
    for f, d in melody:
        t = t_axis(d)
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
        tone = sum(np.sin(2 * np.pi * f * k * np.cumsum(vib) / SR) / k for k in range(1, 7))
        env = np.minimum(1, t / 0.12) * np.minimum(1, (d - t) / 0.3)
        place(L, tone * env * 0.22, at)
        place(R, tone * env * 0.25, at)
        at += d
    # crescendo general
    ramp = np.linspace(0.45, 1.0, len(L))
    return L * ramp, R * ramp


# ---------------------------------------------------------------- AMANECER
def bird(base, chirps=4):
    out = []
    for _ in range(chirps):
        d = rng.uniform(0.06, 0.16)
        t = t_axis(d)
        sweep = base * (1 + rng.uniform(0.2, 0.6) * np.sin(np.pi * t / d))
        ph = 2 * np.pi * np.cumsum(sweep) / SR
        env = np.sin(np.pi * t / d) ** 2
        out.append(np.sin(ph) * env)
        out.append(np.zeros(int(rng.uniform(0.03, 0.12) * SR)))
    return np.concatenate(out)


def gen_amanecer():
    length = 48.0
    n = int(length * SR)
    t = np.arange(n) / SR
    # viento suave
    wind = lowpass(rng.standard_normal(n), 400) * (0.5 + 0.3 * np.sin(2 * np.pi * t / 11))
    L = wind * 0.6
    R = lowpass(rng.standard_normal(n), 400) * 0.6 * (0.5 + 0.3 * np.cos(2 * np.pi * t / 13))
    # pad cálido en Re mayor que va subiendo
    pad_l = np.zeros(n)
    for f in (146.83, 220.0, 293.66, 369.99, 440.0):
        pad_l += np.sin(2 * np.pi * f * t + rng.random() * 6) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 9 + f))
    pad_env = np.clip(t / length, 0, 1) ** 1.5
    L += pad_l * pad_env * 0.25
    R += np.roll(pad_l, 400) * pad_env * 0.25
    # pájaros, cada vez más
    at = 1.0
    while at < length - 2:
        b = bird(rng.uniform(2600, 4800), int(rng.integers(2, 6))) * rng.uniform(0.15, 0.35)
        pan = rng.random()
        place(L, b * pan, at)
        place(R, b * (1 - pan), at)
        at += rng.uniform(0.4, 2.6) * (1.3 - at / length)
    # campanitas
    for k, f in enumerate([587.33, 739.99, 880.0, 1174.66, 880.0, 739.99] * 3):
        tt = t_axis(2.5)
        c = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt * 2.5)
        when = 8 + k * 2.1
        if when < length - 2:
            place(L, c * 0.18, when)
            place(R, c * 0.18, when + 0.02)
    ramp = np.linspace(0.5, 1.0, n)
    return L * ramp, R * ramp


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    save("taiko", *gen_taiko(), out)
    save("epico", *gen_epico(), out)
    save("amanecer", *gen_amanecer(), out)
