with RP.Timer;

with Pico_Keys.MIDI;

package Pico_Keys.Synth_UI is

   procedure Process_Keys (Now : RP.Timer.Time);
   --  Buttons.Scan and LEDs.Clear should be already done before entring this
   --  procedure.

   procedure Update_All_Parameters;
   --  This procedure will update all the parameters to the synth plug-in. It is
   --  typically used when loading saved parameters at startup.

   subtype Param_Id is MIDI.MIDI_Data range 0 .. 6;
   type Synth_Parameters is array (Param_Id) of MIDI.MIDI_Data;

   subtype Synth_Id is MIDI.MIDI_Channel range 0 .. 2;
   type All_Synth_Parameters is array (Synth_Id) of Synth_Parameters;

end Pico_Keys.Synth_UI;
