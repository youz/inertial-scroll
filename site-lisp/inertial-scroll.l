;;; -*- mode:lisp; package:inertial-scroll -*-

;;; ; .xyzzy 設定例
;;; (require "inertial-scroll")
;;; (setq inertial:*initial-velocity* 40
;;;       inertial:*max-velocity* 200
;;;       inertial:*accel* 2/3)
;;; (global-set-key #\C-\, 'inertial:scroll-forward)
;;; (global-set-key #\C-. 'inertial:scroll-backward)
;;; (global-set-key #\C-M-\, 'inertial:scroll-forward-all-windows)
;;; (global-set-key #\C-M-. 'inertial:scroll-backward-all-windows)
;;; (global-set-key #\C-< 'inertial:auto-scroll-forward)
;;; (global-set-key #\C-> 'inertial:auto-scroll-backward)
;;; (inertial:enable-wheel-scroll)


(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "foreign"))

(provide "inertial-scroll")

(defpackage #:inertial-scroll
  (:nicknames #:inertial)
  (:use #:lisp #:editor)
  (:export
   #:*initial-velocity*
   #:*max-velocity*
   #:*friction*
   #:*accel*
   #:scroll-forward
   #:scroll-backward
   #:scroll-forward-all-windows
   #:scroll-backward-all-windows
   #:auto-scroll-forward
   #:auto-scroll-backward
   #:auto-scroll-forward-all-windows
   #:auto-scroll-backward-all-windows

   ;; wheel scrolling
   #:*wheel-scroll-threshold*
   #:enable-wheel-scroll
   #:disable-wheel-scroll
   ))

(in-package :inertial)

(defvar *initial-velocity* 30)
(defvar *max-velocity* 100)
(defvar *friction* 2)
(defvar *accel* 1/2)


(defstruct timer
  func velocity friction dir)

(defvar *timer* nil)

(defun stop-scrolling ()
  (when *timer*
    (stop-timer (timer-func *timer*))
    (setq *timer* nil)))

(defun start-scrolling (windows dir)
  (let ((com *this-command*))
    (labels ((scroll1 (win n)
	       (unless (deleted-window-p win)
		 (with-selected-window
		   (set-window win)
		   (let ((r (get-window-line)))
		     (prog1
			 (next-virtual-line n)
		       (recenter r))))))
	     (scroll ()
	       (if (eq *this-command* com)
		   (let ((d (* (timer-dir *timer*) (ceiling (timer-velocity *timer*) 10))))
		     (dolist (win windows)
		       (unless (scroll1 win d)
			 (stop-scrolling)
			 (return-from scroll)))
		     (if (> (decf (timer-velocity *timer*) (timer-friction *timer*)) 10)
			 (start-timer (/ (timer-velocity *timer*)) #'scroll t)
		       (stop-scrolling))
		     (refresh-screen))
		 (stop-scrolling))))
      (let ((v (if *timer*
		   (+ (timer-velocity *timer*) (* *initial-velocity* *accel*))
		 *initial-velocity*)))
	(stop-scrolling)
	(setq *timer* (make-timer :func #'scroll
				  :velocity (min v *max-velocity*)
				  :friction *friction*
				  :dir (signum dir))))
      (scroll)
      *timer*)))

(defun scroll-forward (&optional (dir 1))
  (interactive "p")
  (start-scrolling (list (selected-window)) dir))

(defun scroll-backward (&optional (dir 1))
  (interactive "p")
  (scroll-forward (- dir)))

(defun auto-scroll-forward (&optional (dir 1))
  (interactive "p")
  (let ((*friction* 0))
    (start-scrolling (list (selected-window)) dir)))

(defun auto-scroll-backward (&optional (dir 1))
  (interactive "p")
  (auto-scroll-forward (- dir)))

(defun list-all-windows ()
  (let ((windows nil))
    (with-selected-window
      (dotimes (i (count-windows))
	(push (selected-window) windows)
	(other-window 1)))
    (nreverse windows)))

(defun scroll-forward-all-windows (&optional (dir 1))
  (interactive "p")
  (start-scrolling (list-all-windows) dir))

(defun scroll-backward-all-windows (&optional (dir 1))
  (interactive "p")
  (scroll-forward-all-windows (- dir)))

(defun auto-scroll-forward-all-windows (&optional (dir 1))
  (interactive "p")
  (let ((*friction* 0))
    (start-scrolling (list-all-windows) dir)))

(defun auto-scroll-backward-all-windows (&optional (dir 1))
  (interactive "p")
  (auto-scroll-forward-all-windows (- dir)))


;;; for mouse-wheel
;;
;; # 静止状態から
;;   n <= *wheel-scroll-threshold*  : 通常のスクロール (ed::mouse-wheel-scroll)
;;   n >  *wheel-scroll-threshold*  : 慣性スクロール開始
;;
;;   Shiftを押しながら回すと全ウィンドウをスクロール
;;
;; # 慣性スクロール中
;;   同方向回転  : 加速
;;   カウンター  : 停止


(defvar *wheel-scroll-threshold* 2)

(defun wheel-handler (window n lines)
  (let ((ws (if (< (si:get-key-state si:*vk-shift*) 0)
		(list-all-windows)
	      (list window))))
    (cond ((null *timer*)
	   (cond ((<= (abs n) *wheel-scroll-threshold*)
		  (dolist (w ws)
		    (ed::mouse-wheel-scroll w n lines)))
		 ((setq *this-command* 'wheel-scroll)
		  (start-scrolling ws n))))
	  ((= (timer-dir *timer*) (signum n))
	   (let ((*accel* (* (abs n) *accel*)))
	     (start-scrolling ws n)))
	  (t (stop-scrolling)))))

(defun enable-wheel-scroll ()
  (interactive)
  (setq ed:mouse-wheel-handler #'wheel-handler))

(defun disable-wheel-scroll ()
  (interactive)
  (setq ed:mouse-wheel-handler #'ed::mouse-wheel-scroll))
