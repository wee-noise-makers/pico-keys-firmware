with HAL; use HAL;

with Pico_Keys; use Pico_Keys;

with Pico_Keys.LEDs;
with Pico_Keys.Buttons;
with Pico_Keys.MIDI;
with Pico_Keys.MIDI.Serial;
with Pico_Keys.Meta_Gen; use Pico_Keys.Meta_Gen;
with Pico_Keys.Arpeggiator;
with Pico_Keys.Sequencer;
with Pico_Keys.Synth_UI;
with Pico_Keys.Synth_Plugin;
with Pico_Keys.Save; use Pico_Keys.Save;

with RP.Timer; use RP.Timer;

procedure Pico_Keys_Firmware is

   Current_Gen : Gen_Id := Gen_Id'First;

   Gen_Btn : constant array (Gen_Id) of Pico_Keys.Button_ID
     := (1 => Btn_G1,
         2 => Btn_G2,
         3 => Btn_G3);

   Arp_Hue      : constant LEDs.Hue := LEDs.Cyan;
   Beat_Hue     : constant LEDs.Hue := LEDs.Green;
   Triplet_Hue  : constant LEDs.Hue := LEDs.Orange;
   Seq_Hue      : constant LEDs.Hue := LEDs.Red;
   Keyboard_Hue : constant LEDs.Hue := LEDs.Violet;

   Gen_Hue : constant array (Pico_Keys.Meta_Gen.Meta_Mode_Kind) of LEDs.Hue
     := (Key => Keyboard_Hue,
         Arp => Arp_Hue,
         Seq => Seq_Hue);

   Base_Note : MIDI.MIDI_Key := MIDI.C6;

   Min_BPM : constant Natural := 50;
   Max_BPM : constant Natural := 250;

   Next_Clock_Trig : RP.Timer.Time := RP.Timer.Clock;
   Next_UI_Trig : RP.Timer.Time := RP.Timer.Clock;

   Step : Step_Count := Step_Count'First;

   Now : RP.Timer.Time;

   Generators : Pico_Keys.Save.Gen_Array renames RAM_State.Generators;
   BPM        : Natural                  renames RAM_State.BPM;

   Playing_Before, Playing_After : Boolean;

   Save_Btn_Long_Press_Deadline : RP.Timer.Time;
   Save_Btn_Dbl_Press_Deadline : RP.Timer.Time;
   Save_Blink_Until : RP.Timer.Time;
   Save_Blink_Hue   : LEDs.Hue;
   Save_Blink_Duration : constant RP.Timer.Time := Ticks_Per_Second / 2;

