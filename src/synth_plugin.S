synth_plugin_start:
//.incbin "../synth_plugin/bin/synth_plugin.bin"

.incbin "../synth_plugin_macro/build/hello_world.bin"


synth_plugin_end:

.global synth_plugin_start
.global synth_plugin_end
