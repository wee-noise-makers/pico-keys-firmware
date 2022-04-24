with MIDI;
with Pico_Keys.Generator;

with Pico_Keys.Arpeggiator;
with Pico_Keys.Sequencer;
private with Pico_Keys.Keyboard;

package Pico_Keys.Meta_Gen is

   type Meta_Mode_Kind is (Key, Seq, Arp);

   subtype Parent is Generator.Instance;
   type Instance is new Parent with private;

   overriding
   function Playing (This : Instance) return Boolean;

   overriding
   procedure Play (This : in out Instance);

   overriding
   procedure Stop (This : in out Instance);

   overriding
   procedure Next_Channel (This : in out Instance);

   overriding
   procedure Prev_Channel (This : in out Instance);

   overriding
   procedure Next_Division (This : in out Instance);

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
   procedure Clear (This : in out Instance) ;

   -- Arpeggiator --
   function In_Arp (This : Instance;
                    K    : MIDI.MIDI_Key)
                    return Boolean;
   --  Return True if a key is part of the Arp sequence

   function Arp_Mode (This : Instance) return Arpeggiator.Arp_Mode;
   procedure Next_Arp_Mode (This : in out Instance);

   -- Sequencer --
   procedure Add_Rest (This : in out Instance);
   procedure Add_Tie (This : in out Instance);

   function In_Seq (This : Instance) return Sequencer.Note_Array;
   --  Return keys part of the current sequencer step

   --  Meta --
   function Current_Mode (This : Instance) return Meta_Mode_Kind;
   procedure Next_Meta (This : in out Instance);

private

   type Instance is new Parent with record
      Meta    : Meta_Mode_Kind;
      Key_Gen : Keyboard.Instance;
      Arp_Gen : Arpeggiator.Instance;
      Seq_Gen : Sequencer.Instance;
   end record;

end Pico_Keys.Meta_Gen;
