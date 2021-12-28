with HAL; use HAL;

with Pico_Keys; use Pico_Keys;

with Pico_Keys.LEDs;
with Pico_Keys.Buttons;
with Pico_Keys.MIDI;
with Pico_Keys.MIDI.Serial;
with Pico_Keys.Arpeggiator;
with Pico_Keys.Sequencer;
with Pico_Keys.Keyboard;
with Pico_Keys.Generator;

with RP.Device;
with RP.Timer; use RP.Timer;

procedure Pico_Keys_Firmware is

   type Main_Mode_Kind is (Key, Arp, Seq);

   Main_Mode : Main_Mode_Kind := Key;

   Key_Gen : aliased Keyboard.Instance;
   Arp_Gen : aliased Arpeggiator.Instance;
   Seq_Gen : aliased Sequencer.Instance;

   Arp_Hue      : constant LEDS.Hue := LEDs.Blue;
   Beat_Hue     : constant LEDS.Hue := LEDs.Green;
   Seq_Hue      : constant LEDS.Hue := LEDs.Red;
   Keyboard_Hue : constant LEDS.Hue := LEDs.Violet;

   Generators : array (Main_Mode_Kind) of Pico_Keys.Generator.Any_Acc
     := (Key => Key_Gen'Unrestricted_Access,
         Arp => Arp_Gen'Unrestricted_Access,
         Seq => Seq_Gen'Unrestricted_Access);

   Gen_Hue : array (Main_Mode_Kind) of LEDs.Hue
     := (Key => Keyboard_Hue,
         Arp => Arp_Hue,
         Seq => Seq_Hue);

   Base_Note : MIDI.MIDI_Key := MIDI.C4;

   BPM : Natural := 120;
   Min_BPM : constant Natural := 50;
   Max_BPM : constant Natural := 250;

   Next_Trig : RP.Timer.Time := RP.Timer.Clock;

   Step : Step_Count := Step_Count'First;

   procedure Switch_To_Mode (M : Main_Mode_Kind) is
   begin
      if M /= Main_Mode then
         Generators (Main_Mode).Leave_Focus;
         Main_Mode := M;
         Generators (Main_Mode).Enter_Focus;
      end if;
   end Switch_To_Mode;
begin
   loop
      LEDs.Clear;
      Buttons.Scan;

      LEDs.Set_Hue (Btn_Func, Gen_Hue (Main_Mode),
                    Effect => (if Generators (Main_Mode).Playing
                               then LEDs.Blink_Fast
                               else LEDs.None));

      if Buttons.Pressed (Btn_Func) then

         if Buttons.Falling (Btn_Func) then
            Generators (Main_Mode).Enter_Func_Mode;
         end if;

         Generators (Main_Mode).No_Keys_Pressed;

         -- Beat LED
         if Generators (Main_Mode).Do_Trigger (Step) then
            LEDS.Set_Hue (Btn_Time_Div, Beat_Hue);
         end if;

         --  MIDI channel +/-
         if Buttons.Falling (Btn_Chan_Plus) then
            Generators (Main_Mode).Next_Channel;
         elsif Buttons.Falling (Btn_Chan_Minus) then
            Generators (Main_Mode).Prev_Channel;
         end if;

         --  Base note +/-
         if Buttons.Falling (Btn_Oct_Plus) and then Base_Note < 96 then
            Base_Note := Base_Note + 12;
         elsif Buttons.Falling (Btn_Oct_Minus) and then Base_Note > 24 then
            Base_Note := Base_Note - 12;
         end if;

         --  BPM +/-
         if Buttons.Falling (Btn_BPM_Plus) and then BPM < Max_BPM then
            BPM := BPM + 10;
         elsif Buttons.Falling (Btn_BPM_Minus) and then BPM > Min_BPM then
            BPM := BPM - 10;
         end if;

         --  ARP Mode select
         if Buttons.Falling (Btn_Arp_Mode) then
            Arp_Gen.Next_Mode;
         end if;

         --  Time Div select
         if Buttons.Falling (Btn_Time_Div) then
            Generators (Main_Mode).Next_Division;
         end if;

         if Buttons.Falling (Btn_Clear) then
            Generators (Main_Mode).Clear;
         end if;

         case Main_Mode is
         when Key =>

            LEDs.Set_Hue (Btn_Keyboard, Keyboard_Hue,
                          Effect => (if Key_Gen.Playing
                                     then LEDs.Blink_Fast
                                     else LEDs.None));

            if Buttons.Falling (Btn_Keyboard) then
               Key_Gen.Toggle_Play;
            elsif Buttons.Falling (Btn_Arp) then
               Switch_To_Mode (Arp);
            elsif Buttons.Falling (Btn_Seq) then
               Switch_To_Mode (Seq);
            end if;

         when Arp =>

            LEDs.Set_Hue (Btn_Arp, Arp_Hue,
                          Effect => (if Arp_Gen.Playing
                                     then LEDs.Blink_Fast
                                     else LEDs.None));

            LEDs.Set_Hue (Btn_Clear, Arp_Hue);

            --  ARP Mode LED
            case Arp_Gen.Mode is
            when Arpeggiator.Up =>
               LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Red);
            when Arpeggiator.Down =>
               LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Green);
            when Arpeggiator.Up_N_Down =>
               LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Blue);
            when Arpeggiator.Order =>
               LEDS.Set_Hue (Btn_Arp_Mode, LEDs.Violet);
            end case;

            if Buttons.Falling (Btn_Clear) then
               Arp_Gen.Clear;
            end if;

            if Buttons.Falling (Btn_Arp) then
               Arp_Gen.Toggle_Play;
            elsif Buttons.Falling (Btn_Seq) then
               Switch_To_Mode (Seq);
            elsif Buttons.Falling (Btn_Keyboard) then
               Switch_To_Mode (Key);
            end if;

         when Seq =>

            LEDs.Set_Hue (Btn_Seq, Seq_Hue,
                          Effect => (if Seq_Gen.Playing
                                     then LEDs.Blink_Fast
                                     else LEDs.None));

            LEDs.Set_Hue (Btn_Rest, Seq_Hue);
            LEDs.Set_Hue (Btn_Tie, Seq_Hue);
            LEDs.Set_Hue (Btn_Clear, Seq_Hue);

            if Buttons.Falling (Btn_Rest) then
               Seq_Gen.Add_Rest;
            end if;

            if Buttons.Falling (Btn_Tie) then
               Seq_Gen.Add_Tie;
            end if;

            if Buttons.Falling (Btn_Arp) then
               Switch_To_Mode (Arp);
            elsif Buttons.Falling (Btn_Seq) then
               Seq_Gen.Toggle_Play;
            elsif Buttons.Falling (Btn_Keyboard) then
               Switch_To_Mode (Key);
            end if;
         end case;

      else


         declare
            Btn_Count : Natural := 0;
         begin
            for Id in Note_Button_ID loop

               if Buttons.Pressed (Id) then
                  Btn_Count := Btn_Count + 1;
               end if;

               if Buttons.Falling (Id) then
                  Generators (Main_Mode).Falling (Base_Note + Id'Enum_Rep);

               elsif Buttons.Raising (Id) then
                  Generators (Main_Mode).Raising (Base_Note + Id'Enum_Rep);

               end if;
            end loop;

            if Btn_Count = 0 then
               Generators (Main_Mode).No_Keys_Pressed;
            end if;
         end;

         LEDs.Set_Hue (Btn_Func, Gen_Hue (Main_Mode));

         case Main_Mode is
         when Key =>
            for Id in Note_Button_ID loop
               if Buttons.Pressed (Id) then
                  LEDs.Set_Hue (Id, Keyboard_Hue);
               end if;
            end loop;

         when Arp =>
            for Id in Note_Button_ID loop
               if Arp_Gen.In_Arp (Base_Note + Id'Enum_Rep) then
                  LEDs.Set_Hue (Id, Arp_Hue);
               end if;
            end loop;

         when Seq =>
            null;
         end case;
      end if;

      if Clock >= Next_Trig then
         Next_Trig :=
           Next_Trig + Time ((Ticks_Per_Second * 60) / (BPM * Step_Count'Last));

         if (for some Gen of Generators => Gen.Playing) then
            MIDI.Send_Clock_Tick;
         end if;

         for Gen of Generators loop
            Gen.Trigger (Step);
         end loop;

         if Step = Step_Count'Last then
            Step := Step_Count'First;
         else
            Step := Step + 1;
         end if;
      end if;

      MIDI.Serial.Flush;
      LEDs.Update;

      RP.Device.Timer.Delay_Milliseconds (1);
   end loop;
end Pico_Keys_Firmware;
