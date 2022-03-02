with HAL; use HAL;

with Pico_Keys.Save;
with Pico_Keys.Buttons;
with Pico_Keys.LEDs;

package body Pico_Keys.Synth_UI is

   Param_Shape     : constant Param_Id := 2;

   Param_Attack    : constant Param_Id := 4;
   Param_Decay     : constant Param_Id := 5;
   Param_Color_Env : constant Param_Id := 6;


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

   Current_Synth : Synth_Id := Synth_Id'First;

   Synth_Btn : constant array (Synth_Id) of Pico_Keys.Button_ID
     := (0 => Btn_G1,
         1 => Btn_G2,
         2 => Btn_G3);

   Selectd_Hue : constant LEDs.Hue := LEDs.Blue;

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

      for Sid in Synth_Id loop
         if Buttons.Falling (Synth_Btn (Sid)) then
            Current_Synth := Sid;
            exit;
         end if;
      end loop;

      LEDS.Set_Hue (Synth_Btn (Current_Synth), Selectd_Hue);

      for Id in Param_Id loop
         if Buttons.Falling (Plus_Btn (Id)) then
            Inc_Param (Current_Synth, Id);
            MIDI.Send_CC (Current_Synth, Id, Params (Current_Synth)(Id));
         elsif Buttons.Falling (Minus_Btn (Id)) then
            Dec_Param (Current_Synth, Id);
            MIDI.Send_CC (Current_Synth, Id, Params (Current_Synth)(Id));
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
   --  Set default values
   for Id in Synth_Id loop
      Params (Id)(0) := 0;
      Params (Id)(1) := 0;
      Params (Id)(Param_Shape) := UInt8 (Id) * 2;
      Params (Id)(3) := 0;
      Params (Id)(Param_Attack) := 0;
      Params (Id)(Param_Decay) := 5;
      Params (Id)(Param_Color_Env) := 0;
   end loop;
end Pico_Keys.Synth_UI;
