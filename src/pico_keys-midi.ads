with MIDI; use MIDI;

private with MIDI.Decoder.Queue;
private with MIDI.Encoder.Queue;

package Pico_Keys.MIDI is

   procedure Send (M : Message);

   procedure Send_Note_On (K    : MIDI_Key;
                           Chan : MIDI_Channel);

   procedure Send_Note_Off (K : MIDI_Key;
                            Chan : MIDI_Channel);

   procedure Send_CC (Chan       : MIDI_Channel;
                      Controller : MIDI_Data;
                      Value      : MIDI_Data);

   procedure Send_Clock_Tick;
   procedure Send_Start;
   procedure Send_Stop;

   procedure Process_Input;

private

   Decoder_Queue : Standard.MIDI.Decoder.Queue.Instance (128);
   Encoder_Queue : Standard.MIDI.Encoder.Queue.Instance (1024);

end Pico_Keys.MIDI;