begin

   Pico_Keys.Synth_Plugin.Start;
   Pico_Keys.Synth_UI.Update_All_Parameters;

   --  Set Gen 2 to seq
   Generators (2).Next_Meta;

   --  Set Gen 3 to arp
   Generators (3).Next_Meta;
   Generators (3).Next_Meta;

   --  Load a previous save, if there's one in flash
   Pico_Keys.Save.Load_From_Flash;

   Pico_Keys.Synth_UI.Update_All_Parameters;

   loop
      Now := Clock;

      if Now >= Next_Clock_Trig then
         Next_Clock_Trig :=
           Next_Clock_Trig + Time ((Ticks_Per_Second * 60) / (BPM * 24));

         for G of Generators loop
            G.Signal_Step (BPM, Step, Now);
         end loop;

         Step := Step + 1;
         if (for some Gen of Generators => Gen.Playing) then
            MIDI.Send_Clock_Tick;
         end if;
      end if;

      for G in Gen_Id loop
         Generators (G).Check_Trigger (Now);
      end loop;

      MIDI.Serial.Flush;

      if Next_UI_Trig <= Now then
         LEDs.Clear;
         Buttons.Scan;

         LEDs.Set_Hue (Btn_Func, Gen_Hue (Generators (Current_Gen).Current_Mode),
                       Effect => (if Generators (Current_Gen).Playing
                                  then LEDs.Blink_Fast
                                  else LEDs.None));

         if Buttons.Pressed (Btn_Synth) then

            Pico_Keys.Synth_UI.Process_Keys (Now,
                                             (case Current_Gen is
                                                 when 1 => 0,
                                                 when 2 => 1,
                                                 when 3 => 2));

         elsif Buttons.Pressed (Btn_Func) then

            Playing_Before := (for some G of Generators => G.Playing);

            if Buttons.Falling (Btn_Func) then
               Generators (Current_Gen).Enter_Func_Mode;

               --  When entering func mode, reset the double press / long press
               --  system.
               Save_Btn_Long_Press_Deadline := RP.Timer.Time'Last;
               Save_Btn_Dbl_Press_Deadline := RP.Timer.Time'First;
               Save_Blink_Until := RP.Timer.Time'First;
            end if;

            Generators (Current_Gen).No_Keys_Pressed;

            --  Time Div LED
            if On_Time (Generators (Current_Gen).Division, Step) then
               if Generators (Current_Gen).Division in Div_4 .. Div_32 then
                  LEDS.Set_Hue (Btn_Time_Div, Beat_Hue, LEDs.Fade);
               else
                  LEDS.Set_Hue (Btn_Time_Div, Triplet_Hue, LEDs.Fade);
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
               LEDS.Set_Hue (Btn_Time_Swing, Beat_Hue);
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
            if Buttons.Falling (Btn_BPM_Plus) and then BPM < Max_BPM then
               BPM := BPM + 5;
            elsif Buttons.Falling (Btn_BPM_Minus) and then BPM > Min_BPM then
               BPM := BPM - 5;
            end if;

            if Pico_Keys.On_Time (Pico_Keys.Div_4, Step) then
               LEDS.Set_Hue (Btn_BPM_Plus, Beat_Hue, LEDs.Fade);
               LEDS.Set_Hue (Btn_BPM_Minus, Beat_Hue, LEDs.Fade);
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
            if Buttons.Falling (Btn_Save) then
               Save_Btn_Long_Press_Deadline := Now + (Ticks_Per_Second * 1);
            elsif Buttons.Pressed (Btn_Save) then

               --  If the button is pressed since more than a second
               if Now >= Save_Btn_Long_Press_Deadline then
                  Save.Save_To_Flash;

                  Save_Blink_Hue := LEDs.Red; --  Red means recording ^^
                  Save_Blink_Until := Now + Save_Blink_Duration;

                  Save_Btn_Long_Press_Deadline := RP.Timer.Time'Last;
               end if;

            elsif Buttons.Rising (Btn_Save) then

               --  If the button was released less than a second ago (double
               --  press/release).
               if Now <= Save_Btn_Dbl_Press_Deadline then
                  Save.Load_From_Flash;

                  Save_Blink_Hue := LEDs.Green; --  Green means loading...
                  Save_Blink_Until := Now + Save_Blink_Duration;

                  Save_Btn_Dbl_Press_Deadline := RP.Timer.Time'First;
               else
                  Save_Btn_Dbl_Press_Deadline := Now + (Ticks_Per_Second / 2);
               end if;
            end if;

            if Now <= Save_Blink_Until then
               LEDS.Set_Hue (Btn_Save, Save_Blink_Hue, LEDs.Blink_Fast);
            end if;

            --  Clear
            if Buttons.Falling (Btn_Clear) then
               Generators (Current_Gen).Clear;
            end if;

            LEDs.Set_Hue (Gen_Btn (Current_Gen),
                          Gen_Hue (Generators (Current_Gen).Current_Mode),
                          Effect => (if Generators (Current_Gen).Playing
                                     then LEDs.Blink_Fast
                                     else LEDs.None));

            case Generators (Current_Gen).Current_Mode is
            when Key =>

               LEDS.Set_Hue (Btn_Meta_Mode, Seq_Hue);

            when Seq =>
               LEDs.Set_Hue (Btn_Rest, Seq_Hue);
               LEDs.Set_Hue (Btn_Tie, Seq_Hue);
               LEDs.Set_Hue (Btn_Clear, Seq_Hue);
               LEDS.Set_Hue (Btn_Meta_Mode, Arp_Hue);

               if Buttons.Falling (Btn_Rest) then
                  Generators (Current_Gen).Add_Rest;
               end if;

               if Buttons.Falling (Btn_Tie) then
                  Generators (Current_Gen).Add_Tie;
               end if;

            when Arp =>
               LEDs.Set_Hue (Btn_Clear, Arp_Hue);
               LEDS.Set_Hue (Btn_Meta_Mode, Keyboard_Hue);

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
               MIDI.Send_Stop;

            elsif not Playing_Before and then Playing_After then
               --  At least one generator was started
               MIDI.Send_Start;
               Step := Step_Count'First;
            end if;

         else

            declare
               Btn_Count : Natural := 0;
            begin
               for Id in Note_Button_ID loop

                  if Buttons.Pressed (Id) then
                     Btn_Count := Btn_Count + 1;
                  end if;

                  if Buttons.Falling (Id) then
                     Generators (Current_Gen).Falling (Base_Note + Id'Enum_Rep);

                  elsif Buttons.Rising (Id) then
                     Generators (Current_Gen).Rising (Base_Note + Id'Enum_Rep);

                  end if;
               end loop;

               if Btn_Count = 0 then
                  Generators (Current_Gen).No_Keys_Pressed;
               end if;
            end;

            case Generators (Current_Gen).Current_Mode is
            when Key =>
               for Id in Note_Button_ID loop
                  if Buttons.Pressed (Id) then
                     LEDs.Set_Hue (Id, Keyboard_Hue, LEDs.Fade);
                  end if;
               end loop;

            when Arp =>
               for Id in Note_Button_ID loop
                  if Generators (Current_Gen).In_Arp (Base_Note + Id'Enum_Rep)
                  then
                     LEDs.Set_Hue (Id, Arp_Hue);
                  end if;
               end loop;

            when Seq =>
               declare
                  Keys : constant Sequencer.Note_Array :=
                    Generators (Current_Gen).In_Seq;
               begin
                  for Id in Note_Button_ID loop
                     for K of Keys loop
                        if K = Base_Note + Id'Enum_Rep then
                           LEDs.Set_Hue (Id, Seq_Hue);
                        end if;
                     end loop;
                  end loop;
               end;

            end case;
         end if;

         LEDs.Update;

         Next_UI_Trig := Next_UI_Trig + Time (Ticks_Per_Second / 120);
      end if;
   end loop;
end Pico_Keys_Firmware;
