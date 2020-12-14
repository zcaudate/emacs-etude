;;
;;  ETUDE CORE WORKFLOW
;;
;;  This package standardizes actions and the etude menu system. All global
;;  keybindings as well as menus are defined. `:keyword`s are used to specify
;;  the action performed. The action is associated with keybindings and a function
;;  definition. Menus are then created from actions. This results in a cleaner
;;  way of configuring the emacs environment.
;;
;;  The menu system is based on a number system, as opposed to a letter abbreviation
;;  system. It follows something like an automated phone directory to assist
;;  the user in picking the right choice. The aim is to simplify movement and order
;;  functionality, not merely to overwhelm the user with options.
;;
;;  - Global                           [quit, menu]
;;  - Editing                          [cut, copy, paste, undo]
;;  - Function Keys        (F1-12)
;;  - Window Management    (M-`)       
;;  - File Management      (M-1)       [open, save, close, quit]
;;  - Navigation           (M-2)       [goto, jump, mark]
;;  - Mode Specific        (M-3)       
;;  - Project Management   (M-4)       [find, replace, bulk find, bulk replace] 
;;  - Code Management      (M-5)       [history, status, commit, push]
;;  - App Management       (M-9)       [eshell]
;;  - Config Management    (M-0)       [jump to config]

(ns: etude-core-workflow
  (:require
   etude-core-base
   etude-core-code
   etude-core-management))

;;
;; (GLOBAL)
;;

(defun on/no-action ()
  (interactive))

(on/bind: []
  ::no-action       ()               'on/no-action
  ::main-menu       ("C-p")          'counsel-M-x
  ::help-bind-key   ("C-c C-h")      'describe-key
  ::quit            ("M-q")          'save-buffers-kill-terminal)

;;
;; (EDITING)
;;

(defun on/just-one-space ()
  "Delete all spaces and tabs around point, leaving one space (or N spaces).
If N is negative, delete newlines as well, leaving -N spaces.
See also `cycle-spacing'."
  (interactive)
  (cycle-spacing -1 nil 'single-shot))

(on/bind: []
  ::cut             ("C-o")             'kill-region
  ::trim            ()                  'on/just-one-space
  ::copy            ("C-x C-o")         'copy-region-as-kill
  ::cut-context     ("C-k")             'paredit-kill
  ::copy-context    ("C-x C-k")         'on/paredit-copy-as-kill
  ::paste           ("C-v" "M-v")       'yank
  ::paste-menu      ("C-x v")           'counsel-yank-pop
  ::undo            ("C--" "M--")       'undo
  ::undo-menu       ("C-x -")           'undo-tree-visualize
  ::redo            ("C-x C-")          'undo-tree-redo
  ::comment         ("C-;")             'comment-dwim)

;;
;; (F1) File and Buffer Management
;;

(defun on/close-buffer ()
  (interactive)
  (if (buffer-file-name (current-buffer))
      (save-buffer))
  (kill-buffer (current-buffer)))

(defun on/close-all-buffers ()
  (interactive)
  (save-some-buffers)
  (mapc 'kill-buffer (buffer-list)))

(defun on/last-used-buffer ()
  (interactive)
  (switch-to-buffer (other-buffer)))

(defun on/revert-buffer ()
  (interactive)
  (revert-buffer :ignore-auto :noconfirm)
  (message "Buffer reverted"))

(defun on/jump-workflow ()
  (interactive)
  (find-library "etude-core-workflow"))

(on/bind: []
  ::open              ()                    'find-file
  ::open-recent       ()                    'on/ivy-recentf-file
  ::open-project      ("M-t" "C-t" "s-t")   'projectile-find-file
  ::revert            ("C-x r" "C-x C-r")   'on/revert-buffer
  ::save              ("C-s" "M-s")         'save-buffer
  ::save-as           ()                    'write-file
  ::save-all          ()                    'save-some-buffers
  ::close             ("C-c 9" "C-c C-9")   'on/close-buffer
  ::close-select      ("C-c k" "C-c C-k")   'kill-buffer  
  ::close-all         ()                    'on/close-all-buffers
  ::last-used-buffer  ("C-\\" "M-\\")       'on/last-used-buffer
  ::prev-buffer       ("C-x C-<left>" "C-x <left>")         'previous-buffer
  ::next-buffer       ("C-x C-<right>" "C-x <right>")         'next-buffer
  ::jump-buffer       ("C-r")               'counsel-buffer-or-recentf
  ::jump-test         ()                    'projectile-find-test-file
  ::locate-project    ("C-c C-r" "C-c r")   'on/neotree-projectile-root
  ::toggle-project    ("C-c C-0" "C-c 0")   'on/neotree-toggle
  ::locate-file       ("C-c C-l" "C-c l")   'on/neotree-projectile-locate)

(on/menu: [::file-menu ("<f1>")]
  "
  ^File^            ^Open^                ^Save^            ^Close^
  _1_: save all     _4_: open             _6_: save         _8_: close 
  _2_: close all    _5_: open recent      _7_: save as      _q_: quit emacs
  _3_: open file in project
  "
  ("1" ::save-all     "save all")
  ("2" ::close-all    "close all")
  ("3" ::open-project "open file in project")
  ("4" ::open         nil :exit true)
  ("5" ::open-recent  nil :exit true)
  ("6" ::save)
  ("7" ::save-as)
  ("8" ::close)
  ("q" ::quit         "quit emacs")
  ("x" ::do-nothing   "exit" :exit t))

;;
;; (F2) Window Management
;;

(defun on/window-list ()
  (seq-filter (lambda (w) 
                (not (equal (buffer-name (window-buffer w))
		            " *NeoTree*")))
              (window-list)))

(defun on/window-alternate ()
  (seq-find (lambda (w)
              (not (equal w (selected-window))))
            (on/window-list)))

(defun on/window-set-buffer (w buff)
  (save-selected-window
    (select-window w)
    (switch-to-buffer buff)))

(defun on/split-window-toggle ()
  (interactive)
  (let: [cnt  (seq-length (on/window-list))]
    (cond ((equal cnt 1)
	   (progn (split-window-below)
                  (on/window-set-buffer (on/window-alternate)
                                        (other-buffer 1))))
          
          ((not (window-full-height-p))
           (progn (delete-other-windows)
                  (split-window-right)
                  (on/window-set-buffer (on/window-alternate)
                                        (other-buffer 1))))
          (:else
           (delete-other-windows)))))

(defun on/window-delete ()
  (interactive)
  (delete-other-windows)
  (on/close-buffer))

(on/bind: []
  ::window-delete        ("M-`")                         'on/window-delete
  ::window-close         ("C-x C-<down>" "C-x <down>")   'delete-window      
  ::window-focus         ("C-x C-<up>" "C-x <up>")       'delete-other-windows
  ::window-split-left    ()                     nil
  ::window-split-right   ()                     'split-window-right
  ::window-split-top     ()                     nil
  ::window-split-bottom  ()                     'split-window-below
  ::window-split-toggle  ("M-w")                'on/split-window-toggle
  ::window-move-left     ("<C-S-left>" "<M-left>"  "ESC <left>")     'windmove-left
  ::window-move-right    ("<C-S-right>" "<M-right>" "ESC <right>")    'windmove-right
  ::window-move-up       ("<C-S-up>" "<M-up>" "ESC <up>")          'windmove-up
  ::window-move-down     ("<C-S-down>" "<M-down>" "ESC <down>")     'windmove-down
  ::window-balance       ()                     'balance-windows
  ::window-swap          ()                     'ace-swap-window
  ::window-h-plus        ()                     'enlarge-window-horizontally
  ::window-h-minus       ()                     'shrink-window-horizontally
  ::window-v-plus        ()                     'enlarge-window
  ::window-v-minus       ()                     'shrink-window
  ::window-grow-font     ()                     nil
  ::window-shrink-font   ()                     nil)

(on/menu: [::window-menu  ("<f2>")]
  "
  ^Position^                  ^Manage^                    Resize      
  _1_: window focus           _o_: swap                   _<up>_
  _2_: window split h         _w_: toggle           _<left>_    _<right>_    
  _3_: window split v         _d_: window close          _<down>_
  _4_: balance windows        _9_: shrink font         _0_: grow font
  "
  ("1" ::window-focus "window focus")
  ("2" ::window-split-bottom)
  ("3" ::window-split-right)
  ("4" ::window-balance)
  ("9" ::window-shrink-font)
  ("0" ::window-grow-font)
  ("o" ::window-swap "window swap")
  ("w" ::window-split-toggle)
  ("d" ::window-close  "window close")
  ("<left>"  ::window-h-minus)
  ("<up>"    ::window-v-minus)
  ("<down>"  ::window-v-plus)
  ("<right>" ::window-h-plus)
  ("x" ::do-nothing "exit" :exit t))

;;
;; (F3) Meta Options
;;
;; This is reserved for minor modes to setup their own `jump-to-<LANG>-config' entry
;;

(require 'find-func)

(setq on/*back-buffer* nil)

(defun on/jump-to-config (library)
  (setq on/*back-buffer* (current-buffer))
  (find-library library))

(defun on/jump-to-workflow ()
  (interactive)
  (setq on/*back-buffer* (current-buffer))
  (find-library "etude-core-workflow"))

(defun on/jump-back ()
  (interactive)
  (when on/*back-buffer*
    (switch-to-buffer on/*back-buffer*)
    (setq on/*back-buffer* nil)))

(on/bind: []
  ::describe-key       ("<f5>") 'describe-key
  ::describe-bindings  ()       'describe-bindings
  ::line-count         ()       'count-lines-page
  ::settings-workflow  ()       'on/jump-to-workflow
  ::settings-back      ()       'on/jump-back)

(on/menu: [::jump-menu ("<f3>")]
  "
  ^Describe^        ^Config^            ^Stats^
  _1_: key          _w_: workflow       _6_: line count
  _2_: bindings     _b_: back
  "
  ("1" ::describe-key "key" :exit t)
  ("2" ::describe-bindings "bindings" :exit t)
  ("w" ::settings-workflow :exit t)
  ("b" ::settings-back :exit t)
  ("6" ::line-count)
  ("x" ::do-nothing  "exit" :exit t))

;;
;; (F4) Project Management
;;

(on/bind: []
  ::goto-line           ("C-c C-g" "C-c g")    'goto-line
  ::goto-start          ("C-c C-<up>" "C-c <up>")       'beginning-of-buffer
  ::goto-end            ("C-c C-<down>" "C-c <down>")   'end-of-buffer
  ::find                ("C-c C-s" "C-c s")  'swiper
  ::search-backward     ()             'isearch-backward
  ::search-forward      ()             'isearch-forward
  ::replace             ()             nil
  ::find-in-project     ("C-x C-s" "C-x s")    'counsel-ag
  ::replace-in-project  ()             nil
  ::find-in-os          ()             nil) 

(on/menu: [::search-menu  ("<f4>")]
  "
  ^Goto^            
  _1_: find             _4_: find in project
  _2_: goto top
  _3_: goto bottom
  _4_: goto line
  "
  ("1" ::find)
  ("2" ::search-backward)
  ("3" ::search-forward)
  ("4" ::find-in-project)
  ("x" ::do-nothing   "exit" :exit t))

;;
;; (M-5) Code Management
;;

(on/bind: []
  ::git-status         ()             'magit-status
  ::git-doall          ()             'on/magit-add-commit-push
  ::git-rebase         ()             'magit-rebase
  ::git-commit         ()             'magit-commit
  ::git-push           ()             'magit-push
  ::git-log            ()             'magit-log)

(on/menu: [::git-menu ("M-5")]
  "
  ^Basic^                           ^Advanced^
  _1_: git status
  _2_: git add, commit, push
  _3_: git log
  "
  ("1" ::git-status   "git status")
  ("2" ::git-doall    "git add, commit, push")
  ("3" ::git-log      "git log")
  ("x" ::do-nothing   "exit" :exit t))


;;
;; (M-6) Container Management
;;

(on/bind: []
  ::docker-ps          ()             'docker)

(on/menu: [::docker-menu ("M-6")]
  "
  ^Basic^                           ^Advanced^
  _1_: docker-ps
  "
  ("1" ::docker-ps)
  ("x" ::do-nothing   "exit" :exit t))


;;
;; (M-8) Language Specific
;; 
;; This is reserved for the given language minor mode to provide
;; functionality that is specific working within the language.
;; Usually done for tutorial/walk-through/late-night-brain-dead
;; programming to show common options that a user might be able to use.
;;
;;   - emacs lisp
;;   - java
;;   - clojure
;;   - rust
;;   - c/c++
;;   - verilog
;;   - html/css
;;   - javascript

(on/mode-init: []
  ::eval-cursor        ("C-e")   ("P")
  ::eval-file          ("M-e" "C-x e" "C-x C-e")   ()
  ::init               ("M-c")   ())

(on/menu: [::lang-menu  ("<f8>")]
  "
  ^Code^            
  _1_: run          
  _2_: test      
  _3_: connect/compile
  _4_: eval file
  "
  ("1" ::run)
  ("2" ::test)
  ("3" ::init         "connect/compile")
  ("4" ::eval-file)
  ("x" ::do-nothing   "exit" :exit t))

;;
;; (M-9) OS Management 
;;

(defun on/jump-to-buffer (bname command &rest args)
  (if (not (equal (buffer-name (current-buffer))
                  bname))
      (funcall 'apply command args)
    (previous-buffer)))

(defun on/jump-to-eshell ()
  (interactive)
  (on/jump-to-buffer "*eshell*" 'eshell))

(defun on/jump-to-start-screen ()
  (interactive)
  (on/jump-to-buffer "*dashboard*" 'on/start-screen))

(defun on/jump-to-scratch ()
  (interactive)
  (on/jump-to-buffer "*scratch*" (lambda () (switch-to-buffer "*scratch*"))))

(on/bind: []
  ::toggle-eshell          ("M-1")                      'on/jump-to-eshell
  ::toggle-dashboard       ("M-2")                      'on/jump-to-start-screen
  ::toggle-scratch         ("M-3")                      'on/jump-to-scratch
  ::toggle-workflow        ("M-4")                      'on/jump-to-workflow
  ::toggle-magit           ("M-5")                      'magit)

(on/menu: [::os-menu ("<f9>")]
  "
  ^OS^                      
  _1_: toggle eshell         _4_: toggle workflow
  _2_: toggle dashboard      _5_: toggle git
  _3_: toggle scratch
  "
  ("1" ::toggle-eshell)
  ("2" ::toggle-dashboard)
  ("3" ::toggle-scratch)
  ("4" ::toggle-workflow)
  ("5" ::toggle-magit)
  ("x" ::do-nothing   "exit" :exit t))

