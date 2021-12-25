with HAL; use HAL;
with BBqueue.Buffers;

package Pico_Keys.MIDI is

   type Command_Kind is (Note_Off,
                         Note_On,
                         Aftertouch,
                         Continous_Controller,
                         Patch_Change,
                         Channel_Pressure,
                         Pitch_Bend)
     with Size => 4;

   for Command_Kind use (Note_Off             => 16#8#,
                         Note_On              => 16#9#,
                         Aftertouch           => 16#A#,
                         Continous_Controller => 16#B#,
                         Patch_Change         => 16#C#,
                         Channel_Pressure     => 16#D#,
                         Pitch_Bend           => 16#E#);

   subtype MIDI_Data is UInt8 range 2#0000_0000# .. 2#0111_1111#;
   subtype MIDI_Key is MIDI_Data;
   type MIDI_Channel is mod 2**4 with Size => 4;

   type Message (Kind : Command_Kind := Note_On) is record
      Chan : MIDI_Channel;
      case Kind is
         when Note_On | Note_Off | Aftertouch =>
            Key      : MIDI_Key;
            Velocity : MIDI_Data;
         when Continous_Controller =>
            Controller       : MIDI_Data;
            Controller_Value : MIDI_Data;
         when Patch_Change =>
            Instrument : MIDI_Data;
         when Channel_Pressure =>
            Pressure : MIDI_Data;
         when Pitch_Bend =>
            Bend : MIDI_Data;
      end case;
   end record
     with Size => 3 * 8;

   for Message use record
      Kind             at 0 range 4 .. 7;
      Chan             at 0 range 0 .. 3;
      Key              at 1 range 0 .. 7;
      Velocity         at 2 range 0 .. 7;
      Controller       at 1 range 0 .. 7;
      Controller_Value at 2 range 0 .. 7;
      Instrument       at 1 range 0 .. 7;
      Pressure         at 1 range 0 .. 7;
      Bend             at 1 range 0 .. 7;
   end record;

   procedure Send (M : Message);

   procedure Send_Note_On (K    : MIDI_Key;
                           Chan : MIDI_Channel);

   procedure Send_Note_Off (K : MIDI_Key;
                           Chan : MIDI_Channel);

   type Octaves is new UInt8 range 1 .. 8;
   type Notes is (C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B);

   function Key (Oct : Octaves; N : Notes) return MIDI_Key
   is (MIDI_Key (12 + Natural (Oct) * 12 +
         Notes'Pos (N) - Notes'Pos (Notes'First)));

   A0  : constant MIDI_Key := 16#15#;
   As0 : constant MIDI_Key := 16#16#;
   B0  : constant MIDI_Key := 16#17#;
   C1  : constant MIDI_Key := 16#18#;
   Cs1 : constant MIDI_Key := 16#19#;
   D1  : constant MIDI_Key := 16#1a#;
   Ds1 : constant MIDI_Key := 16#1b#;
   E1  : constant MIDI_Key := 16#1c#;
   F1  : constant MIDI_Key := 16#1d#;
   Fs1 : constant MIDI_Key := 16#1e#;
   G1  : constant MIDI_Key := 16#1f#;
   Gs1 : constant MIDI_Key := 16#20#;
   A1  : constant MIDI_Key := 16#21#;
   As1 : constant MIDI_Key := 16#22#;
   B1  : constant MIDI_Key := 16#23#;
   C2  : constant MIDI_Key := 16#24#;
   Cs2 : constant MIDI_Key := 16#25#;
   D2  : constant MIDI_Key := 16#26#;
   Ds2 : constant MIDI_Key := 16#27#;
   E2  : constant MIDI_Key := 16#28#;
   F2  : constant MIDI_Key := 16#29#;
   Fs2 : constant MIDI_Key := 16#2a#;
   G2  : constant MIDI_Key := 16#2b#;
   Gs2 : constant MIDI_Key := 16#2c#;
   A2  : constant MIDI_Key := 16#2d#;
   As2 : constant MIDI_Key := 16#2e#;
   B2  : constant MIDI_Key := 16#2f#;
   C3  : constant MIDI_Key := 16#30#;
   Cs3 : constant MIDI_Key := 16#31#;
   D3  : constant MIDI_Key := 16#32#;
   Ds3 : constant MIDI_Key := 16#33#;
   E3  : constant MIDI_Key := 16#34#;
   F3  : constant MIDI_Key := 16#35#;
   Fs3 : constant MIDI_Key := 16#36#;
   G3  : constant MIDI_Key := 16#37#;
   Gs3 : constant MIDI_Key := 16#38#;
   A3  : constant MIDI_Key := 16#39#;
   As3 : constant MIDI_Key := 16#3a#;
   B3  : constant MIDI_Key := 16#3b#;
   C4  : constant MIDI_Key := 16#3c#;
   Cs4 : constant MIDI_Key := 16#3d#;
   D4  : constant MIDI_Key := 16#3e#;
   Ds4 : constant MIDI_Key := 16#3f#;
   E4  : constant MIDI_Key := 16#40#;
   F4  : constant MIDI_Key := 16#41#;
   Fs4 : constant MIDI_Key := 16#42#;
   G4  : constant MIDI_Key := 16#43#;
   Gs4 : constant MIDI_Key := 16#44#;
   A4  : constant MIDI_Key := 16#45#;
   As4 : constant MIDI_Key := 16#46#;
   B4  : constant MIDI_Key := 16#47#;
   C5  : constant MIDI_Key := 16#48#;
   Cs5 : constant MIDI_Key := 16#49#;
   D5  : constant MIDI_Key := 16#4a#;
   Ds5 : constant MIDI_Key := 16#4b#;
   E5  : constant MIDI_Key := 16#4c#;
   F5  : constant MIDI_Key := 16#4d#;
   Fs5 : constant MIDI_Key := 16#4e#;
   G5  : constant MIDI_Key := 16#4f#;
   Gs5 : constant MIDI_Key := 16#50#;
   A5  : constant MIDI_Key := 16#51#;
   As5 : constant MIDI_Key := 16#52#;
   B5  : constant MIDI_Key := 16#53#;
   C6  : constant MIDI_Key := 16#54#;
   Cs6 : constant MIDI_Key := 16#55#;
   D6  : constant MIDI_Key := 16#56#;
   Ds6 : constant MIDI_Key := 16#57#;
   E6  : constant MIDI_Key := 16#58#;
   F6  : constant MIDI_Key := 16#59#;
   Fs6 : constant MIDI_Key := 16#5a#;
   G6  : constant MIDI_Key := 16#5b#;
   Gs6 : constant MIDI_Key := 16#5c#;
   A6  : constant MIDI_Key := 16#5d#;
   As6 : constant MIDI_Key := 16#5e#;
   B6  : constant MIDI_Key := 16#5f#;
   C7  : constant MIDI_Key := 16#60#;
   Cs7 : constant MIDI_Key := 16#61#;
   D7  : constant MIDI_Key := 16#62#;
   Ds7 : constant MIDI_Key := 16#63#;
   E7  : constant MIDI_Key := 16#64#;
   F7  : constant MIDI_Key := 16#65#;
   Fs7 : constant MIDI_Key := 16#66#;
   G7  : constant MIDI_Key := 16#67#;
   Gs7 : constant MIDI_Key := 16#68#;
   A7  : constant MIDI_Key := 16#69#;
   As7 : constant MIDI_Key := 16#6a#;
   B7  : constant MIDI_Key := 16#6b#;
   C8  : constant MIDI_Key := 16#6c#;
   Cs8 : constant MIDI_Key := 16#6d#;
   D8  : constant MIDI_Key := 16#6e#;
   Ds8 : constant MIDI_Key := 16#6f#;
   E8  : constant MIDI_Key := 16#70#;
   F8  : constant MIDI_Key := 16#71#;
   Fs8 : constant MIDI_Key := 16#72#;
   G8  : constant MIDI_Key := 16#73#;
   Gs8 : constant MIDI_Key := 16#74#;
   A8  : constant MIDI_Key := 16#75#;
   As8 : constant MIDI_Key := 16#76#;
   B8  : constant MIDI_Key := 16#77#;

private

   MIDI_Serial_Queue : BBqueue.Buffers.Buffer (2048);

end Pico_Keys.MIDI;
