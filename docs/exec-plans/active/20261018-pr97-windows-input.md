# PR #97: Windows scrolling, DPI and explicit global input

## Goal

Integrate latest main into the original PR, fix issues found in review, add repeatable real Windows desktop tests, and push reviewable follow-up commits. Do not merge the PR.

## Decisions

- Preserve the original contributor commit and current selective-observation behavior.
- Fix missing scroll bounds and align Win32/UIA/capture to physical pixel coordinates.
- Keep global input opt-in. Default and explicitly selected app_post/accessibility delivery must not switch to real input silently.
- Remove synthetic Alt focus tricks; verify target foreground, geometry and pointer hit target before physical input. Validate keys before pressing modifiers, release pressed keys/buttons in finally, and report native input failures.
- Exercise only owned fixtures on a hosted Windows desktop; reuse the existing read-only-permissions Windows workflow, without a local desktop VM.
- Record actual DPI and toolkit coverage; do not infer high-DPI/WinUI validation from a normal-DPI WPF test.

## Progress

- [x] Fetch latest main and original PR, resolve conflicts and adapt tests to the existing service bridge seam.
- [ ] Review/fix global input, coordinate freshness and cleanup; add focused regression tests.
- [ ] Add actual Windows scrolling, physical click/drag/key, gate/default/refusal and DPI/capture checks alongside existing observation smoke.
- [ ] Run Go tests/vet/builds, PowerShell tests, relevant JS checks, documentation checks and hosted desktop CI.
- [ ] Update docs/history/PR, synchronize remotes, push and report merge readiness.

## Initial findings

Main is `31a7d7d` (#101). The original PR adds a second process-global bridge test seam, now superseded by service.runBridge. Global drag/scroll ignore focus failure; global click does not confirm its target; key validation occurs after modifier downs and has no finally cleanup. The global-key branch changes every auto press_key when the pointer gate is enabled. Keep auto on window messages and expose real keys through explicit Windows key_method=global. These require fixes before merge.

## Desktop findings

First hosted run passed Go, PowerShell and the existing observation smoke. The real default scroll test exposed a second coordinate bug: WM_MOUSEWHEEL/HWHEEL lParam was incorrectly converted to client coordinates. Preserve screen coordinates and report PostMessage failure, then rerun the actual scroll-offset check.
