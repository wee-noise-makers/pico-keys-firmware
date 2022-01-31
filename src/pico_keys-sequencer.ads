with Pico_Keys.MIDI;
with Pico_Keys.Generator;

package Pico_Keys.Sequencer is

   subtype Parent is Generator.Instance;
   type Instance is new Parent with private;

   overriding
   procedure Play (This : in out Instance);

   overriding
   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key);

   overriding
   procedure Rising (This : in out Instance;
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
   procedure Trigger (This : in out Instance);

   overriding
   procedure Clear (This : in out Instance);

   procedure Add_Rest (This : in out Instance);
   procedure Add_Tie (This : in out Instance);

   Number_Of_Steps : constant := 300;
   Notes_Per_Step : constant := 20;

   subtype Step_Index is Natural range 1 .. Number_Of_Steps;
   subtype Note_Index is Natural range 1 .. Notes_Per_Step;

   type Note_Array is array (Note_Index range <>) of MIDI.MIDI_Key;

   function In_Seq (This : Instance) return Note_Array;
   --  Return keys part of the current sequencer step
private


   type Step_Rec is record
      Count : Natural := 0;
      Notes : Note_Array (Note_Index);
      Tie   : Boolean := False;
   end record;

   type Step_Array is array (Step_Index) of Step_Rec;
   type Instance is new Parent with record
      Steps : Step_Array;
      Edit_Step : Natural := Step_Index'First - 1;
      Current_Step : Natural := 0;
      Waiting_For_Notes : Boolean := False;
   end record;

end Pico_Keys.Sequencer;
