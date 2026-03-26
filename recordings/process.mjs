#!/usr/bin/env node
// process.mjs — Post-process raw.mp4 + moments.jsonl into polished.mp4 via Remotion
// Usage: node recordings/process.mjs
//
// Prerequisites:
//   npm install @remotion/cli @remotion/core remotion react react-dom
//   (or: npx create-video@latest inside recordings/ for a full Remotion project)

import { execSync, spawn } from 'child_process';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RECORDINGS_DIR = __dirname;

// ── Timing constants (ms) ─────────────────────────────────────────────────────
const CLIP_START_OFFSET_MS = 500;
const CLIP_END_OFFSET_MS   = 1000;
const MERGE_GAP_THRESHOLD  = 2000;
const SPLIT_GAP_THRESHOLD  = 3000;
const FPS = 30;

// ── Load moments ──────────────────────────────────────────────────────────────
const momentsPath = path.join(RECORDINGS_DIR, 'moments.jsonl');
if (!existsSync(momentsPath)) {
  console.error('✗ moments.jsonl not found. Run record.sh first.');
  process.exit(1);
}

const rawMp4 = path.join(RECORDINGS_DIR, 'raw.mp4');
if (!existsSync(rawMp4)) {
  console.error('✗ raw.mp4 not found. Run record.sh first.');
  process.exit(1);
}

/** @type {Array<{timestamp: number, type: string, x: number, y: number, label: string, value?: string}>} */
const moments = readFileSync(momentsPath, 'utf8')
  .trim()
  .split('\n')
  .filter(Boolean)
  .map(line => JSON.parse(line));

console.log(`✔ Loaded ${moments.length} moments`);

// ── Get video duration via ffprobe ────────────────────────────────────────────
function getVideoDurationMs(filePath) {
  const out = execSync(
    `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filePath}"`
  ).toString().trim();
  return Math.round(parseFloat(out) * 1000);
}

const videoDurationMs = getVideoDurationMs(rawMp4);
const recordingStartMs = moments.find(m => m.type === 'start')?.timestamp ?? moments[0].timestamp;

console.log(`✔ Video duration: ${(videoDurationMs / 1000).toFixed(1)}s`);

// Convert absolute wall-clock timestamps to video-relative offsets
const actionMoments = moments
  .filter(m => !['start', 'end', 'move'].includes(m.type))
  .map(m => ({
    ...m,
    videoMs: m.timestamp - recordingStartMs,
  }))
  .filter(m => m.videoMs >= 0 && m.videoMs <= videoDurationMs);

// ── Build clips ───────────────────────────────────────────────────────────────
/**
 * Each clip = { startMs, endMs, moments[] }
 */
function buildClips(actions) {
  if (!actions.length) return [{ startMs: 0, endMs: videoDurationMs, moments: [] }];

  const rawClips = actions.map(a => ({
    startMs: Math.max(0, a.videoMs - CLIP_START_OFFSET_MS),
    endMs:   Math.min(videoDurationMs, a.videoMs + CLIP_END_OFFSET_MS),
    moments: [a],
  }));

  // Merge/split
  const merged = [];
  for (const clip of rawClips) {
    const prev = merged[merged.length - 1];
    if (prev) {
      const gap = clip.startMs - prev.endMs;
      if (gap < MERGE_GAP_THRESHOLD) {
        // merge
        prev.endMs = Math.max(prev.endMs, clip.endMs);
        prev.moments.push(...clip.moments);
        continue;
      }
      if (gap > SPLIT_GAP_THRESHOLD) {
        // split — finalize prev, start new
      }
    }
    merged.push({ ...clip });
  }
  return merged;
}

const clips = buildClips(actionMoments);
console.log(`✔ Built ${clips.length} clip(s):`);
clips.forEach((c, i) =>
  console.log(`  Clip ${i + 1}: ${(c.startMs/1000).toFixed(2)}s → ${(c.endMs/1000).toFixed(2)}s  (${c.moments.length} actions)`)
);

// ── Build camera keyframes ────────────────────────────────────────────────────
/**
 * For each action moment within a clip, create a zoom-in keyframe centred on (x, y).
 * Returns array of { frameInClip, x, y, scale }
 */
function buildZoomKeyframes(clip, videoWidth = 1280, videoHeight = 720) {
  const keyframes = [];
  for (const m of clip.moments) {
    if (!m.x && !m.y) continue;
    const frameInClip = Math.round(((m.videoMs - clip.startMs) / 1000) * FPS);
    keyframes.push({
      frame: frameInClip,
      x: m.x,
      y: m.y,
      scale: 1.4,
      label: m.label,
    });
  }
  return keyframes;
}

const allKeyframes = clips.map(c => buildZoomKeyframes(c));

// ── Write Remotion composition data ──────────────────────────────────────────
const compositionData = {
  clips: clips.map((c, i) => ({
    index: i,
    startMs: c.startMs,
    endMs: c.endMs,
    durationFrames: Math.round(((c.endMs - c.startMs) / 1000) * FPS),
    keyframes: allKeyframes[i],
    moments: c.moments,
  })),
  fps: FPS,
  totalDurationFrames: clips.reduce((sum, c) => sum + Math.round(((c.endMs - c.startMs) / 1000) * FPS), 0),
};

const dataPath = path.join(RECORDINGS_DIR, 'composition-data.json');
writeFileSync(dataPath, JSON.stringify(compositionData, null, 2));
console.log(`✔ Wrote composition data to ${dataPath}`);

// ── Generate ffmpeg trim + concat commands ────────────────────────────────────
// If Remotion is not installed, fall back to pure ffmpeg post-processing.
const ffmpegInputs = clips.map((c, i) => {
  const out = path.join(RECORDINGS_DIR, `clip_${i}.mp4`);
  return {
    out,
    cmd: `ffmpeg -y -ss ${(c.startMs/1000).toFixed(3)} -to ${(c.endMs/1000).toFixed(3)} -i "${rawMp4}" -c copy "${out}"`,
  };
});

const concatListPath = path.join(RECORDINGS_DIR, 'concat.txt');
writeFileSync(concatListPath, ffmpegInputs.map(f => `file '${f.out}'`).join('\n'));

const polishedMp4 = path.join(RECORDINGS_DIR, 'polished.mp4');
const concatCmd = `ffmpeg -y -f concat -safe 0 -i "${concatListPath}" -c copy "${polishedMp4}"`;

console.log('\n── Rendering clips ──────────────────────────────────────────────');
for (const { cmd, out } of ffmpegInputs) {
  console.log(`  $ ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
  console.log(`  ✔ ${path.basename(out)}`);
}

console.log('\n── Concatenating clips ──────────────────────────────────────────');
console.log(`  $ ${concatCmd}`);
execSync(concatCmd, { stdio: 'inherit' });

console.log(`\n✔ Polished video saved to: ${polishedMp4}`);
console.log('\nOptional: open recordings/remotion-composition.tsx in a Remotion project for zoom/gradient effects.');
console.log('  npx create-video@latest recordings/remotion-project');
console.log('  cp recordings/remotion-composition.tsx recordings/remotion-project/src/');
