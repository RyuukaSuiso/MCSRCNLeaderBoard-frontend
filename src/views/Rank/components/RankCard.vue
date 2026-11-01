<template>
  <div class="stats" @click="handleClick">
    <span class="new-record-cell" v-if="isNewRecord">NEW</span>
    <div class="cell rank-cell">
      <img
        :src="rankPlaceIconSrc(rank)"
        :alt="`第 ${rank} 名`"
        class="rank-icon"
        v-if="rank <= 3"
      />
      <span v-else>{{ rank }}</span>
    </div>
    <div class="cell player-cell">
      <RouterLink :to="`/profile/${userId}`" class="player-link" @click.stop>{{
        nickname
      }}</RouterLink>
      <span class="new-record-badge" v-if="isNewRecord">NEW</span>
    </div>
    <div class="cell igt-cell">
      <RouterLink
        :to="`/run/${runId}`"
        :aria-label="`${nickname} 的成绩 ${igt}，查看详情`"
        @click.stop
        >{{ igt }}</RouterLink
      >
    </div>
    <div class="cell date-cell">{{ date }}</div>
    <div class="cell version-cell">{{ version }}</div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router';
// 导入排名图标
import firstPlaceIcon from '@/assets/icons/firstplace.png';
import secondPlaceIcon from '@/assets/icons/secondplace.png';
import thirdPlaceIcon from '@/assets/icons/thirdplace.png';
import { computed } from 'vue';

// 定义 props
interface Props {
  rank: number;
  nickname: string;
  userId: number;
  igt: string;
  date: string;
  version: string;
  runId: number;
  is_new_record: boolean;
}

const props = defineProps<Props>();

// 定义 emits
const emit = defineEmits<{
  click: [runId: number];
}>();

// 处理点击事件
const handleClick = () => {
  emit('click', props.runId);
};

// 获取排名图标
const rankPlaceIconSrc = (rank: number) => {
  if (rank === 1) {
    return firstPlaceIcon;
  } else if (rank === 2) {
    return secondPlaceIcon;
  } else if (rank === 3) {
    return thirdPlaceIcon;
  }
  return '';
};

// 判断是否为30天内的新成绩
const isNewRecord = computed(() => {
  return props.is_new_record;
});
</script>

<style scoped>
.stats {
  cursor: pointer;
  transition: background-color 0.2s ease;
  border-bottom: 1px solid var(--border);
  display: grid;
  grid-template-columns: 64px minmax(0, 2fr) minmax(130px, 1.1fr) 108px 88px;
  position: relative;
  color: var(--text-secondary);
}

.stats:nth-child(even) {
  background-color: rgba(255, 255, 255, 0.02);
}

.stats:hover {
  background-color: var(--hovercolor);
  color: #fff;
}

.stats:last-child {
  border-bottom: none;
}

.cell {
  min-width: 0;
  padding: 14px 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.new-record-cell {
  position: absolute;
  left: 0;
  top: 0;
  color: #4caf50;
  font-weight: 600;
  font-size: 0.8em;
  transform: rotate(-45deg);
}

.rank-icon {
  width: 30px;
  height: 30px;
}

.rank-cell {
  font-weight: 600;
  color: var(--accent-bright);
  font-variant-numeric: tabular-nums;
}

.player-cell {
  font-weight: 500;
  font-size: 1.1em;
  color: #fff;
  justify-content: flex-start;
  padding-left: 12px;
}

.player-link {
  min-width: 0;
  overflow-wrap: anywhere;
}

.stats a {
  color: inherit;
  text-decoration: none;
}

.stats a:hover {
  color: #4caf50;
}

.stats a:focus-visible {
  outline: 2px solid #4caf50;
  outline-offset: 3px;
  border-radius: 4px;
}

.new-record-badge {
  display: none;
}

.igt-cell {
  font-family: 'Courier New', monospace;
  font-weight: 600;
  font-size: 1.1em;
  color: #fff;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.date-cell {
  color: var(--text-secondary);
  font-size: 0.9em;
}

.version-cell {
  color: var(--text-secondary);
  font-size: 0.9em;
  font-variant-numeric: tabular-nums;
}

@media (max-width: 780px) {
  .stats {
    display: grid;
    grid-template-columns: 44px minmax(0, 1fr) 112px;
    column-gap: 8px;
    padding: 0 12px;
  }

  .stats:hover {
    transform: none;
  }

  .cell {
    min-width: 0;
    padding: 16px 0 4px;
    font-size: 14px;
  }

  .player-cell {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }

  .igt-cell {
    font-size: 15px;
  }

  .rank-icon {
    width: 26px;
    height: 26px;
  }

  .date-cell,
  .version-cell,
  .new-record-cell {
    display: none;
  }

  .new-record-badge {
    display: inline-flex;
    color: #4caf50;
    font-size: 10px;
    font-weight: 600;
  }
}

@media (prefers-reduced-motion: reduce) {
  .stats {
    transition: none;
  }
}
</style>
