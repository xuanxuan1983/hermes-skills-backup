import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Sequence,
  staticFile,
  useVideoConfig,
} from 'remotion';
import { VideoClip } from './VideoClip';

// 辅助函数：秒转帧
const sec = (s: number, fps: number = 24) => Math.round(s * fps);

export const EquationAd: React.FC = () => {
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: '#000' }}>
      {/* 全片 BGM */}
      <Audio src={staticFile('audio/bgm.mp3')} volume={0.3} />

      {/* 镜头 1: 公式浮现 (0-5s) */}
      <Sequence from={0} durationInFrames={sec(5, fps)}>
        <VideoClip
          src={staticFile('videos/01_equations.mp4')}
          durationInFrames={sec(5, fps)}
          fadeIn={0}
          fadeOut={15}
        />
      </Sequence>

      {/* 镜头 2: 粒子汇聚 (5-10s) */}
      <Sequence from={sec(5, fps)} durationInFrames={sec(5, fps)}>
        <VideoClip
          src={staticFile('videos/02_particles.mp4')}
          durationInFrames={sec(5, fps)}
          playbackRate={0.9}
        />
      </Sequence>

      {/* 镜头 3: 产品开盖 (10-16s) + 配音延迟0.5s */}
      <Sequence from={sec(10, fps)} durationInFrames={sec(6, fps)}>
        <VideoClip
          src={staticFile('videos/03_product_opening.mp4')}
          durationInFrames={sec(6, fps)}
          playbackRate={0.85}
        />
        <Sequence from={sec(0.5, fps)}>
          <Audio src={staticFile('audio/voiceover_03.mp3')} volume={1} />
        </Sequence>
      </Sequence>

      {/* 镜头 4: 点燃蜡烛 (16-22s) — 慢镜头 */}
      <Sequence from={sec(16, fps)} durationInFrames={sec(6, fps)}>
        <VideoClip
          src={staticFile('videos/04_candle.mp4')}
          durationInFrames={sec(6, fps)}
          playbackRate={0.7}
        />
        <Audio src={staticFile('audio/voiceover_04.mp3')} volume={1} />
      </Sequence>

      {/* 镜头 5: 品牌收尾 (22-30s) */}
      <Sequence from={sec(22, fps)} durationInFrames={sec(8, fps)}>
        <VideoClip
          src={staticFile('videos/05_brand.mp4')}
          durationInFrames={sec(8, fps)}
          fadeIn={20}
          fadeOut={0}
        />
        <Sequence from={sec(2, fps)}>
          <Audio src={staticFile('audio/voiceover_05.mp3')} volume={1} />
        </Sequence>
      </Sequence>

      {/* 暗角效果 - 贯穿全片 */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.4) 100%)`,
          pointerEvents: 'none',
        }}
      />
    </AbsoluteFill>
  );
};
