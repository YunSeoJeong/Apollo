<script setup>
import {ref, computed, inject} from 'vue'
import {$tp} from '../../platform-i18n'
import PlatformLayout from '../../PlatformLayout.vue'
import AdapterNameSelector from './audiovideo/AdapterNameSelector.vue'
import DisplayOutputSelector from './audiovideo/DisplayOutputSelector.vue'
import DisplayDeviceOptions from "./audiovideo/DisplayDeviceOptions.vue";
import DisplayModesSettings from "./audiovideo/DisplayModesSettings.vue";
import Checkbox from "../../Checkbox.vue";

const i18n = inject('i18n');
const $t = i18n?.t ?? ((key) => key);

const props = defineProps([
  'platform',
  'config',
  'vdisplay',
  'min_fps_factor',
])

const sudovdaStatus = {
  '1': 'Unknown',
  '0': 'Ready',
  '-1': 'Uninitialized',
  '-2': 'Version Incompatible',
  '-3': 'Watchdog Failed'
}

const currentDriverStatus = computed(() => sudovdaStatus[props.vdisplay])

const config = ref(props.config ?? {})
config.value.vdd_mode_table ??= "1920x1080@60\n2560x1440@60\n3840x2160@60"

const validateFallbackMode = (event) => {
  const value = event.target.value;
  if (!value.match(/^\d+x\d+x\d+(\.\d+)?$/)) {
    event.target.setCustomValidity($t('config.fallback_mode_error'));
  } else {
    event.target.setCustomValidity('');
  }

  event.target.reportValidity();
}
</script>

<template>
  <div id="audio-video" class="config-page">
    <!-- Audio Sink -->
    <div class="mb-3">
      <label for="audio_sink" class="form-label">{{ $t('config.audio_sink') }}</label>
      <input type="text" class="form-control" id="audio_sink"
             :placeholder="$tp('config.audio_sink_placeholder', 'alsa_output.pci-0000_09_00.3.analog-stereo')"
             v-model="config.audio_sink" />
      <div class="form-text pre-wrap">
        {{ $tp('config.audio_sink_desc') }}<br>
        <PlatformLayout :platform="platform">
          <template #windows>
            <pre>tools\audio-info.exe</pre>
          </template>
          <template #linux>
            <pre>pacmd list-sinks | grep "name:"</pre>
            <pre>pactl info | grep Source</pre>
          </template>
          <template #macos>
            <a href="https://github.com/mattingalls/Soundflower" target="_blank">Soundflower</a><br>
            <a href="https://github.com/ExistentialAudio/BlackHole" target="_blank">BlackHole</a>.
          </template>
        </PlatformLayout>
      </div>
    </div>

    <PlatformLayout :platform="platform">
      <template #windows>
        <!-- Virtual Sink -->
        <div class="mb-3">
          <label for="virtual_sink" class="form-label">{{ $t('config.virtual_sink') }}</label>
          <input type="text" class="form-control" id="virtual_sink" :placeholder="$t('config.virtual_sink_placeholder')"
                 v-model="config.virtual_sink" />
          <div class="form-text pre-wrap">{{ $t('config.virtual_sink_desc') }}</div>
        </div>
        <!-- Install Steam Audio Drivers -->
        <Checkbox class="mb-3"
                  id="install_steam_audio_drivers"
                  locale-prefix="config"
                  v-model="config.install_steam_audio_drivers"
                  default="true"
        ></Checkbox>

        <Checkbox class="mb-3"
                  id="keep_sink_default"
                  locale-prefix="config"
                  v-model="config.keep_sink_default"
                  default="true"
        ></Checkbox>

        <Checkbox class="mb-3"
                  id="auto_capture_sink"
                  locale-prefix="config"
                  v-model="config.auto_capture_sink"
                  default="true"
        ></Checkbox>
      </template>
    </PlatformLayout>

    <!-- Disable Audio -->
    <Checkbox class="mb-3"
              id="stream_audio"
              locale-prefix="config"
              v-model="config.stream_audio"
              default="true"
    ></Checkbox>

    <AdapterNameSelector
        :platform="platform"
        :config="config"
    />

    <DisplayOutputSelector
      :platform="platform"
      :config="config"
    />

    <DisplayDeviceOptions
      :platform="platform"
      :config="config"
    />

    <!-- Display Modes -->
    <DisplayModesSettings
        :platform="platform"
        :config="config"
    />

    <!-- Fallback Display Mode -->
    <div class="mb-3">
      <label for="fallback_mode" class="form-label">{{ $t('config.fallback_mode') }}</label>
      <input
        type="text"
        class="form-control"
        id="fallback_mode"
        v-model="config.fallback_mode"
        placeholder="1920x1080x60"
        @input="validateFallbackMode"
      />
      <div class="form-text">{{ $t('config.fallback_mode_desc') }}</div>
    </div>

    <!-- Headless Mode -->
    <Checkbox class="mb-3"
              id="headless_mode"
              locale-prefix="config"
              v-model="config.headless_mode"
              default="false"
              v-if="platform === 'windows'"
    ></Checkbox>

    <!-- Double Refreshrate -->
    <Checkbox class="mb-3"
              id="double_refreshrate"
              locale-prefix="config"
              v-model="config.double_refreshrate"
              default="false"
              v-if="platform === 'windows'"
    ></Checkbox>

    <!-- Isolated Virtual Display -->
    <Checkbox class="mb-3"
              id="isolated_virtual_display_option"
              locale-prefix="config"
              v-model="config.isolated_virtual_display_option"
              default="false"
              v-if="platform === 'windows'"
    ></Checkbox>

    <!-- vdVDD Mode Table -->
    <div class="mb-3" v-if="platform === 'windows'">
      <label for="vdd_mode_table" class="form-label">{{ $tp('config.vdd_mode_table', 'vdVDD resolution mode table') }}</label>
      <textarea
        class="form-control font-monospace"
        id="vdd_mode_table"
        rows="7"
        placeholder="1920x1080@60&#10;2560x1440@120&#10;3840x2160@60"
        v-model="config.vdd_mode_table"
      ></textarea>
      <div class="form-text">{{ $tp('config.vdd_mode_table_desc', 'One mode per line. Format: WIDTHxHEIGHT@HZ. These modes are applied the next time the driver is enabled.') }}</div>
    </div>

    <!-- SudoVDA Driver Status -->
    <div class="alert" :class="[vdisplay ? 'alert-warning' : 'alert-success']" v-if="platform === 'windows'">
      <i class="fa-solid fa-xl fa-circle-info"></i> Virtual Display Driver status: {{currentDriverStatus}}
    </div>
    <div class="form-text" v-if="platform === 'windows' && vdisplay">Please ensure the virtual display driver is installed to the latest version and enabled properly.</div>

  </div>
</template>

<style scoped>
</style>
