# 已知问题记录（不修复，仅备忘）

## 2026-09-03：TUI 追踪在子进程切换模型时错误识别导致前端卡住

- 现象：agent 通过 `opencode run --model <新模型>` 子进程方式调用视觉模型（tool-image-vision 流程）时，正在围观的前端 TUI 会错误识别/切换该会话，导致前端卡死。
- 复现路径：主会话（QQ 远控）→ `opencode run --model zhipuai-coding-plan/glm-5v-turbo ...` 子进程 → TUI 追踪异常。
- 影响：围观体验中断，需用户手动恢复；命令本身可能被 abort。
- 决定：仅记录，暂不修复。后续读图任务注意此风险，必要时提示用户先退出围观再执行。
