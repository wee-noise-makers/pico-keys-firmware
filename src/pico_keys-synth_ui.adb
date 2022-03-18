with HAL; use HAL;

with Pico_Keys.Save;
with Pico_Keys.Buttons; use Pico_Keys.Buttons;
with Pico_Keys.LEDs;

package body Pico_Keys.Synth_UI is

   Params : All_Synth_Parameters renames Save.RAM_State.Synth_Params;

   Plus_Btn : constant array (Param_Id) of Button_ID :=
     (Timber     => Btn_Ds,
      Timber_Env => Btn_D,
      Color      => Btn_D2s,
      Color_Env  => Btn_E2,
      Model      => Btn_F,
      Attack     => Btn_A,
      Decay      => Btn_C2,
      Volume     => Btn_Gs);

   Minus_Btn : constant array (Param_Id) of Button_ID :=
     (Timber     => Btn_Cs,
      Timber_Env => Btn_C,
      Color      => Btn_C2s,
      Color_Env  => Btn_D2,
      Model      => Btn_E,
      Attack     => Btn_G,
      Decay      => Btn_B,
      Volume     => Btn_Fs);

   Param_Hue : constant array (Param_Id) of LEDs.Hue :=
     (Timber     => LEDS.Blue,
      Timber_Env => LEDS.Cyan,
      Color      => LEDS.Violet,
      Color_Env  => LEDs.Pink,
      Model      => LEDs.Red,
      Attack     => LEDs.Green,
      Decay      => LEDs.Orange,
      Volume     => LEDs.Yellow);

   ---------------
   -- Inc_Param --
   ---------------

   procedure Inc_Param (S : Synth_Id; P : Param_Id) is
   begin
      if Params (S)(P) < Synth_Param_Value'Last then
         Params (S)(P) := Params (S)(P) + 1;
      end if;
   end Inc_Param;

   ---------------
   -- Dec_Param --
   ---------------

   procedure Dec_Param (S : Synth_Id; P : Param_Id) is
   begin
      if Params (S)(P) > Synth_Param_Value'First then
         Params (S)(P) := Params (S)(P) - 1;
      end if;
   end Dec_Param;

   ------------------
   -- Process_Keys --
   ------------------

   procedure Process_Keys (Now          : RP.Timer.Time;
                           Select_Synth : Synth_Id)
   is
      pragma Unreferenced (Now);

   begin

      --  for Sid in Synth_Id loop
      --     if Buttons.Falling (Synth_Btn (Sid)) then
      --        Current_Synth := Sid;
      --        exit;
      --     end if;
      --  end loop;
      --
      --  LEDS.Set_Hue (Synth_Btn (Current_Synth), Selectd_Hue);


      for Id in Param_Id loop

         if Falling (Plus_Btn (Id)) or else Repeat (Plus_Btn (Id)) then

            Inc_Param (Select_Synth, Id);
            MIDI.Send_CC (Select_Synth, Id'Enum_Rep, Params (Select_Synth)(Id));

         elsif Falling (Minus_Btn (Id)) or else Repeat (Minus_Btn (Id)) then

            Dec_Param (Select_Synth, Id);
            MIDI.Send_CC (Select_Synth, Id'Enum_Rep, Params (Select_Synth)(Id));

         end if;

         declare
            Hue : constant LEDs.Hue := Param_Hue (Id);
            Val : constant UInt8 :=
              (UInt8'Last / Synth_Param_Value'Last) * UInt8(Params (Select_Synth)(Id));
         begin
            LEDs.Set_HSV (Plus_Btn (Id), Hue, UInt8'Last, Val);
            LEDs.Set_HSV (Minus_Btn (Id), Hue, UInt8'Last, UInt8'Last - Val);
         end;
      end loop;
   end Process_Keys;

   ---------------------------
   -- Update_All_Parameters --
   ---------------------------

   procedure Update_All_Parameters is
   begin
      for Synth in Synth_Id loop
         for Id in Param_Id loop
            MIDI.Send_CC (Synth, Id'Enum_Rep, Params (Synth)(Id));
         end loop;
      end loop;
   end Update_All_Parameters;

begin
   --  Set default values
   for Id in Synth_Id loop
      Params (Id)(Timber) := Synth_Param_Value'Last / 2;
      Params (Id)(Color) := Synth_Param_Value'Last / 2;
      Params (Id)(Color_Env) := 0;
      Params (Id)(Timber_Env) := 0;
      Params (Id)(Model) := Id'Enum_Rep;
      Params (Id)(Attack) := 0;
      Params (Id)(Decay) := 5;
      Params (Id)(Volume) := Synth_Param_Value'Last;
   end loop;
end Pico_Keys.Synth_UI;
