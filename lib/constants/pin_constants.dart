// Usage: Constants used in pin input screen
const kBiometricIdentifier = 'bio';
const kDeleteBtnIdentifier = '<';

// pin check constants
const kExpectedPinLength = 4;
const kMaxAttemptPerTurn = 3;
const kMaxTurn = 8;

const kPinInputDelayMinutesTurn1 = 1;
const kPinInputDelayMinutesTurn2 = 5;
const kPinInputDelayMinutesTurn3 = 15;
const kPinInputDelayMinutesTurn4 = 30;
const kPinInputDelayMinutesTurn5 = 60;
const kPinInputDelayMinutesTurn6 = 180;
const kPinInputDelayMinutesTurn7 = 480;
const kPinInputDelayMinutesTurn8 = 600;
const kPinInputDelayInfinite = -1;

const kLockoutDurationsPerTurn = [
  kPinInputDelayMinutesTurn1,
  kPinInputDelayMinutesTurn2,
  kPinInputDelayMinutesTurn3,
  kPinInputDelayMinutesTurn4,
  kPinInputDelayMinutesTurn5,
  kPinInputDelayMinutesTurn6,
  kPinInputDelayMinutesTurn7,
  kPinInputDelayMinutesTurn8,
  kPinInputDelayInfinite,
];
