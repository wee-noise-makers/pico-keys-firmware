with RP.Timer;

with MIDI;

package Pico_Keys.Synth_UI is

   subtype Synth_Id is MIDI.MIDI_Channel range 0 .. 2;

   procedure Process_Keys (Now          : RP.Timer.Time;
                           Select_Synth : Synth_Id);
   --  Buttons.Scan and LEDs.Clear should be already done before entring this
   --  procedure.

   procedure Update_All_Parameters;
   --  This procedure will update all the parameters to the synth plug-in. It is
   --  typically used when loading saved parameters at startup.

   subtype Synth_Param_Value is MIDI.MIDI_Data range 0 .. 15;

   type Param_Id is (Timber, Timber_Env,
                     Color, Color_Env,
                     Model, Attack, Decay, Volume);

   for Param_Id use (Timber     => 0,
                     Timber_Env => 1,
                     Color      => 2,
                     Color_Env  => 3,
                     Model      => 4,
                     Attack     => 5,
                     Decay      => 6,
                     Volume     => 7);

   --  MIDI.MIDI_Data range 0 .. 6;
   type Synth_Parameters is array (Param_Id) of Synth_Param_Value;

   type All_Synth_Parameters is array (Synth_Id) of Synth_Parameters;

end Pico_Keys.Synth_UI;
