with Pico_Keys.MIDI;
with Pico_Keys.Generator;

package Pico_Keys.Keyboard is

   subtype Parent is Generator.Instance;
   type Instance is new Parent with private;

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
   procedure Clear (This : in out Instance)
   is null;

private

   type Instance is new Parent with null record;

end Pico_Keys.Keyboard;
