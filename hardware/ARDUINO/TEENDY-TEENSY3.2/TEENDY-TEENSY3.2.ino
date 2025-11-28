
#define CC1  3 
#define CC2  9 
#define CC3  102 
#define CC4  103 
#define CC5  104 
#define CC6  105 
#define CC7  106 
#define CC8  107 
#define CC9  108 
#define CC10  109 
#define CC11  110 
#define CC12  111 
#define CC13  112 
#define CC14  113 
#define CC15  114 
#define CC16  115 
#define CC17  116 
#define CC18  117 
#define CC19  118
#define CC20  119

#define POT1 A0
#define POT2 A1
#define POT3 A2
#define POT4 A3
#define POT5 A4
#define POT6 A5
#define POT7 A6
#define POT8 A7
#define POT9 A8
#define POT10 A9
#define POT11 A10
#define POT12 A11
#define POT13 A12
#define POT14 A13
#define POT15 A14
#define POT16 A15
#define POT17 A16
#define POT18 A17
#define POT19 A18
#define POT20 A19

#define MIDI_CHANNEL 1
#define LOOPS_PER_REFRESH 10000
#define POT_BIT_RES 10
#define POT_NUM_READS 32

uint16_t prev_pot_val[20] = {0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff};

uint8_t pot[20] = {POT1, POT2, POT3, POT4, POT5, POT6, POT7, POT8, POT9, POT10, POT11, POT12, POT13, POT14, POT15, POT16, POT17, POT18, POT19, POT20};

uint8_t cc[20] = {CC1, CC2, CC3, CC4, CC5, CC6, CC7, CC8, CC9, CC10, CC11, CC12, CC13, CC14, CC15, CC16, CC17, CC18, CC19, CC20};

const uint8_t nbrhd = 5;

uint16_t loop_count = 0;

void setup() {

  Serial.begin(38400);

  analogReadResolution(POT_BIT_RES);
  analogReadAveraging(POT_NUM_READS);

}

void loop() {

  for (uint8_t i = 0; i < 20; i++) {
    uint16_t pot_val = analogRead(pot[i]);
    if ((pot_val < prev_pot_val[i] - nbrhd) ||
        (pot_val > prev_pot_val[i] + nbrhd)) {
      usbMIDI.sendControlChange(cc[i], pot_val >> (POT_BIT_RES - 7), MIDI_CHANNEL);
      prev_pot_val[i] = pot_val;
    }
  }

  if (loop_count > LOOPS_PER_REFRESH) {
    for (uint8_t i = 0; i < 20; i++) {
      usbMIDI.sendControlChange(cc[i], analogRead(pot[i]) >> (POT_BIT_RES - 7), MIDI_CHANNEL);
    }
    loop_count = 0;
  }
  loop_count++;

}
