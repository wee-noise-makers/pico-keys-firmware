with HAL; use HAL;

with MIDI;

with Pico_Keys; use Pico_Keys;

with Pico_Keys.Arpeggiator;
with Pico_Keys.LEDs;
with Pico_Keys.Buttons;
with Pico_Keys.MIDI_Clock;
with Pico_Keys.Meta_Gen; use Pico_Keys.Meta_Gen;
with Pico_Keys.Save; use Pico_Keys.Save;

with RP.Timer; use RP.Timer;

package body Pico_Keys.Gen_UI is

   Gen_Btn : constant array (Gen_Id) of Pico_Keys.Button_ID
     := (1 => Btn_G1,
         2 => Btn_G2,
         3 => Btn_G3);

   Load_Save_Mode : Boolean := True;
   Save_Blink_Until : RP.Timer.Time;
   Save_Blink_Hue   : LEDs.Hue;
   Save_Blink_Duration : constant RP.Timer.Time := Ticks_Per_Second / 2;

   Generators : Pico_Keys.Save.Gen_Array renames RAM_State.Generators;
   BPM        : BPM_Range                renames RAM_State.BPM;
   Base_Note  : MIDI.MIDI_Key            renames RAM_State.Base_Note;

   Save_Slot_To_Btn : constant array (Valid_Save_Slot) of Button_ID :=
     (1  => Btn_C,
      2  => Btn_D,
      3  => Btn_E,
      4  => Btn_F,
      5  => Btn_G,
      6  => Btn_A,
      7  => Btn_B,
      8  => Btn_C2,
      9  => Btn_D2,
      10 => Btn_E2);

   ------------------
   -- Process_Keys --
   ------------------

   procedure Process_Keys (Now         :        RP.Timer.Time;
                           Current_Gen : in out Gen_Id)
   is
      Playing_Before, Playing_After : Boolean;

      Step : constant Step_Count := MIDI_Clock.Step;
   begin
      Playing_Before := (for some G of Generators => G.Playing);

      if Buttons.Falling (Btn_Func) then
         Generators (Current_Gen).Enter_Func_Mode;

         --  When entering func mode, reset the double press / long press
         --  system.
         Buttons.Reset_Dbl_Long;
         Load_Save_Mode := False;
         Save_Blink_Until := RP.Timer.Time'First;
      end if;

      Generators (Current_Gen).No_Keys_Pressed;

      if Load_Save_Mode then

         if Save.Last_Load in Valid_Save_Slot then
            LEDs.Set_Hue (Save_Slot_To_Btn (Save.Last_Load), LEDs.Green);
         end if;

         for S in Valid_Save_Slot loop
            declare
               Btn : constant Button_ID := Save_Slot_To_Btn (S);
            begin
               if Buttons.Double_Press (Btn) then
                  Save.Load_From_Flash (S);
                  Load_Save_Mode := False;

                  Save_Blink_Hue := LEDs.Green; --  Green means loading...
                  Save_Blink_Until := Now + Save_Blink_Duration;

                  exit;

               elsif Buttons.Long_Press (Btn) then

                  Save.Save_To_Flash (S);
                  Load_Save_Mode := False;

                  Save_Blink_Hue := LEDs.Red; --  Red means recording ^^
                  Save_Blink_Until := Now + Save_Blink_Duration;
                  exit;
               end if;
            end;
         end loop;

      else

         --  Time Div LED
         if On_Time (Generators (Current_Gen).Division, Step) then
            if Generators (Current_Gen).Division in Div_4 .. Div_32 then
               LEDS.Set_Hue (Btn_Time_Div, LEDs.Beat_Hue, LEDs.Fade);
            else
               LEDS.Set_Hue (Btn_Time_Div, LEDs.Triplet_Hue, LEDs.Fade);
            end if;
         end if;

         --  Time Swing LED
         if (case Generators (Current_Gen).Swing is
                when Swing_Off => False,
                when Swing_55  => (Step mod 24) = 0,
                when Swing_60  => (Step mod 12) = 0,
                when Swing_65  => (Step mod  6) = 0,
                when Swing_70  => (Step mod  3) = 0,
                when Swing_75  => True)
         then
            LEDS.Set_Hue (Btn_Time_Swing, LEDs.Beat_Hue);
         end if;

         --  MIDI channel +/-
         if Buttons.Falling (Btn_Chan_Plus) then
            Generators (Current_Gen).Next_Channel;
         elsif Buttons.Falling (Btn_Chan_Minus) then
            Generators (Current_Gen).Prev_Channel;
         end if;

         --  Base note +/-
         if Buttons.Falling (Btn_Oct_Plus) and then Base_Note < 96 then
            Base_Note := Base_Note + 12;
         elsif Buttons.Falling (Btn_Oct_Minus) and then Base_Note > 24 then
            Base_Note := Base_Note - 12;
         end if;

         --  BPM +/-
         if (Buttons.Falling (Btn_BPM_Plus) or else Buttons.Repeat (Btn_BPM_Plus))
           and then BPM <= (BPM_Range'Last - BPM_Step)
         then
            BPM := BPM + BPM_Step;

         elsif (Buttons.Falling (Btn_BPM_Minus) or else Buttons.Repeat (Btn_BPM_Minus))
           and then BPM >= (BPM_Range'First + BPM_Step)
         then
            BPM := BPM - BPM_Step;
         end if;

         if Pico_Keys.On_Time (Pico_Keys.Div_4, Step) then
            LEDS.Set_Hue (Btn_BPM_Plus, LEDs.Beat_Hue, LEDs.Fade);
            LEDS.Set_Hue (Btn_BPM_Minus, LEDs.Beat_Hue, LEDs.Fade);
         end if;

         --  ARP Mode select
         if Buttons.Falling (Btn_Arp_Mode) then
            Generators (Current_Gen).Next_Arp_Mode;
         end if;

         --  Time Div select
         if Buttons.Falling (Btn_Time_Div) then
            Generators (Current_Gen).Next_Division;
         end if;

         --  Time Swing select
         if Buttons.Falling (Btn_Time_Swing) then
            Generators (Current_Gen).Next_Swing;
         end if;

         --  Meta mode select
         if Buttons.Falling (Btn_Meta_Mode) then
            Generators (Current_Gen).Next_Meta;
         end if;

         --  Save / Load
         if Buttons.Rising (Btn_Save) then
            Load_Save_Mode := True;
         end if;

         if Now <= Save_Blink_Until then
            LEDS.Set_Hue (Btn_Save, Save_Blink_Hue, LEDs.Blink_Fast);
         end if;

         --  Clear
         if Buttons.Falling (Btn_Clear) then
            Generators (Current_Gen).Clear;
         end if;

         LEDs.Set_Hue (Gen_Btn (Current_Gen),
                       LEDs.Gen_Hue (Generators (Current_Gen).Current_Mode),
                       Effect => (if Generators (Current_Gen).Playing
                                  then LEDs.Blink_Fast
                                  else LEDs.None));

         case Generators (Current_Gen).Current_Mode is
         when Key =>

            LEDS.Set_Hue (Btn_Meta_Mode, LEDs.Seq_Hue);

         when Seq =>
            LEDs.Set_Hue (Btn_Rest, LEDs.Seq_Hue);
            LEDs.Set_Hue (Btn_Tie, LEDs.Seq_Hue);
            LEDs.Set_Hue (Btn_Clear, LEDs.Seq_Hue);
            LEDS.Set_Hue (Btn_Meta_Mode, LEDs.Arp_Hue);

            if Buttons.Falling (Btn_Rest) then
               Generators (Current_Gen).Add_Rest;
            end if;

            if Buttons.Falling (Btn_Tie) then
               Generators (Current_Gen).Add_Tie;
            end if;

         when Arp =>
            LEDs.Set_Hue (Btn_Clear, LEDs.Arp_Hue);
            LEDS.Set_Hue (Btn_Meta_Mode, LEDs.Keyboard_Hue);

            --  ARP Mode LED
            case Generators (Current_Gen).Arp_Mode is
               when Arpeggiator.Up =>
                  LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Red);
               when Arpeggiator.Down =>
                  LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Green);
               when Arpeggiator.Up_N_Down =>
                  LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Blue);
               when Arpeggiator.Order =>
                  LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Violet);
            end case;

         end case;

         --  Change generator
         if Buttons.Falling (Gen_Btn (Current_Gen)) then

            Generators (Current_Gen).Toggle_Play;
         else
            Gen_Switch_Loop : for G in Gen_Id loop
               if Current_Gen /= G and Buttons.Falling (Gen_Btn (G)) then
                  Current_Gen := G;
                  exit Gen_Switch_loop;
               end if;
            end loop Gen_Switch_Loop;
         end if;

         Playing_After := (for some G of Generators => G.Playing);

         if Playing_Before and then not Playing_After then
            --  The last playing generator was stopped
            MIDI_Clock.Internal_Stop;

         elsif not Playing_Before and then Playing_After then
         --  At least one generator was started
            MIDI_Clock.Internal_Start;
         end if;
      end if;
   end Process_Keys;

end Pico_Keys.Gen_UI;
