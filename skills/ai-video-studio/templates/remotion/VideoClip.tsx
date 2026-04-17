import React from 'react';
import { AbsoluteFill, Video, interpolate, useCurrentFrame } from 'remotion';

interface VideoClipProps {
  src: string;
  durationInFrames: number;
  playbackRate?: number;
  fadeIn?: number;
  fadeOut?: number;
}

export const VideoClip: React.FC<VideoClipProps> = ({
  src,
  durationInFrames,
  playbackRate = 1,
  fadeIn = 15,
  fadeOut = 15,
}) => {
  const frame = useCurrentFrame();

  // 处理 fadeIn=0 的边界情况（重要！）
  const fadeInOpacity = fadeIn > 0
    ? interpolate(frame, [0, fadeIn], [0, 1], { extrapolateRight: 'clamp' })
    : 1;
    
  const fadeOutOpacity = fadeOut > 0
    ? interpolate(
        frame,
        [durationInFrames - fadeOut, durationInFrames],
        [1, 0],
        { extrapolateLeft: 'clamp' }
      )
    : 1;

  return (
    <AbsoluteFill 
      style={{ 
        opacity: Math.min(fadeInOpacity, fadeOutOpacity),
        backgroundColor: '#000'
      }}
    >
      <Video
        src={src}
        volume={0}
        playbackRate={playbackRate}
        style={{ 
          width: '100%', 
          height: '100%', 
          objectFit: 'cover' 
        }}
      />
    </AbsoluteFill>
  );
};
