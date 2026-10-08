// 由 tools/pipeline/extract/parse_programmable_waves.py 生成，**不要手改**。
// 出处：sound/programmable_wave_data.s + sound/programmable_wave_samples/*.pcm
// PORT OF: sound/programmable_wave_data.s

/// 一个可编程波（GBA 波 RAM 一页 = 16 字节 = 32 个 4 位样本）
class ProgrammableWave {
  const ProgrammableWave(this.symbol, this.bytes);
  final String symbol;
  final int bytes;
}

/// 11 个波；地址由 `programmable_wave_data.s` 的注解核对过
const List<ProgrammableWave> gProgrammableWaves = [
  ProgrammableWave('wave000_sinewave', 16),
  ProgrammableWave('wave001_triangle', 16),
  ProgrammableWave('wave002_fat_saw', 16),
  ProgrammableWave('wave003_thin_saw', 16),
  ProgrammableWave('wave004_square12', 16),
  ProgrammableWave('wave005_square25', 16),
  ProgrammableWave('wave006_square37', 16),
  ProgrammableWave('wave007_square50', 16),
  ProgrammableWave('wave008_se_triangle_1', 16),
  ProgrammableWave('wave009_se_triangle_2', 16),
  ProgrammableWave('wave010_square25_e1', 16),
];

/// 键分离表在 FE8 里**未使用**（三个计数互证，见提取器判据）
const int gKeysplitTableRefs = 0;
const int gVoiceKeysplitCount = 0;
const int gVoiceKeysplitAllCount = 67;
