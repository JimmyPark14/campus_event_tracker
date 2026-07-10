import 'dart:math';
import 'dart:typed_data';

class AudioGenerator {
  /// Generates a pleasant, modern success "ding" (like a gentle chime)
  static Uint8List generateSuccessSound() {
    return _generateComplexSound(
      frequencies: [880.0, 1760.0], // A5 and A6 for a bright chime
      durationMs: 600,
      decayRate: 6.0, // Fast exponential decay
      volume: 0.3, // Soft, safe for ears
    );
  }

  /// Generates a gentle, low-pitched error "bloop"
  static Uint8List generateErrorSound() {
    return _generateComplexSound(
      frequencies: [350.0, 175.0], // Low tones
      durationMs: 500,
      decayRate: 4.0,
      volume: 0.4,
    );
  }

  static Uint8List _generateComplexSound({
    required List<double> frequencies,
    required int durationMs,
    required double decayRate,
    required double volume,
  }) {
    final int sampleRate = 44100;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    
    final byteData = ByteData(44 + numSamples * 2);
    
    // RIFF chunk
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57); // W
    byteData.setUint8(9, 0x41); // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E
    
    // fmt sub-chunk
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample
    
    // data sub-chunk
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, numSamples * 2, Endian.little);
    
    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      
      // Exponential decay envelope
      double envelope = exp(-decayRate * t);
      
      // Quick attack to prevent clicking (15ms)
      if (i < 661) {
        envelope *= (i / 661.0);
      }
      
      double sample = 0;
      for (int j = 0; j < frequencies.length; j++) {
        // Higher overtone frequencies decay faster and have less volume
        double overToneDecay = exp(-(decayRate + j*2) * t);
        sample += sin(2.0 * pi * frequencies[j] * t) * overToneDecay * (1.0 / (j + 1));
      }
      
      // Apply overall envelope (including attack)
      sample *= envelope;
      
      // Normalize and apply volume
      double value = sample * volume * 32767.0;
      
      // Hard clip just in case
      if (value > 32767) value = 32767;
      if (value < -32768) value = -32768;
      
      byteData.setInt16(44 + i * 2, value.toInt(), Endian.little);
    }
    
    return byteData.buffer.asUint8List();
  }
}
