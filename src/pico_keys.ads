with System;

with RP.DMA;
with RP.Clock;
with RP.Timer;

package Pico_Keys is
   pragma Elaborate_Body;

   type Step_Count is mod 48;

   type Time_Div is (Div_4, Div_8, Div_16, Div_32,
                     Div_4T, Div_8T, Div_16T, Div_32T);

   function On_Time (Div : Time_Div; Step : Step_Count) return Boolean
   is ((case DiV is
          when Div_4   => (Step mod 24) = 0,
          when Div_8   => (Step mod 12) = 0,
          when Div_16  => (Step mod  6) = 0,
          when Div_32  => (Step mod  3) = 0,
          when Div_4T  => (Step mod 16) = 0,
          when Div_8T  => (Step mod  8) = 0,
          when Div_16T => (Step mod  4) = 0,
          when Div_32T => (Step mod  2) = 0));

   type Time_Swing is (Swing_Off, Swing_55, Swing_60,
                       Swing_65, Swing_70, Swing_75);

   type Gen_Id is range 1 .. 3;

   type Button_ID is (Btn_C,
                      Btn_Cs,
                      Btn_D,
                      Btn_Ds,
                      Btn_E,
                      Btn_F,
                      Btn_Fs,
                      Btn_G,
                      Btn_Gs,
                      Btn_A,
                      Btn_As,
                      Btn_B,
                      Btn_C2,
                      Btn_C2s,
                      Btn_D2,
                      Btn_D2s,
                      Btn_E2,
                      Btn_Func
                     );

   subtype Note_Button_ID is Button_ID range Btn_C .. Btn_E2;

   Btn_Oct_Minus : constant Button_ID := Btn_Cs;
   Btn_Oct_Plus  : constant Button_ID := Btn_Ds;
   Btn_Chan_Minus : constant Button_ID := Btn_C2s;
   Btn_Chan_Plus  : constant Button_ID := Btn_D2s;
   Btn_BPM_Minus : constant Button_ID := Btn_D2;
   Btn_BPM_Plus  : constant Button_ID := Btn_E2;

   Btn_G1 : constant Button_ID := Btn_Fs;
   Btn_G2 : constant Button_ID := Btn_Gs;
   Btn_G3 : constant Button_ID := Btn_As;

   Btn_Arp_Mode   : constant Button_ID := Btn_C;
   Btn_Clear      : constant Button_ID := Btn_D;
   Btn_Rest       : constant Button_ID := Btn_E;
   Btn_Tie        : constant Button_ID := Btn_F;
   Btn_Time_Div   : constant Button_ID := Btn_G;
   Btn_Time_Swing : constant Button_ID := Btn_A;
   Btn_Meta_Mode  : constant Button_ID := Btn_B;

   LED_PIO_DMA : constant RP.DMA.DMA_Channel_Id := 1;
   UART_TX_DMA : constant RP.DMA.DMA_Channel_Id := 2;

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer);
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");

   XOSC_Frequency : RP.Clock.XOSC_Hertz := 12_000_000;

end Pico_Keys;
