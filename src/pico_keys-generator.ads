--  Abstract class for note generators (Arp, Seq, Keyboard, etc..)

with Pico_Keys.MIDI;

package Pico_Keys.Generator is

   type Instance is abstract tagged limited private;

   type Acc is access all Instance;
   type Any_Acc is access all Instance'Class;

   -- Play --

   function Playing (This : Instance) return Boolean;
   procedure Play (This : in out Instance);
   procedure Stop (This : in out Instance);
   procedure Toggle_play (This : in out Instance);

   procedure Clear (This : in out Instance)
   is abstract;

   -- Keys --

   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is abstract;
   --  Call this procedure when a MIDI Key is falling

   procedure Raising (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is abstract;
   --  Call this procedure when a MIDI Key is raising

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
   function Do_Trigger (This : Instance; Step : Step_Count) return Boolean;

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

   procedure Trigger (This : in out Instance; Step : Step_Count)
   is abstract;
   --  Call this procedure on every 64th time div

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
   type Instance is abstract tagged limited record
      Chan : MIDI.MIDI_Channel := MIDI.MIDI_Channel'First;
      Notes_On : Key_Mask := (others => False);
      Div : Time_Div := Time_Div'First;
      Is_Playing : Boolean;
   end record;

end Pico_Keys.Generator;
