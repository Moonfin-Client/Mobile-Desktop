String? audioLabelFromProfileCodec(String? profile, String? codec) {
  if (profile != null && profile.toLowerCase().contains('atmos')) {
    return 'Atmos';
  }
  if (codec == null || codec.isEmpty) {
    return null;
  }
  return codec.toUpperCase();
}
