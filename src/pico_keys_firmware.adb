with HAL; use HAL;

with MIDI;

with Pico_Keys; use Pico_Keys;

with Pico_Keys.LEDs;
with Pico_Keys.Buttons;
with Pico_Keys.MIDI;
with Pico_Keys.MIDI.Serial;
with Pico_Keys.Meta_Gen; use Pico_Keys.Meta_Gen;
with Pico_Keys.Sequencer;
with Pico_Keys.MIDI_Clock;
with Pico_Keys.Gen_UI;
with Pico_Keys.Synth_UI;
with Pico_Keys.Synth_Plugin;
with Pico_Keys.Save; use Pico_Keys.Save;

with Pico_Keys.Last_Chance;
pragma Unreferenced (Pico_Keys.Last_Chance);

with RP.Timer; use RP.Timer;

procedure Pico_Keys_Firmware is

   Current_Gen : Gen_Id := Gen_Id'First;

   Next_UI_Trig : RP.Timer.Time := RP.Timer.Clock;
   Now : RP.Timer.Time;

   Generators : Pico_Keys.Save.Gen_Array renames RAM_State.Generators;
   Base_Note  : MIDI.MIDI_Key            renames RAM_State.Base_Note;

begin

   Pico_Keys.Synth_Plugin.Start;
   Pico_Keys.Synth_UI.Update_All_Parameters;

   --  Set Gen 2 to seq and MIDI chan 1
   Generators (2).Next_Meta;
   Generators (2).Next_Channel;

   --  Set Gen 3 to arp and MIDI chan 2
   Generators (3).Next_Meta;
   Generators (3).Next_Meta;
   Generators (3).Next_Channel;
   Generators (3).Next_Channel;

   --  Load a previous save, if there's one in flash
   Pico_Keys.Save.Load_First_Valid;

   Pico_Keys.Synth_UI.Update_All_Parameters;

   loop
      Now := Clock;

      Pico_Keys.MIDI.Process_Input;

      MIDI_Clock.Update (Now);

      for G in Gen_Id loop
         Generators (G).Check_Trigger (Now);
      end loop;

      Pico_Keys.MIDI.Serial.Flush;

      if Next_UI_Trig <= Now then
         LEDs.Clear;
         Buttons.Scan (Now);

         LEDs.Set_Hue (Btn_Func,
                       LEDs.Gen_Hue (Generators (Current_Gen).Current_Mode),
                       Effect => (if Generators (Current_Gen).Playing
                                  then LEDs.Blink_Fast
                                  else LEDs.None));

         if Buttons.Pressed (Btn_Func) then

            Pico_Keys.Gen_UI.Process_Keys (Now, Current_Gen);

         elsif Buttons.Pressed (Btn_Synth) then

            Pico_Keys.Synth_UI.Process_Keys (Now,
                                             (case Current_Gen is
                                                 when 1 => 0,
                                                 when 2 => 1,
                                                 when 3 => 2));
         else

            --  Key events for the current generator
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

            --  LEDs for the current generator
            case Generators (Current_Gen).Current_Mode is
            when Key =>
               for Id in Note_Button_ID loop
                  if Buttons.Pressed (Id) then
                     LEDs.Set_Hue (Id, LEDs.Keyboard_Hue, LEDs.Fade);
                  end if;
               end loop;

            when Arp =>
               for Id in Note_Button_ID loop
                  if Generators (Current_Gen).In_Arp (Base_Note + Id'Enum_Rep)
                  then
                     LEDs.Set_Hue (Id, LEDs.Arp_Hue);
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
                           LEDs.Set_Hue (Id, LEDs.Seq_Hue);
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
