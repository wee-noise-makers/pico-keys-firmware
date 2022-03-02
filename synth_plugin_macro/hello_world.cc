// Copyright 2012 Emilie Gillet.
//
// Author: Emilie Gillet (emilie.o.gillet@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION ObF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// See http://creativecommons.org/licenses/MIT/ for more information.

//#include <stm32f10x_conf.h>

#include <algorithm>

#include "dsp.h"
//#include "stmlib/utils/ring_buffer.h"
//#include "stmlib/system/system_clock.h"
//#include "stmlib/system/uid.h"

//#include "braids/drivers/adc.h"
//#include "braids/drivers/dac.h"
//#include "braids/drivers/debug_pin.h"
//#include "braids/drivers/gate_input.h"
//#include "braids/drivers/internal_adc.h"
//#include "braids/drivers/system.h"
#include "envelope.h"
#include "macro_oscillator.h"
//#include "quantizer.h"
#include "signature_waveshaper.h"
#include "vco_jitter_source.h"
//#include "ui.h"

//#include "quantizer_scales.h"

#include "plugin_interface.h"

// #define PROFILE_RENDER 1

using namespace braids;
using namespace std;
using namespace stmlib;


const size_t kBlockSize = MAX_RENDER_BUFFER_SIZE;

MacroOscillator osc[NBR_OF_OSCs];
Envelope envelope[NBR_OF_OSCs];
SignatureWaveshaper ws[NBR_OF_OSCs];
int32_t midi_pitch[NBR_OF_OSCs] = {48 << 7};

#define MAX_MIDI_VAL (15)
#define MAX_PARAM (32767)
int32_t cc_params[NBR_OF_OSCs][2] = {{MAX_PARAM / 2}};

// Adc adc;
// Dac dac;
// DebugPin debug_pin;
// GateInput gate_input;
// InternalAdc internal_adc;
//Quantizer quantizer;
// System sys;
// VcoJitterSource jitter_source;
// Ui ui;

// uint8_t current_scale = 0xff;
// size_t current_sample;
int16_t audio_samples[NBR_OF_OSCs][kBlockSize];
uint8_t sync_samples[NBR_OF_OSCs][kBlockSize];

// bool trigger_detected_flag;
volatile bool trigger_flag[NBR_OF_OSCs];
// uint16_t trigger_delay;

extern "C" {

void HardFault_Handler(void) { while (1); }
void MemManage_Handler(void) { while (1); }
void BusFault_Handler(void) { while (1); }
void UsageFault_Handler(void) { while (1); }
void NMI_Handler(void) { }
void SVC_Handler(void) { }
void DebugMon_Handler(void) { }
void PendSV_Handler(void) { }

}

//  Hack to remove a bunch (~500 bytes) of C++ at exit data in .bss
extern "C"{
    int __aeabi_atexit(void *object, void (*destructor)(void *), void *dso_handle) {
        return 0;
    }

    void __cxa_atexit() {
    }

    void __register_exitproc() {
    }}

// extern "C" {

// void SysTick_Handler() {
//   ui.Poll();
// }

// void TIM1_UP_IRQHandler(void) {
//   if (!(TIM1->SR & TIM_IT_Update)) {
//     return;
//   }
//   TIM1->SR = (uint16_t)~TIM_IT_Update;

//   dac.Write(-audio_samples[playback_block][current_sample] + 32768);

//   bool trigger_detected = gate_input.raised();
//   sync_samples[playback_block][current_sample] = trigger_detected;
//   trigger_detected_flag = trigger_detected_flag | trigger_detected;

//   current_sample = current_sample + 1;
//   if (current_sample >= kBlockSize) {
//     current_sample = 0;
//     playback_block = (playback_block + 1) % kNumBlocks;
//   }

