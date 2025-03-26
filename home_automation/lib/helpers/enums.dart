enum FlickyAnimatedIconOptions {
  none,
  flickybulb,
  flickytext,
  barhome,
  barrooms,
  bardevices,
  barsettings,
  barprofile,
  lightbulb,
  fan,
  hairdryer,
  bolt,
  ac,
  oven,
  lamp,
  camera,
}

enum FlickyAnimatedIconSizes {
  small(35),
  medium(60),
  large(100),
  xlarge(120),
  x2large(160);

  const FlickyAnimatedIconSizes(this.value);
  final double value;
}

enum HomeTileOptions {
  addDevice,
  manageDevices,
  energySaving,
  testConnection
}

enum AddDeviceStates {
  none,
  saving,
  saved,
  error
}

enum AppLoadingStates {
  none,
  loading,
  success,
  error
}