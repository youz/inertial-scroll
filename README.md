# inertial-scroll for xyzzy

xyzzyで慣性スクロール

要 xyzzy ver 0.2.2.246以上

## .xyzzy 設定例

```
(require "inertial-scroll")
(setq inertial:*initial-velocity* 40   ; 初速度
      inertial:*max-velocity* 200      ; 最大速度
      inertial:*accel* 2/3)            ; 加速時に (* *initial-velocity* *accel*) の値が加速される

(global-set-key #\C-\, 'inertial:scroll-forward)  ; 下へ
(global-set-key #\C-. 'inertial:scroll-backward)  ; 上へ
(global-set-key #\C-< 'inertial:scroll-forward-all-windows)   ; 全ウィンドウ上へ
(global-set-key #\C-> 'inertial:scroll-backward-all-windows)  ; 全ウィンドウ下へ

(inertial:enable-wheel-scroll)  ; ホイールスクロールでも慣性スクロールする
(setq inertial:*wheel-scroll-threshold* 1)  ; ホイールの入力値が1以下なら通常スクロール
```
