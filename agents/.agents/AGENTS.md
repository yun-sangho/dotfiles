# 전역 에이전트 규칙 (Claude Code · Codex 공용)
# 원본: ~/.agents/AGENTS.md → ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md 는 심링크

## 브라우저 사용
- 브라우저가 필요한 작업(페이지 열기·읽기·클릭·폼 입력·스크린샷·QA)은 항상 `ego-browser` 스킬을 먼저 읽고 Ego Lite로 수행한다.
- 다른 브라우저 도구(claude-in-chrome, Codex 내장 browser/Chrome 백엔드, computer-use 등)는 쓰지 않는다.
- 오스틴님이 보고 있는 페이지를 수정할 때: 수정 전 Ego Lite에서 해당 탭을 읽고, 수정 후 같은 탭에서 결과를 확인한다.
- Ego Lite가 응답하지 않거나 실패하면 다른 브라우저 도구로 우회하지 말고 먼저 물어본다.
- 로그인 없이 볼 수 있는 공개 문서는 웹 fetch 도구를 써도 된다. 사내·로그인 페이지는 Ego Lite로 본다.

## Git worktree와 머지
- git 저장소에서 worktree 생성·삭제는 `hwt new`/`hwt rm`으로만 한다. `git worktree add/remove/prune`, EnterWorktree, Agent `isolation: "worktree"`는 쓰지 않는다. 병렬 작업자는 저장소 밖 출력 폴더나 hwt worktree를 쓴다.
- hwt worktree나 merge queue 항목이 있는 PR은 `hwt mq`로 머지한다. `gh pr merge`를 직접 쓰지 않는다.
- 스킬(pstack 등)의 worktree·머지 지시와 충돌하면 이 규칙과 `hwt` 스킬을 따른다.
