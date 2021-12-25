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

   Generators : array (Main_Mode_Kind) of Pico_Keys.Generator.Any_Acc
     := (Key => Key_Gen'Unrestricted_Access,
         Arp => Arp_Gen'Unrestricted_Access,
         Seq => Seq_Gen'Unrestricted_Access);

   Base_Note : MIDI.MIDI_Key := MIDI.C4;

   BPM : Natural := 120;
   Min_BPM : constant Natural := 50;
   Max_BPM : constant Natural := 250;

   Beat : Natural := 4;

   Next_Trig : RP.Timer.Time := RP.Timer.Clock;

   Arp_Hue : constant LEDS.Hue := LEDs.Blue;
   Beat_Hue : constant LEDS.Hue := LEDs.Green;

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

      if Buttons.Pressed (Btn_Func) then

         if Buttons.Falling (Btn_Func) then
            Generators (Main_Mode).Enter_Func_Mode;
         end if;

         LEDs.Set_Hue (Btn_Func, LEDs.Blue);

         LEDs.Set_Hue (Btn_Arp, Arp_Hue,
                       Effect => (if Main_Mode = Arp
                                  then LEDs.Blink_Fast
                                  else LEDs.Dim));

         LEDs.Set_Hue (Btn_Rec, LEDs.Red,
                       Effect => (if Main_Mode = Seq
                                  then LEDs.Blink_Fast
                                  else LEDs.Dim));

         --  ARP Mode LED
         case Arp_Gen.Mode is
            when Arpeggiator.Up =>
               LEDS.Set_Hue (Btn_Arp_Up, Arp_Hue);
            when Arpeggiator.Down =>
               LEDS.Set_Hue (Btn_Arp_Down, Arp_Hue);
            when Arpeggiator.Up_N_Down =>
               LEDS.Set_Hue (Btn_Arp_Up_N_Down, Arp_Hue);
            when Arpeggiator.Order =>
               LEDS.Set_Hue (Btn_Arp_Order, Arp_Hue);
         end case;

         -- Beat LED
         case Beat is
            when 4 =>
               LEDS.Set_Hue (Btn_Beat_4th, Beat_Hue);
            when 8 =>
               LEDS.Set_Hue (Btn_Beat_8th, Beat_Hue);
            when 16 =>
               LEDS.Set_Hue (Btn_Beat_16th, Beat_Hue);
            when others =>
               LEDS.Set_Hue (Btn_Beat_32nd, Beat_Hue);
         end case;

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
         if Buttons.Falling (Btn_Arp_Up) then
            Arp_Gen.Set_Mode (Arpeggiator.Up);
         elsif Buttons.Falling (Btn_Arp_Down) then
            Arp_Gen.Set_Mode (Arpeggiator.Down);
         elsif Buttons.Falling (Btn_Arp_Up_N_Down) then
            Arp_Gen.Set_Mode (Arpeggiator.Up_N_Down);
         elsif Buttons.Falling (Btn_Arp_Order) then
            Arp_Gen.Set_Mode (Arpeggiator.Order);
         end if;

         --  Beat select
         if Buttons.Falling (Btn_Beat_4th) then
            Generators (Main_Mode).Set_Division (Div_4);
            Beat := 4;
         elsif Buttons.Falling (Btn_Beat_8th) then
            Generators (Main_Mode).Set_Division (Div_8);
            Beat := 8;
         elsif Buttons.Falling (Btn_Beat_16th) then
            Generators (Main_Mode).Set_Division (Div_16);
            Beat := 16;
         elsif Buttons.Falling (Btn_Beat_32nd) then
            Generators (Main_Mode).Set_Division (Div_32);
            Beat := 32;
         end if;

         Generators (Main_Mode).No_Keys_Pressed;

         if Buttons.Falling (Btn_Play) then
            Generators (Main_Mode).Toggle_play;
         end if;

         if Generators (Main_Mode).Playing
           and then
             Generators (Main_Mode).Do_Trigger (Step)
         then
            LEDs.Set_Hue (Btn_Play, LEDs.Green);
         end if;

         case Main_Mode is
         when Key =>

            if Buttons.Falling (Btn_Arp) then
               Switch_To_Mode (Arp);
            elsif Buttons.Falling (Btn_Rec) then
               Switch_To_Mode (Seq);
            end if;

         when Arp =>

            if Buttons.Falling (Btn_Arp) then
               Switch_To_Mode (Key);
            elsif Buttons.Falling (Btn_Rec) then
               Switch_To_Mode (Seq);
            end if;

         when Seq =>

            if Buttons.Falling (Btn_Arp) then
               Switch_To_Mode (Arp);
            elsif Buttons.Falling (Btn_Rec) then
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

         case Main_Mode is
         when Key =>
            for Id in Note_Button_ID loop
               if Buttons.Pressed (Id) then
                  LEDs.Set_Hue (Id, LEDs.Violet);
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
