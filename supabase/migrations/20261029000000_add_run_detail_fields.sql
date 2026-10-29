-- 为 runs 表补充成绩新字段：真实时间、难度、F3、模组情况
-- （版本号已由 subversion 承载，无需新增）
-- 请在 Supabase SQL Editor 中执行；全部可空，老数据不受影响。

alter table public.runs
  add column if not exists rta text default '',
  add column if not exists difficulty text default '',
  add column if not exists f3 text default '',
  add column if not exists mods text default '';
