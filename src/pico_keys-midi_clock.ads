with RP.Timer;

package Pico_Keys.MIDI_Clock is

   type State_Kind is (Stopped, Running_Internal, Running_External);

   function State return State_Kind;
   function Step return Step_Count;

   procedure Update (Now : RP.Timer.Time);

   procedure Internal_Start;
   procedure Internal_Stop;

   procedure External_Start;
   procedure External_Stop;
   procedure External_Tick;

end Pico_Keys.MIDI_Clock;
