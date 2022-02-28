with HAL; use HAL;
with VirtAPU; use VirtAPU;
with MIDI; use MIDI;
with Plugin_Interface; use Plugin_Interface;

package body APU_Synth is

   BITS_PER_SAMPLE        : constant := 10;
   SAMPLE_BITS_TO_DISCARD : constant := (16 - BITS_PER_SAMPLE);
   PWM_TOP                : constant := (2**BITS_PER_SAMPLE) - 1;

   APU : VirtAPU.Instance (3, 44_100);

   procedure Next_Samples
   is new VirtAPU.Next_Samples_UInt (UInt16, UInt16_Array);

   --------------------------
   -- MIDI_Key_To_APU_Freq --
   --------------------------

   function MIDI_Key_To_APU_Freq (Key : MIDI.MIDI_Key) return VirtAPU.Frequency is
   begin
      return (case Key is
                 when MIDI.A0  => VirtAPU.A0.Freq,
                 when MIDI.As0 => VirtAPU.As0.Freq,
                 when MIDI.B0  => VirtAPU.B4.Freq,

                 when MIDI.C1  => VirtAPU.C1.Freq,
                 when MIDI.Cs1 => VirtAPU.Cs1.Freq,
                 when MIDI.D1  => VirtAPU.D1.Freq,
                 when MIDI.Ds1 => VirtAPU.Ds1.Freq,
                 when MIDI.E1  => VirtAPU.E1.Freq,
                 when MIDI.F1  => VirtAPU.F1.Freq,
                 when MIDI.Fs1 => VirtAPU.Fs1.Freq,
                 when MIDI.G1  => VirtAPU.G1.Freq,
                 when MIDI.Gs1 => VirtAPU.Gs1.Freq,
                 when MIDI.A1  => VirtAPU.A1.Freq,
                 when MIDI.As1 => VirtAPU.As1.Freq,
                 when MIDI.B1  => VirtAPU.B1.Freq,

                 when MIDI.C2  => VirtAPU.C2.Freq,
                 when MIDI.Cs2 => VirtAPU.Cs2.Freq,
                 when MIDI.D2  => VirtAPU.D2.Freq,
                 when MIDI.Ds2 => VirtAPU.Ds2.Freq,
                 when MIDI.E2  => VirtAPU.E2.Freq,
                 when MIDI.F2  => VirtAPU.F2.Freq,
                 when MIDI.Fs2 => VirtAPU.Fs2.Freq,
                 when MIDI.G2  => VirtAPU.G2.Freq,
                 when MIDI.Gs2 => VirtAPU.Gs2.Freq,
                 when MIDI.A2  => VirtAPU.A2.Freq,
                 when MIDI.As2 => VirtAPU.As2.Freq,
                 when MIDI.B2  => VirtAPU.B2.Freq,

                 when MIDI.C3  => VirtAPU.C3.Freq,
                 when MIDI.Cs3 => VirtAPU.Cs3.Freq,
                 when MIDI.D3  => VirtAPU.D3.Freq,
                 when MIDI.Ds3 => VirtAPU.Ds3.Freq,
                 when MIDI.E3  => VirtAPU.E3.Freq,
                 when MIDI.F3  => VirtAPU.F3.Freq,
                 when MIDI.Fs3 => VirtAPU.Fs3.Freq,
                 when MIDI.G3  => VirtAPU.G3.Freq,
                 when MIDI.Gs3 => VirtAPU.Gs3.Freq,
                 when MIDI.A3  => VirtAPU.A3.Freq,
                 when MIDI.As3 => VirtAPU.As3.Freq,
                 when MIDI.B3  => VirtAPU.B3.Freq,

                 when MIDI.C4  => VirtAPU.C4.Freq,
                 when MIDI.Cs4 => VirtAPU.Cs4.Freq,
                 when MIDI.D4  => VirtAPU.D4.Freq,
                 when MIDI.Ds4 => VirtAPU.Ds4.Freq,
                 when MIDI.E4  => VirtAPU.E4.Freq,
                 when MIDI.F4  => VirtAPU.F4.Freq,
                 when MIDI.Fs4 => VirtAPU.Fs4.Freq,
                 when MIDI.G4  => VirtAPU.G4.Freq,
                 when MIDI.Gs4 => VirtAPU.Gs4.Freq,
                 when MIDI.A4  => VirtAPU.A4.Freq,
                 when MIDI.As4 => VirtAPU.As4.Freq,
                 when MIDI.B4  => VirtAPU.B4.Freq,

                 when MIDI.C5  => VirtAPU.C5.Freq,
                 when MIDI.Cs5 => VirtAPU.Cs5.Freq,
                 when MIDI.D5  => VirtAPU.D5.Freq,
                 when MIDI.Ds5 => VirtAPU.Ds5.Freq,
                 when MIDI.E5  => VirtAPU.E5.Freq,
                 when MIDI.F5  => VirtAPU.F5.Freq,
                 when MIDI.Fs5 => VirtAPU.Fs5.Freq,
                 when MIDI.G5  => VirtAPU.G5.Freq,
                 when MIDI.Gs5 => VirtAPU.Gs5.Freq,
                 when MIDI.A5  => VirtAPU.A5.Freq,
                 when MIDI.As5 => VirtAPU.As5.Freq,
                 when MIDI.B5  => VirtAPU.B5.Freq,

                 when MIDI.C6  => VirtAPU.C6.Freq,
                 when MIDI.Cs6 => VirtAPU.Cs6.Freq,
                 when MIDI.D6  => VirtAPU.D6.Freq,
                 when MIDI.Ds6 => VirtAPU.Ds6.Freq,
                 when MIDI.E6  => VirtAPU.E6.Freq,
                 when MIDI.F6  => VirtAPU.F6.Freq,
                 when MIDI.Fs6 => VirtAPU.Fs6.Freq,
                 when MIDI.G6  => VirtAPU.G6.Freq,
                 when MIDI.Gs6 => VirtAPU.Gs6.Freq,
                 when MIDI.A6  => VirtAPU.A6.Freq,
                 when MIDI.As6 => VirtAPU.As6.Freq,
                 when MIDI.B6  => VirtAPU.B6.Freq,

                 when MIDI.C7  => VirtAPU.C7.Freq,
                 when MIDI.Cs7 => VirtAPU.Cs7.Freq,
                 when MIDI.D7  => VirtAPU.D7.Freq,
                 when MIDI.Ds7 => VirtAPU.Ds7.Freq,
                 when MIDI.E7  => VirtAPU.E7.Freq,
                 when MIDI.F7  => VirtAPU.F7.Freq,
                 when MIDI.Fs7 => VirtAPU.Fs7.Freq,
                 when MIDI.G7  => VirtAPU.G7.Freq,
                 when MIDI.Gs7 => VirtAPU.Gs7.Freq,
                 when MIDI.A7  => VirtAPU.A7.Freq,
                 when MIDI.As7 => VirtAPU.As7.Freq,
                 when MIDI.B7  => VirtAPU.B7.Freq,

                 when MIDI.C8  => VirtAPU.C8.Freq,
                 when MIDI.Cs8 => VirtAPU.Cs8.Freq,
                 when MIDI.D8  => VirtAPU.D8.Freq,
                 when MIDI.Ds8 => VirtAPU.Ds8.Freq,
                 when MIDI.E8  => VirtAPU.E8.Freq,
                 when MIDI.F8  => VirtAPU.F8.Freq,
                 when MIDI.Fs8 => VirtAPU.Fs8.Freq,
                 when MIDI.G8  => VirtAPU.G8.Freq,
                 when MIDI.Gs8 => VirtAPU.Gs8.Freq,
                 when MIDI.A8  => VirtAPU.A8.Freq,
                 when MIDI.As8 => VirtAPU.As8.Freq,
                 when MIDI.B8  => VirtAPU.B8.Freq,

                 when others => 0.0);
   end MIDI_Key_To_APU_Freq;

   procedure Handle (D : Plugin_Interface.Data) is
      Last_Chan : constant MIDI.MIDI_Channel :=
        MIDI_Channel (APU.Number_Of_Channels) - 1;
   begin
      case D.Kind is
         when MIDI_Msg =>
            case D.Msg.Kind is
               when MIDI.Note_On =>
                  if D.Msg.Chan <= Last_Chan then
                     APU.Note_On
                       (Channel_ID (D.Msg.Chan + 1),
                        MIDI_Key_To_APU_Freq (D.Msg.Key));

                  end if;
               when MIDI.Note_Off =>
                  if D.Msg.Chan <= Last_Chan then
                     APU.Note_Off (Channel_ID (D.Msg.Chan + 1));
                  end if;
                           when others =>
                  null;
            end case;

         when In_Buffer =>

            APU.Tick;
            declare
               Buffer : UInt16_Array (1 .. 2**Natural(D.Size))
                 with Address => Address (D.Offset);
            begin
               Next_Samples (APU, Buffer);

               for Elt of Buffer loop
                  Elt := Shift_Right (Elt, SAMPLE_BITS_TO_DISCARD);
               end loop;
            end;

            Push ((Kind => Out_Buffer,
                   Size => D.Size,
                   Offset => D.Offset));

         when others =>
            null;
      end case;
   end Handle;

begin

   --  for X in 1 .. APU.Number_Of_Channels loop
   --     APU.Set_Mode (X, VirtAPU.Pulse);
   --     APU.Set_Width (X, VirtAPU.Pulse_Width (20 + X));
   --     APU.Set_Volume (X, 50);
   --     APU.Set_Decay (X, 0);
   --     --  APU.Note_On (X, 440.0 + Frequency (X));
   --  end loop;

   APU.Set_Mode (1, VirtAPU.Pulse);
   APU.Set_Width (1, 75);
   APU.Set_Volume (1, 50);
   APU.Set_Decay (1, 5);

   APU.Set_Mode (2, VirtAPU.Pulse);
   APU.Set_Width (2, 20);
   APU.Set_Volume (2, 50);
   APU.Set_Decay (2, 7);

   APU.Set_Mode (3, VirtAPU.Triangle);
   APU.Set_Width (3, 75);
   APU.Set_Volume (3, 50);
   APU.Set_Decay (3, 10);

end APU_Synth;
