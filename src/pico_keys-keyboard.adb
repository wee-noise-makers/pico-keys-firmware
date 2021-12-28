package body Pico_Keys.Keyboard is

   -------------
   -- Falling --
   -------------

   overriding
   procedure Falling (This : in out Instance; K : MIDI.MIDI_Key) is
   begin
      This.Note_On (K);
   end Falling;

   ------------
   -- Rising --
   ------------

   overriding
   procedure Rising (This : in out Instance; K : MIDI.MIDI_Key) is
   begin
      This.Note_Off (K);
   end Rising;

   ---------------------
   -- No_Keys_Pressed --
   ---------------------

   overriding procedure No_Keys_Pressed (This : in out Instance) is
   begin
      null;
   end No_Keys_Pressed;

   -----------------
   -- Enter_Focus --
   -----------------

   overriding
   procedure Enter_Focus (This : in out Instance) is
   begin
      null;
   end Enter_Focus;

   -----------------
   -- Leave_Focus --
   -----------------

   overriding
   procedure Leave_Focus (This : in out Instance) is
   begin
      null;
   end Leave_Focus;

   ---------------------
   -- Enter_Func_Mode --
   ---------------------

   overriding procedure Enter_Func_Mode (This : in out Instance) is
   begin
      This.Release_All;
   end Enter_Func_Mode;

   -------------
   -- Trigger --
   -------------

   overriding
   procedure Trigger (This : in out Instance; Step : Step_Count) is
   begin
      null;
   end Trigger;

end Pico_Keys.Keyboard;