//   bool adc_scan_cycle_complete = adc.PipelinedScan();
//   if (adc_scan_cycle_complete) {
//     ui.UpdateCv(adc.channel(0), adc.channel(1), adc.channel(2), adc.channel(3));
//     if (trigger_detected_flag) {
//       trigger_delay = settings.trig_delay()
//           ? (1 << settings.trig_delay()) : 0;
//       ++trigger_delay;
//       trigger_detected_flag = false;
//     }
//     if (trigger_delay) {
//       --trigger_delay;
//       if (trigger_delay == 0) {
//         trigger_flag = true;
//       }
//     }
//   }
// }

// }

void Init() {
  // sys.Init(F_CPU / 96000 - 1, true);
  // ui.Init();
//   system_clock.Init();
//   adc.Init(false);
//   gate_input.Init();
// #ifdef PROFILE_RENDER
//   debug_pin.Init();
// #endif
//   dac.Init();
  for (int i = 0; i < NBR_OF_OSCs; i++){
      settings[i].Init();
      osc[i].Init();
      envelope[i].Init();
      ws[i].Init(42000 * (i + 1));
  }
  //quantizer.Init();
  // internal_adc.Init();

  for (size_t i = 0; i < NBR_OF_OSCs; ++i) {
    fill(&audio_samples[i][0], &audio_samples[i][kBlockSize], 0);
    fill(&sync_samples[i][0], &sync_samples[i][kBlockSize], 0);
  }
  // current_sample = 0;

  // jitter_source.Init();
  // sys.StartTimers();
}

const uint16_t bit_reduction_masks[] = {
    0xc000,
    0xe000,
    0xf000,
    0xf800,
    0xff00,
    0xfff0,
    0xffff };

const uint16_t decimation_factors[] = { 24, 12, 6, 4, 3, 2, 1 };

