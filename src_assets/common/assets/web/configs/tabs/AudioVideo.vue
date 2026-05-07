<script setup>
import {ref, computed, inject, watch} from 'vue'
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

const blankVddMode = () => ({
  width: '',
  height: '',
  refresh: ''
})

const parseVddModeTable = (value) => {
  const rows = `${value ?? ''}`
    .split(/[\r\n;]+/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const match = line.match(/^(\d+)\s*x\s*(\d+)\s*@\s*(\d+(?:\.\d+)?)$/i)
      if (match) {
        return {
          width: match[1],
          height: match[2],
          refresh: match[3]
        }
      }

      const parts = line.match(/\d+(?:\.\d+)?/g) ?? []
      return {
        width: parts[0] ?? '',
        height: parts[1] ?? '',
        refresh: parts[2] ?? ''
      }
    })

  return rows.length ? rows : [blankVddMode()]
}

const normalizeVddModePart = (value) => `${value ?? ''}`.trim()

const serializeVddModeTable = (rows) => rows
  .map((row) => ({
    width: normalizeVddModePart(row.width),
    height: normalizeVddModePart(row.height),
    refresh: normalizeVddModePart(row.refresh)
  }))
  .filter((row) => row.width && row.height && row.refresh)
  .map((row) => `${row.width}x${row.height}@${row.refresh}`)
  .join(';')

const vddModeRows = ref(parseVddModeTable(config.value.vdd_mode_table))

watch(
  () => config.value.vdd_mode_table,
  (value) => {
    if (serializeVddModeTable(vddModeRows.value) !== `${value ?? ''}`.trim()) {
      vddModeRows.value = parseVddModeTable(value)
    }
  }
)

watch(
  vddModeRows,
  (rows) => {
    config.value.vdd_mode_table = serializeVddModeTable(rows)
  },
  {deep: true}
)

const addVddModeRow = () => {
  vddModeRows.value.push(blankVddMode())
}

const removeVddModeRow = (index) => {
  vddModeRows.value.splice(index, 1)
  if (!vddModeRows.value.length) {
    addVddModeRow()
  }
}

const moveVddModeRow = (index, offset) => {
  const target = index + offset
  if (target < 0 || target >= vddModeRows.value.length) {
    return
  }

  const [row] = vddModeRows.value.splice(index, 1)
  vddModeRows.value.splice(target, 0, row)
}

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
      <div id="vdd_mode_table" class="vdd-mode-table border rounded overflow-hidden">
        <div class="vdd-mode-row vdd-mode-header">
          <div>{{ $tp('config.vdd_mode_width', 'Width') }}</div>
          <div>{{ $tp('config.vdd_mode_height', 'Height') }}</div>
          <div>{{ $tp('config.vdd_mode_refresh_rate', 'Hz') }}</div>
          <div class="text-end">{{ $tp('config.vdd_mode_actions', 'Actions') }}</div>
        </div>
        <div class="vdd-mode-row" v-for="(mode, index) in vddModeRows" :key="index">
          <input
            type="number"
            min="1"
            step="1"
            class="form-control"
            inputmode="numeric"
            placeholder="1920"
            v-model="mode.width"
          />
          <input
            type="number"
            min="1"
            step="1"
            class="form-control"
            inputmode="numeric"
            placeholder="1080"
            v-model="mode.height"
          />
          <input
            type="number"
            min="1"
            step="0.01"
            class="form-control"
            inputmode="decimal"
            placeholder="60"
            v-model="mode.refresh"
          />
          <div class="vdd-mode-actions">
            <button
              type="button"
              class="btn btn-outline-secondary btn-sm"
              :disabled="index === 0"
              :title="$tp('config.vdd_mode_move_up', 'Move up')"
              :aria-label="$tp('config.vdd_mode_move_up', 'Move up')"
              @click="moveVddModeRow(index, -1)"
            >
              <i class="fa-solid fa-arrow-up"></i>
            </button>
            <button
              type="button"
              class="btn btn-outline-secondary btn-sm"
              :disabled="index === vddModeRows.length - 1"
              :title="$tp('config.vdd_mode_move_down', 'Move down')"
              :aria-label="$tp('config.vdd_mode_move_down', 'Move down')"
              @click="moveVddModeRow(index, 1)"
            >
              <i class="fa-solid fa-arrow-down"></i>
            </button>
            <button
              type="button"
              class="btn btn-outline-danger btn-sm"
              :title="$tp('config.vdd_mode_remove', 'Remove')"
              :aria-label="$tp('config.vdd_mode_remove', 'Remove')"
              @click="removeVddModeRow(index)"
            >
              <i class="fa-solid fa-trash"></i>
            </button>
          </div>
        </div>
      </div>
      <button type="button" class="btn btn-outline-primary btn-sm mt-2" @click="addVddModeRow">
        <i class="fa-solid fa-plus me-1"></i>{{ $tp('config.vdd_mode_add', 'Add mode') }}
      </button>
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
.vdd-mode-table {
  background: var(--bs-body-bg);
}

.vdd-mode-row {
  display: grid;
  grid-template-columns: minmax(88px, 1fr) minmax(88px, 1fr) minmax(76px, .8fr) 124px;
  gap: .5rem;
  align-items: center;
  padding: .5rem;
}

.vdd-mode-row + .vdd-mode-row {
  border-top: 1px solid var(--bs-border-color);
}

.vdd-mode-header {
  background: var(--bs-tertiary-bg);
  color: var(--bs-secondary-color);
  font-size: .875rem;
  font-weight: 600;
}

.vdd-mode-actions {
  display: grid;
  grid-template-columns: repeat(3, 36px);
  justify-content: end;
  gap: .25rem;
}

.vdd-mode-actions .btn {
  width: 36px;
}

@media (max-width: 575.98px) {
  .vdd-mode-row {
    grid-template-columns: 1fr 1fr;
  }

  .vdd-mode-header {
    display: none;
  }

  .vdd-mode-actions {
    grid-column: 1 / -1;
    justify-content: start;
  }
}
</style>
