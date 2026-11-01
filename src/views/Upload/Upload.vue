<template>
  <div class="upload-container">
    <div class="upload-title">提交成绩</div>
    <form class="upload-form" @submit.prevent="uploadRun">
      <div class="form-grid">
        <div class="form-group">
          <span class="form-label" id="category-label">类别</span>
          <div class="readonly-field" aria-labelledby="category-label">Any%</div>
        </div>

        <div class="form-group">
          <label class="form-label" for="type">种子类型</label>
          <select class="form-select" id="type" v-model="type">
            <option
              v-for="option in TYPE_SELECTOR_OPTIONS"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label" for="version">版本范围</label>
          <select class="form-select" id="version" v-model="version">
            <option v-for="r in rangeOptions" :key="r.value" :value="r.value">
              {{ r.label }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label" for="igt-minute">IGT（游戏内时间）</label>
          <div class="time-inputs">
            <input
              class="form-input time-input"
              type="number"
              id="igt-minute"
              v-model="igtMinute"
              placeholder="0"
              min="0"
              autocomplete="off"
            />
            <span class="time-separator">分</span>
            <input
              class="form-input time-input"
              type="number"
              id="igt-second"
              v-model="igtSecond"
              placeholder="0"
              min="0"
              max="59"
              autocomplete="off"
            />
            <span class="time-separator">秒</span>
            <input
              class="form-input time-input"
              type="number"
              id="igt-millisecond"
              v-model="igtMillisecond"
              placeholder="0"
              min="0"
              max="999"
              autocomplete="off"
            />
            <span class="time-separator">毫秒</span>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="date">日期</label>
          <input class="form-input" type="date" id="date" v-model="date" autocomplete="off" />
        </div>

        <div class="form-group">
          <label class="form-label" for="video-link">视频链接</label>
          <input
            class="form-input"
            type="text"
            id="video-link"
            v-model="videoLink"
            placeholder="请输入视频链接"
            autocomplete="off"
          />
        </div>

        <div class="form-group">
          <label class="form-label" for="subversion">版本</label>
          <select class="form-select" id="subversion" v-model="subversion">
            <option v-for="v in subversionOptions" :key="v" :value="v">{{ v }}</option>
          </select>
        </div>

        <div class="form-group full-width">
          <label class="form-label" for="remarks">简介</label>
          <textarea
            class="form-textarea"
            id="remarks"
            v-model="remarks"
            placeholder="请输入简介信息"
            rows="3"
            autocomplete="off"
          />
        </div>
      </div>

      <div class="form-actions">
        <button
          class="submit-button"
          type="submit"
          :disabled="isSubmitting"
          :class="{ submitting: isSubmitting }"
        >
          <span v-if="!isSubmitting">提交成绩</span>
          <span v-else>提交中...</span>
        </button>

        <button type="button" class="clear-button" @click="clearForm" :disabled="isSubmitting">
          清空表单
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '@/lib/supabaseClient';
import { validateVideoLink, sanitizeTextInput, sanitizeVideoLink } from '@/utils/security';
import { TYPE_SELECTOR_OPTIONS } from '@/constants/common';
import { useUserStore } from '@/stores';
import {
  showErrorNotification,
  showSuccessNotification,
  showInfoNotification,
} from '@/utils/notification';

const userStore = useUserStore();

const version = ref('1.16+');
const type = ref('RSG');
const igtMinute = ref(0);
const igtSecond = ref(0);
const igtMillisecond = ref(0);
const date = ref(new Date().toISOString().split('T')[0]);
const videoLink = ref('');
const subversion = ref('1.16');
const remarks = ref('');

// 版本范围选项按种子类型区分：
// FSG 只有 1.16；RSG 为 Pre 1.8 / 1.8 / 1.9-1.12 / 1.13-1.15 / 1.16+；SSG 另分 1.16-1.19 与 1.20+。
interface RangeOption {
  value: string;
  label: string;
}

const RANGE_OPTIONS: Record<string, RangeOption[]> = {
  FSG: [{ value: '1.16', label: '1.16' }],
  RSG: [
    { value: '1.7.10', label: 'Pre 1.8' },
    { value: '1.8.9', label: '1.8' },
    { value: '1.12.2', label: '1.9-1.12' },
    { value: '1.15.2', label: '1.13-1.15' },
    { value: '1.16+', label: '1.16+' },
  ],
  SSG: [
    { value: '1.7.10', label: 'Pre 1.8' },
    { value: '1.8.9', label: '1.8' },
    { value: '1.12.2', label: '1.9-1.12' },
    { value: '1.15.2', label: '1.13-1.15' },
    { value: '1.16-1.19', label: '1.16-1.19' },
    { value: '1.20+', label: '1.20+' },
  ],
};

const rangeOptions = computed(() => RANGE_OPTIONS[type.value] ?? RANGE_OPTIONS.RSG);

// 实际版本号选项：按所选版本范围（区间 key）给出对应清单。
const VERSIONS_1_16_TO_1_19 = [
  '1.16', '1.16.1', '1.16.2', '1.16.3', '1.16.4', '1.16.5',
  '1.17', '1.17.1', '1.18', '1.18.1', '1.18.2',
  '1.19', '1.19.1', '1.19.2', '1.19.3', '1.19.4',
];
const VERSIONS_1_20_PLUS = [
  '1.20', '1.20.1', '1.20.2', '1.20.3', '1.20.4', '1.20.5', '1.20.6',
  '1.21', '1.21.1', '1.21.2', '1.21.3', '1.21.4', '1.21.5', '1.21.6',
  '1.21.7', '1.21.8', '1.21.9', '1.21.10', '1.21.11',
  '26.1', '26.1.1', '26.1.2', '26.2', '26.3',
];
const VERSIONS_1_16_ONLY = ['1.16', '1.16.1', '1.16.2', '1.16.3', '1.16.4', '1.16.5'];

const VERSION_BY_RANGE: Record<string, string[]> = {
  '1.7.10': [
    '1.0', '1.1', '1.2.1', '1.2.2', '1.2.3', '1.2.4', '1.2.5', '1.3.1', '1.3.2',
    '1.4.2', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.5', '1.5.1', '1.5.2', '1.6.1',
    '1.6.2', '1.6.4', '1.7.2', '1.7.4', '1.7.5', '1.7.6', '1.7.7', '1.7.8', '1.7.9',
    '1.7.10',
  ],
  '1.8.9': [
    '1.8', '1.8.1', '1.8.2', '1.8.3', '1.8.4', '1.8.5', '1.8.6', '1.8.7', '1.8.8',
    '1.8.9',
  ],
  '1.12.2': [
    '1.9', '1.9.1', '1.9.2', '1.9.3', '1.9.4', '1.10', '1.10.1', '1.10.2', '1.11',
    '1.11.1', '1.11.2', '1.12', '1.12.1', '1.12.2',
  ],
  '1.15.2': [
    '1.13', '1.13.1', '1.13.2', '1.14', '1.14.1', '1.14.2', '1.14.3', '1.14.4',
    '1.15', '1.15.1', '1.15.2',
  ],
  '1.16-1.19': VERSIONS_1_16_TO_1_19,
  '1.20+': VERSIONS_1_20_PLUS,
  // FSG：只有 1.16 区间
  '1.16': VERSIONS_1_16_ONLY,
  // RSG：1.16+ 覆盖 1.16-1.19 与 1.20+
  '1.16+': [...VERSIONS_1_16_TO_1_19, ...VERSIONS_1_20_PLUS],
};

const subversionOptions = computed(() => VERSION_BY_RANGE[version.value] ?? []);

// 数据库 runs.version 存代表版本，提交时由版本范围（必要时结合实际版本）换算。
const representativeVersion = computed(() => {
  if (version.value === '1.16+') {
    return VERSIONS_1_16_TO_1_19.includes(subversion.value) ? '1.16.1' : '1.20';
  }
  if (version.value === '1.16-1.19') return '1.16.1';
  if (version.value === '1.20+') return '1.20';
  if (version.value === '1.16') return '1.16.1';
  return version.value; // 1.7.10 / 1.8.9 / 1.12.2 / 1.15.2
});

// 切换种子类型时，把当前区间映射到该类型下的对应区间；无法对应则回退第一项。
const normalizeRange = () => {
  const keys = rangeOptions.value.map((r) => r.value);
  if (keys.includes(version.value)) return;

  const current = version.value;
  if (type.value === 'FSG') {
    version.value = '1.16';
  } else if (type.value === 'RSG') {
    version.value = current === '1.16-1.19' || current === '1.20+' || current === '1.16' ? '1.16+' : keys[0];
  } else {
    // SSG
    version.value = current === '1.16+' || current === '1.16' ? '1.20+' : keys[0];
  }
};

// 版本范围或种子类型变化时，实际版本重置为新区间第一项。
watch(
  () => type.value,
  () => normalizeRange()
);
watch(
  () => version.value,
  () => {
    subversion.value = subversionOptions.value[0] ?? '';
  }
);

// 防重复提交状态
const isSubmitting = ref(false);

const formatTime = (minute: unknown, second: unknown, millisecond: unknown) => {
  return (
    String(minute ?? 0).padStart(2, '0') +
    ':' +
    String(second ?? 0).padStart(2, '0') +
    '.' +
    String(millisecond ?? 0).padStart(3, '0')
  );
};

const igt = computed(() => formatTime(igtMinute.value, igtSecond.value, igtMillisecond.value));

const checkRequiredInfo = () => {
  if (version.value === '') {
    showErrorNotification('版本范围不能为空');
    return false;
  }
  if (type.value === '') {
    showErrorNotification('种子类型不能为空');
    return false;
  }
  if (igt.value === '00:00.000') {
    showErrorNotification('IGT 不能为 0');
    return false;
  }
  if (date.value === '') {
    showErrorNotification('日期不能为空');
    return false;
  }

  const videoLinkValidation = validateVideoLink(videoLink.value);
  if (!videoLinkValidation.isValid) {
    showErrorNotification(videoLinkValidation.message);
    return false;
  }

  return true;
};

const insertRun = async () => {
  const sanitizedRemarks = sanitizeTextInput(remarks.value.trim());
  const sanitizedVideoLink = sanitizeVideoLink(videoLink.value.trim());

  const userId = userStore.userInfo.id;
  const { data, error } = await supabase.from('runs').insert({
    userid: userId,
    version: representativeVersion.value,
    type: type.value,
    igt: igt.value,
    date: date.value.replace(/-/g, '/'),
    videolink: sanitizedVideoLink,
    remarks: sanitizedRemarks,
    subversion: sanitizeTextInput(subversion.value.trim()),
    status: 'pending',
  });
  if (error) {
    console.error('提交成绩失败', error);
    showErrorNotification('提交失败，请稍后重试');
    return;
  }
  showSuccessNotification('提交成功，等待审核');

  // 提交成功后清空表单
  clearForm();
};

/**
 * 清空所有表单输入
 */
const clearForm = () => {
  version.value = '1.16+';
  type.value = 'RSG';
  igtMinute.value = 0;
  igtSecond.value = 0;
  igtMillisecond.value = 0;
  date.value = new Date().toISOString().split('T')[0];
  videoLink.value = '';
  subversion.value = subversionOptions.value[0] ?? '';
  remarks.value = '';
};

const uploadRun = async () => {
  // 防重复提交检查
  if (isSubmitting.value) {
    showInfoNotification('正在提交中，请勿重复提交');
    return;
  }

  if (!checkRequiredInfo()) {
    return;
  }

  try {
    isSubmitting.value = true; // 设置提交状态
    await insertRun();
  } catch (error) {
    console.error('提交过程中出现错误:', error);
    showErrorNotification('提交失败，请重试');
  } finally {
    isSubmitting.value = false; // 重置提交状态
  }
};
</script>

<style scoped>
.upload-container {
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.upload-title {
  color: #fff;
  font-size: 1.8em;
  font-weight: 600;
  text-align: center;
  margin-bottom: 30px;
}

.upload-form {
  width: 100%;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-label {
  color: #ccc;
  font-size: 0.9em;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.readonly-field {
  padding: 12px 16px;
  background-color: rgba(76, 175, 80, 0.08);
  border: 1px solid rgba(76, 175, 80, 0.35);
  border-radius: 8px;
  color: #4caf50;
  font-weight: 600;
}

.form-input,
.form-select {
  width: 100%;
  padding: 12px 16px;
  background-color: #333;
  border: 1px solid #444;
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
  transition: all 0.2s ease;
  box-sizing: border-box;
}

.form-input::placeholder {
  color: #666;
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #4caf50;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.1);
}

.time-inputs {
  display: flex;
  align-items: center;
  gap: 8px;
}

.time-input {
  width: 72px;
  text-align: center;
  min-width: 0;
}

.time-separator {
  color: #666;
  font-weight: 600;
  font-size: 14px;
  white-space: nowrap;
}

.form-textarea {
  width: 100%;
  padding: 12px 16px;
  background-color: #333;
  border: 1px solid #444;
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
  transition: all 0.2s ease;
  box-sizing: border-box;
  resize: vertical;
  min-height: 80px;
  font-family: inherit;
}

.form-textarea:focus {
  outline: none;
  border-color: #4caf50;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.1);
}

.form-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
  padding-top: 20px;
}

.submit-button {
  background: linear-gradient(135deg, #4caf50, #388e3c);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 14px 32px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.submit-button:hover {
  background: linear-gradient(135deg, #43a047, #2e7d32);
  transform: translateY(-2px);
  box-shadow: 0 4px 20px rgba(76, 175, 80, 0.3);
}

.submit-button:active {
  transform: translateY(0);
}

.submit-button:disabled {
  background: linear-gradient(135deg, #666, #555);
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
  opacity: 0.7;
}

.submit-button.submitting {
  background: linear-gradient(135deg, #388e3c, #1b5e20);
  cursor: wait;
}

.submit-button.submitting:hover {
  transform: none;
  box-shadow: none;
}

.clear-button {
  background: linear-gradient(135deg, #666, #555);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 14px 24px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.clear-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #777, #666);
  transform: translateY(-2px);
  box-shadow: 0 4px 20px rgba(102, 102, 102, 0.3);
}

.clear-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.clear-button:active:not(:disabled) {
  transform: translateY(0);
}

@media (max-width: 768px) {
  .upload-container {
    padding: 16px;
  }

  .upload-title {
    font-size: 1.5em;
    margin-bottom: 24px;
  }

  .form-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .form-input,
  .form-select,
  .form-textarea {
    padding: 10px 14px;
  }

  .time-inputs {
    flex-wrap: wrap;
  }

  .submit-button {
    padding: 12px 24px;
    font-size: 14px;
  }
}
</style>
