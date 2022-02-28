with HAL; use HAL;

with Pico_Keys.Save;
with Pico_Keys.Buttons;

package body Pico_Keys.Synth_UI is

   Params : All_Synth_Parameters renames Save.RAM_State.Synth_Params;

   Plus_Btn : constant array (Param_Id) of Button_ID :=
     (0 => Btn_Ds,
      1 => Btn_D2s,
      2 => Btn_D,
      3 => Btn_F,
      4 => Btn_A,
      5 => Btn_C2,
      6 => Btn_E2);

   Minus_Btn : constant array (Param_Id) of Button_ID :=
     (0 => Btn_Cs,
      1 => Btn_C2s,
      2 => Btn_C,
      3 => Btn_E,
      4 => Btn_G,
      5 => Btn_B,
      6 => Btn_D2);

   ---------------
   -- Inc_Param --
   ---------------

   procedure Inc_Param (S : Synth_Id; P : Param_Id) is
   begin
      if Params (S)(P) < MIDI.MIDI_Data'Last then
         Params (S)(P) := Params (S)(P) + 1;
      end if;
   end Inc_Param;

   ---------------
   -- Dec_Param --
   ---------------

   procedure Dec_Param (S : Synth_Id; P : Param_Id) is
   begin
      if Params (S)(P) > MIDI.MIDI_Data'First then
         Params (S)(P) := Params (S)(P) - 1;
      end if;
   end Dec_Param;

   ------------------
   -- Process_Keys --
   ------------------

   procedure Process_Keys (Now : RP.Timer.Time) is
      pragma Unreferenced (Now);
   begin

      for Id in Param_Id loop
         if Buttons.Falling (Plus_Btn (Id)) then
            Inc_Param (0, Id);
            MIDI.Send_CC (0, Id, Params (0)(Id));
         elsif Buttons.Falling (Minus_Btn (Id)) then
            Dec_Param (0, Id);
            MIDI.Send_CC (0, Id, Params (0)(Id));
         end if;
      end loop;
   end Process_Keys;

   ---------------------------
   -- Update_All_Parameters --
   ---------------------------

   procedure Update_All_Parameters is
   begin
      for Synth in Synth_Id loop
         for Id in Param_Id loop
            MIDI.Send_CC (Synth, Id, Params (Synth)(Id));
         end loop;
      end loop;
   end Update_All_Parameters;

begin
   Params (0)(0) := MIDI.MIDI_Data'Last / 2;
   Params (0)(1) := MIDI.MIDI_Data'Last / 2;
end Pico_Keys.Synth_UI;
