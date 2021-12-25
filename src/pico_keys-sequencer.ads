with Pico_Keys.MIDI;
with Pico_Keys.Generator;

package Pico_Keys.Sequencer is

   subtype Parent is Generator.Instance;
   type Instance is new Parent with private;

   overriding
   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key);

   overriding
   procedure Raising (This : in out Instance;
                      K    :        MIDI.MIDI_Key);

   overriding
   procedure No_Keys_Pressed (This : in out Instance);

   overriding
   procedure Enter_Focus (This : in out Instance);

   overriding
   procedure Leave_Focus (This : in out Instance);

   overriding
   procedure Enter_Func_Mode (This : in out Instance);

   overriding
   procedure Trigger (This : in out Instance; Step : Step_Count);

   procedure Clear (This : in out Instance);

private

   Number_Of_Steps : constant := 300;
   Notes_Pre_Step : constant := 20;

   subtype Step_Index is Natural range 1 .. Number_Of_Steps;
   subtype Note_Index is Natural range 1 .. Notes_Pre_Step;

   type Note_Array is array (Note_Index) of MIDI.MIDI_Key;

   type Step_Rec is record
      Count : Natural := 0;
      Notes : Note_Array;
   end record;

   type Step_Array is array (Step_Index) of Step_Rec;
   type Instance is new Parent with record
      Steps : Step_Array;
      Edit_Step : Natural := Step_Index'First - 1;
      Current_Step : Natural := 0;
      Waiting_For_Notes : Boolean := False;
   end record;

end Pico_Keys.Sequencer;
