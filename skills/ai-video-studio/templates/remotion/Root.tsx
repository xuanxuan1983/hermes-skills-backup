import { Composition } from 'remotion';
import { EquationAd } from './EquationAd';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="EquationAd"
        component={EquationAd}
        durationInFrames={30 * 24}  // 30秒 @24fps
        fps={24}
        width={1920}
        height={1080}
        defaultProps={{
          // 可以在这里传递动态参数
        }}
      />
    </>
  );
};