void RenderBlock(int osc_id) {
  static int16_t previous_pitch[NBR_OF_OSCs] = {0};
  // static int16_t previous_shape[NBR_OF_OSCs] = 0;
  static uint16_t gain_lp[NBR_OF_OSCs];

#ifdef PROFILE_RENDER
  debug_pin.High();
#endif
  envelope[osc_id].Update(
      settings[osc_id].GetValue(SETTING_AD_ATTACK) * 8,
      settings[osc_id].GetValue(SETTING_AD_DECAY) * 8);
  uint32_t ad_value = envelope[osc_id].Render();

  // if (false){//ui.paques()) {
  //   osc[osc_id].set_shape(MACRO_OSC_SHAPE_QUESTION_MARK);
  // } else if (settings[osc_id].meta_modulation()) {
  //   int16_t shape = 0;//adc.channel(3);
  //   shape -= settings[osc_id].data().fm_cv_offset;
  //   if (shape > previous_shape + 2 || shape < previous_shape - 2) {
  //     previous_shape = shape;
  //   } else {
  //     shape = previous_shape;
  //   }
  //   shape = MACRO_OSC_SHAPE_LAST * shape >> 11;
  //   shape += settings[osc_id].shape();
  //   if (shape >= MACRO_OSC_SHAPE_LAST_ACCESSIBLE_FROM_META) {
  //     shape = MACRO_OSC_SHAPE_LAST_ACCESSIBLE_FROM_META;
  //   } else if (shape <= 0) {
  //     shape = 0;
  //   }
  //   MacroOscillatorShape osc_shape = static_cast<MacroOscillatorShape>(shape);
  //   osc[osc_id].set_shape(osc_shape);
  //   //ui.set_meta_shape(osc_shape);
  // } else {
  osc[osc_id].set_shape(settings[osc_id].shape());
  // }

  // Set timbre and color: CV + internal modulation.
  uint16_t parameters[2];
  for (uint16_t i = 0; i < 2; ++i) {
    int32_t value = cc_params[osc_id][i];//settings.adc_to_parameter(i, adc.channel(i));
    Setting ad_mod_setting = i == 0 ? SETTING_AD_TIMBRE : SETTING_AD_COLOR;
    value += ad_value * settings[osc_id].GetValue(ad_mod_setting) >> 5;
    CONSTRAIN(value, 0, 32767);
    parameters[i] = value;
  }
  osc[osc_id].set_parameters(parameters[0], parameters[1]);

  // // Apply hysteresis to ADC reading to prevent a single bit error to move
  // // the quantized pitch up and down the quantization boundary.
  // int32_t pitch = quantizer.Process(
  //     midi_pitch[osc_id],//settings.adc_to_pitch(adc.channel(2)),
  //     (60 + settings[osc_id].quantizer_root()) << 7);
  // if (!settings[osc_id].meta_modulation()) {
  //     pitch += settings[osc_id].adc_to_fm(1000);//adc.channel(3));
  // }

  // Check if the pitch has changed to cause an auto-retrigger
  int32_t pitch = midi_pitch[osc_id];
  // int32_t pitch_delta = pitch - previous_pitch;
  // if (settings[osc_id].data().auto_trig &&
  //     (pitch_delta >= 0x40 || -pitch_delta >= 0x40)) {
  //   trigger_detected_flag = true;
  // }
  previous_pitch[osc_id] = pitch;

  //pitch += jitter_source.Render(settings[osc_id].vco_drift());
  //pitch += internal_adc.value() >> 8;
  pitch += ad_value * settings[osc_id].GetValue(SETTING_AD_FM) >> 7;

  if (pitch > 16383) {
    pitch = 16383;
  } else if (pitch < 0) {
    pitch = 0;
  }

  if (settings[osc_id].vco_flatten()) {
    pitch = Interpolate88(lut_vco_detune, pitch << 2);
  }
  osc[osc_id].set_pitch(pitch + settings[osc_id].pitch_transposition());

  if (trigger_flag[osc_id]) {
    osc[osc_id].Strike();
    envelope[osc_id].Trigger(ENV_SEGMENT_ATTACK);
    //ui.StepMarquee();
    trigger_flag[osc_id] = false;
  }

  uint8_t* sync_buffer = sync_samples[osc_id];
  int16_t* render_buffer = audio_samples[osc_id];

  if (settings[osc_id].GetValue(SETTING_AD_VCA) != 0
    || settings[osc_id].GetValue(SETTING_AD_TIMBRE) != 0
    || settings[osc_id].GetValue(SETTING_AD_COLOR) != 0
    || settings[osc_id].GetValue(SETTING_AD_FM) != 0) {
    memset(sync_buffer, 0, kBlockSize);
  }

  osc[osc_id].Render(sync_buffer, render_buffer, kBlockSize);

  // Copy to DAC buffer with sample rate and bit reduction applied.
  int16_t sample = 0;
  size_t decimation_factor = decimation_factors[settings[osc_id].data().sample_rate];
  uint16_t bit_mask = bit_reduction_masks[settings[osc_id].data().resolution];
  int32_t gain = settings[osc_id].GetValue(SETTING_AD_VCA) ? ad_value : 65535;
  uint16_t signature = settings[osc_id].signature() * settings[osc_id].signature() * 4095;
  for (size_t i = 0; i < kBlockSize; ++i) {
    if ((i % decimation_factor) == 0) {
      sample = render_buffer[i] & bit_mask;
    }
    sample = sample * gain_lp[osc_id] >> 16;
    gain_lp[osc_id] += (gain - gain_lp[osc_id]) >> 4;
    int16_t warped = ws[osc_id].Transform(sample);
    render_buffer[i] = Mix(sample, warped, signature);
  }
#ifdef PROFILE_RENDER
  debug_pin.Low();
#endif
}

