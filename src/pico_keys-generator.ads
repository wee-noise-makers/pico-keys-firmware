--  Abstract class for note generators (Arp, Seq, Keyboard, etc..)

with MIDI;
with RP.Timer;

package Pico_Keys.Generator is

   type Instance is abstract tagged private;

   type Acc is access all Instance;
   type Any_Acc is access all Instance'Class;

   -- Play --

   function Playing (This : Instance) return Boolean;
   procedure Play (This : in out Instance);
   procedure Continue (This : in out Instance);
   procedure Stop (This : in out Instance);
   procedure Toggle_Play (This : in out Instance);

   procedure Clear (This : in out Instance)
   is abstract;

   -- Keys --

   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is abstract;
   --  Call this procedure when a MIDI Key is falling

   procedure Rising (This : in out Instance;
                     K    :        MIDI.MIDI_Key)
   is abstract;
   --  Call this procedure when a MIDI Key is rising

   procedure No_Keys_Pressed (This : in out Instance)
   is abstract;
   --  Call this procedure when no MIDI keys are pressed

   -- MIDI Channel --

   function Channel (This : Instance) return MIDI.MIDI_Channel;
   procedure Next_Channel (This : in out Instance);
   procedure Prev_Channel (This : in out Instance);

   -- Time division --

   function Division (This : Instance) return Time_Div;
   procedure Next_Division (This : in out Instance);

   function Swing (This : Instance) return Time_Swing;
   procedure Next_Swing (This : in out Instance);

   procedure Signal_Step (This : in out Instance;
                          BPM  :        BPM_Range;
                          Step :        Step_Count;
                          Now  :        RP.Timer.Time);

   procedure Check_Trigger (This : in out Instance;
                            Now  :        RP.Timer.Time);

   -- Events --

   procedure Enter_Focus (This : in out Instance)
   is abstract;
   --  Call this procedure when user switch to this generator

   procedure Leave_Focus (This : in out Instance)
   is abstract;
   --  Call this procedure when user switch out of this generator

   procedure Enter_Func_Mode (This : in out Instance)
   is abstract;
   --  Call this procedure when user switch to func mode

   procedure Trigger (This : in out Instance)
   is abstract;
   --  Call this procedure to trigger the next note

   -- Playing notes --

   procedure Note_On (This : in out Instance; K : MIDI.MIDI_Key);
   --  Send a Note_On message on the generator channel for the given key

   procedure Note_Off (This : in out Instance; K : MIDI.MIDI_Key);
   --  Send a Note_Off message on the generator channel for the given key

   procedure Release_All (This : in out Instance);
   --  Send a Note_On message on the generator channel for all key that are
   --  currently on.

private

   type Key_Mask is array (MIDI.MIDI_Key) of Boolean;
   type Instance is abstract tagged record
      Chan : MIDI.MIDI_Channel := MIDI.MIDI_Channel'First;
      Notes_On : Key_Mask := (others => False);
      Div : Time_Div := Time_Div'First;
      Swing : Time_Swing := Time_Swing'First;
      Is_Playing : Boolean;

      Next_Trig : RP.Timer.Time := 0;
      First_Of_Pair : Boolean := True;
   end record;

end Pico_Keys.Generator;
