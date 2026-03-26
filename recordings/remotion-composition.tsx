// remotion-composition.tsx
// Drop this into your Remotion project's src/ directory.
// It reads composition-data.json and renders each clip with zoom + gradient background.
//
// Usage inside a Remotion project:
//   1. npx create-video@latest
//   2. cp remotion-composition.tsx src/
//   3. cp ../composition-data.json src/
//   4. cp ../clip_*.mp4 src/
//   5. Register in src/index.ts: registerRoot(Root)
//   6. npx remotion render src/index.ts Recording polished-remotion.mp4

import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
  Video,
  Sequence,
} from 'remotion';
import compositionData from './composition-data.json';

// ── Types ─────────────────────────────────────────────────────────────────────
interface Keyframe {
  frame: number;
  x: number;
  y: number;
  scale: number;
  label: string;
}

interface ClipData {
  index: number;
  startMs: number;
  endMs: number;
  durationFrames: number;
  keyframes: Keyframe[];
  moments: Array<{ videoMs: number; type: string; label: string; x: number; y: number }>;
}

// ── Zoom helper ───────────────────────────────────────────────────────────────
function useZoom(keyframes: Keyframe[], frame: number, fps: number) {
  if (!keyframes.length) return { scale: 1, translateX: 0, translateY: 0 };

  // Find surrounding keyframes
  const before = [...keyframes].reverse().find(k => k.frame <= frame) ?? keyframes[0];
  const after  = keyframes.find(k => k.frame > frame) ?? keyframes[keyframes.length - 1];

  const progress = before === after
    ? 1
    : spring({ frame: frame - before.frame, fps, config: { damping: 80, stiffness: 200 } });

  const scale = interpolate(progress, [0, 1], [1, before.scale]);

  // Translate to centre zoom on action coordinates (assumes 1280×720 canvas)
  const canvasW = 1280;
  const canvasH = 720;
  const targetX = interpolate(progress, [0, 1], [canvasW / 2, before.x]);
  const targetY = interpolate(progress, [0, 1], [canvasH / 2, before.y]);
  const translateX = (canvasW / 2 - targetX) * (scale - 1);
  const translateY = (canvasH / 2 - targetY) * (scale - 1);

  return { scale, translateX, translateY };
}

// ── Single clip component ─────────────────────────────────────────────────────
const Clip: React.FC<{ clip: ClipData; src: string }> = ({ clip, src }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { scale, translateX, translateY } = useZoom(clip.keyframes, frame, fps);

  return (
    <AbsoluteFill
      style={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <div
        style={{
          width: 1280,
          height: 720,
          overflow: 'hidden',
          borderRadius: 12,
          boxShadow: '0 32px 80px rgba(0,0,0,0.45)',
          transform: `scale(${scale}) translate(${translateX}px, ${translateY}px)`,
          transformOrigin: 'center center',
        }}
      >
        <Video
          src={src}
          startFrom={Math.round((clip.startMs / 1000) * fps)}
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />
      </div>
    </AbsoluteFill>
  );
};

// ── Root composition ──────────────────────────────────────────────────────────
export const Recording: React.FC = () => {
  const clips: ClipData[] = compositionData.clips;
  let offset = 0;

  return (
    <>
      {clips.map((clip) => {
        const from = offset;
        offset += clip.durationFrames;
        return (
          <Sequence key={clip.index} from={from} durationInFrames={clip.durationFrames}>
            <Clip clip={clip} src={`./clip_${clip.index}.mp4`} />
          </Sequence>
        );
      })}
    </>
  );
};

// ── Register root (entry point) ───────────────────────────────────────────────
import { Composition } from 'remotion';

export const Root: React.FC = () => (
  <Composition
    id="Recording"
    component={Recording}
    durationInFrames={compositionData.totalDurationFrames}
    fps={compositionData.fps}
    width={1920}
    height={1080}
  />
);