int main(void) {
  Init();
  while (1) {
    // if (current_scale != settings.GetValue(SETTING_QUANTIZER_SCALE)) {
    //   current_scale = settings.GetValue(SETTING_QUANTIZER_SCALE);
    //   quantizer.Configure(scales[current_scale]);
    // }

    // while (render_block != playback_block) {
    //   RenderBlock();
    // }

    const uint32_t data = fifo_pop_blocking();
    const uint8_t  kind = (uint8_t)(data & 0b1111);

    switch (kind) {
    case 1:{ // Out_Buffer
        break;
    }
    case 2: { // In_Buffer

        const uint32_t offset     = (data >> 8) & 0xFFFFFF;
        const uint8_t  size       = (uint8_t)((data >> 4) & 0b1111);
        const int      buffer_len = 1 << size;
              int16_t *buffer     = (int16_t *)(RAM_BASE + offset);
             uint16_t *ubuffer    = (uint16_t *)buffer;

        for (int x = 0; x < buffer_len;){
            int32_t mix_buffer[kBlockSize] = {0};

            for (int osc_id = 0; osc_id < NBR_OF_OSCs; osc_id++) {

                RenderBlock(osc_id);

                int16_t* render_buffer = audio_samples[osc_id];
                for (int y = 0; y < kBlockSize; y++) {
                    mix_buffer[y] += render_buffer[y] / NBR_OF_OSCs;
                }
            }

            for (int y = 0; y < kBlockSize; y++, x++) {
                if (mix_buffer[y] > 32767) {
                    mix_buffer[y] = 32767;
                }  else if (mix_buffer[y] < -32768) {
                    mix_buffer[y] = -32768;
                }
                ubuffer[x] = (uint16_t)(mix_buffer[y] + 0x8000) >> SAMPLE_BITS_TO_DISCARD;
            }
        }

        fifo_push_blocking((data & (~0b1111)) | 1);
        break;
    }
    case 3: {// MIDI Msg
        uint32_t midi = (data >> 8)  & 0xFFFFFF;
        uint8_t  chan = (midi >> 0) & 0xF;
        uint8_t  kind = (midi >> 4) & 0xF;
        uint8_t  key  = (midi >> 8)  & 0xFF;
        uint8_t  val  = (midi >> 16)  & 0xFF;

        switch (kind) {
        case 0b1000:{// Note off
            break;
        }
        case 0b1001:{// Note on

            if (chan >= NBR_OF_OSCs) {
                //  The last channel is used to polyphony (round-robin)
                static uint8_t rr_next_chan = 0;

                chan = rr_next_chan;
                rr_next_chan = (rr_next_chan + 1) % NBR_OF_OSCs;
            }

            if (chan < NBR_OF_OSCs) {
                trigger_flag[chan] = true;

                //      FIXME?: Why this 24 offset in MIDI notes?
                midi_pitch[chan] = (((int32_t)key) << 7) - 24;

            }

            break;

        }
        case 0b1011:{// Control change
            if (chan < NBR_OF_OSCs) {
                switch (key) {
                case 0:{
                    cc_params[chan][0] = (int32_t)val * (MAX_PARAM / MAX_MIDI_VAL);
                    break;
                }
                case 1:{
                    cc_params[chan][1] = (int32_t)val * (MAX_PARAM / MAX_MIDI_VAL);
                    break;
                }
                case 2:{
                    if (val < MACRO_OSC_SHAPE_LAST) {
                        settings[chan].SetValue(SETTING_OSCILLATOR_SHAPE, static_cast<MacroOscillatorShape>(val));
                    }
                    break;
                }
                case 3:{
                    settings[chan].SetValue(SETTING_AD_FM, val);
                    break;
                }
                case 4:{
                    settings[chan].SetValue(SETTING_AD_ATTACK, val);
                    break;
                }
                case 5:{
                    settings[chan].SetValue(SETTING_AD_DECAY, val);
                    break;
                }
                case 6:{
                    settings[chan].SetValue(SETTING_AD_COLOR, val);
                    break;
                }
                default:{
                    break;
                }
                }
            }
        }
        default:{
            break;
        }
    }

        break;
    }
    default: {
        continue;
    }
    }

    //ui.DoEvents();
  }
}
