
;;; #######################
;;; GLOBAL FLAGS
;;; #######################

;; Font for emacs
(defconst ehrax/font-family "Input Mono")

;; use spaces emacs
(setq-default tab-width 4 indent-tabs-mode nil)

;; dont make me type yes no, y/n will do
(defalias 'yes-or-no-p 'y-or-n-p)

;; Make sure UTF-8 is used
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment "UTF-8")

;; Highlight some keywords in prog-mode
(add-hook 'prog-mode-hook
          (lambda ()
            (font-lock-add-keywords nil
                                    '(("\\<\\(FIXME\\|TODO\\|BUG\\|DONE\\)" 1 font-lock-warning-face t)))))

;; From http://emacswiki.org/emacs/AutoSave
(setq
 backup-directory-alist `((".*" . ,temporary-file-directory))
 auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; Size of font
(defconst ehrax/font-size 130)

;; Font
(set-face-attribute 'default nil
                    :family ehrax/font-family :height ehrax/font-size :weight 'normal)
(set-face-attribute 'variable-pitch nil
                    :family ehrax/font-family :height ehrax/font-size :weight 'normal)
;; remove toolbar
(tool-bar-mode -1)

;; remove scrollbar
(scroll-bar-mode -1)

;; remove blinking cursor
(blink-cursor-mode -1)

;; current cursor line
(global-hl-line-mode t)


;; Show system name and full file path in emacs frame title
(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
            '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; Don't create lockfiles
(setq create-lockfiles nil)

;; Dont ask to follow symlink in git
(setq vc-follow-symlinks t)

;; just annoying emacs stuff
;; ------------------------

;; macOS smooth scrolling
(when (eq system-type 'darwin)
  (setq mouse-wheel-scroll-amount '(1))
  (setq mouse-wheel-progressive-speed nil))

;; bindign option to option key, and mac command to meta
(when (eq system-type 'darwin)
  (setq mac-option-modifier 'option
        mac-command-modifier 'meta))

;; shut up emacs
(setq ring-bell-function 'ignore)


;;; #######################
;;; GLOBAL KEYBINDING
;;; #######################

;; unconditionally kill unmodified buffers.
(global-set-key (kbd "C-x k") 'onc/kill-this-buffer-if-not-modified)

;; Revert buffer
(global-set-key [f5]
                (lambda ()
                  (interactive)
                  (revert-buffer nil t)
                  (message "Buffer reverted")))

;; Map escape to cancel (like C-g)..
(define-key isearch-mode-map [escape] 'isearch-abort) ;; isearch
(global-set-key [escape] 'keyboard-escape-quit) ;; everywhere else


;;; #######################
;;; PACKAGES
;;; #######################

;; boostrap package management
;; ----------------------------

(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("marmalade" . "https://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)


;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents) (package-install 'use-package))
(require 'use-package)
(setq use-package-verbose t)


;; Show column
(use-package fill-column-indicator
  :ensure t
  :init
  (add-hook 'c-mode-common-hook #'fci-mode)
  (add-hook 'mail-mode-hook #'fci-mode)
  (add-hook 'js2-mode-hook #'fci-mode)
  :config
  (setq fci-rule-width 1)
  (setq fci-rule-color "#ABB2BF")
  (setq-default fill-column 80))


;; no idea where this comes from...
(use-package unbound
  :ensure t)


;; OS X window support
(use-package ns-win
  :defer t
  :if (eq system-type 'darwin)
  :config
  (setq
   ;; Don't pop up new frames from the workspace
   ns-pop-up-frames nil))

;; Load shell env
(use-package exec-path-from-shell
  :ensure t
  :if (and (eq system-type 'darwin) (display-graphic-p))
  :config
  (setq exec-path-from-shell-variables
        '("PATH"))
  (exec-path-from-shell-initialize))


;; Fringe mode (left and right borders stuff)
(use-package fringe
  :init (fringe-mode '(5 . 0)))


;; install evil mode, vim + emacs
(use-package evil
  :ensure t
  :init
  (evil-mode t)

  ;; save on double escape, works best with escape mapped to caps-lock
  (add-hook 'evil-normal-state-entry-hook #'add-vim-bindings)

  :preface
  (defun save-with-escape-and-timeout ()
    "if no second escape is pressed in a given timeout, dont wait for a second escape."
    (interactive)
    (cl-block return-point
      (let ((timer (run-at-time "0.3 sec" nil (lambda () (return-from return-point))))
            (key (read-key)))
        (if (eq key 27)
            (progn
              (cancel-timer timer)
              (save-buffer))))))

  (defun add-vim-bindings()
    (define-key evil-normal-state-local-map (kbd "<escape>") 'save-with-escape-and-timeout))

  ;; unbind C-w from evil-window-map, so I can use it!
  (defun set-control-w-shortcuts ()
    (define-prefix-command 'onc-window-map)
    (global-set-key (kbd "C-w") 'onc-window-map)
    (define-key onc-window-map (kbd "h") 'evil-window-left)
    (define-key onc-window-map (kbd "j") 'evil-window-down)
    (define-key onc-window-map (kbd "k") 'evil-window-up)
    (define-key onc-window-map (kbd "l") 'evil-window-right)
    (define-key onc-window-map (kbd "|") 'split-window-right)
    (define-key onc-window-map (kbd "-") 'split-window-below)
    (define-key onc-window-map (kbd "x") 'delete-window)
    (define-key onc-window-map (kbd "o") 'delete-other-windows)
    (define-key onc-window-map (kbd "c") 'perspeen-create-ws)
    (define-key onc-window-map (kbd "n") 'perspeen-next-ws)
    (define-key onc-window-map (kbd "r") 'perspeen-rename-ws)
    (define-key onc-window-map (kbd "d") 'perspeen-delete-ws))

  :config
  ;; Some modes should not start in evil-mode
  (evil-set-initial-state 'paradox-menu-mode 'emacs)
  (evil-set-initial-state 'el-get-package-menu-mode 'emacs)
  (evil-set-initial-state 'ag-mode 'emacs)
  (evil-set-initial-state 'flycheck-error-list-mode 'emacs)
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'neotree-mode 'emacs)
  (evil-set-initial-state 'magit-popup-mode 'emacs)
  (evil-set-initial-state 'magit-mode 'emacs)
  (evil-set-initial-state 'pdf-view-mode 'emacs)
  (evil-set-initial-state 'pdf-annot-list-mode 'emacs)
  (evil-set-initial-state 'calendar-mode 'emacs)

  (use-package evil-leader
    :ensure t
    :init (global-evil-leader-mode)
    :config
    (evil-leader/set-leader "<SPC>")
    (evil-leader/set-key
      "f" 'onc/indent-whole-buffer
      "o" 'helm-find-files
      "b" 'helm-mini
      "p" 'helm-projectile
      "ci" 'evilnc-comment-or-uncomment-lines
      "cl" 'evilnc-quick-comment-or-uncomment-to-the-line
      "ll" 'evilnc-quick-comment-or-uncomment-to-the-line
      "cc" 'evilnc-copy-and-comment-lines
      "cp" 'evilnc-comment-or-uncomment-paragraphs
      "cr" 'comment-or-uncomment-region
      "cv" 'evilnc-toggle-invert-comment-line-by-line))

  (use-package evil-nerd-commenter
    :ensure t))

;; from: https://lists.ourproject.org/pipermail/implementations-list/2014-September/002064.html
(eval-after-load "evil-maps"
  '(dolist (map (list evil-motion-state-map
                      evil-insert-state-map
                      evil-emacs-state-map))
     (define-key map "\C-w" nil)
     (set-control-w-shortcuts)))


(use-package helm
  :ensure t
  :bind (("C-h C-h" . helm-apropos)
         ("M-x" . helm-M-x)
         ("C-x b" . helm-mini)
         ("C-x C-f" . helm-find-files)
         :map helm-map
         ("<tab>" . helm-execute-persistent-action)
         ("C-i" . helm-execute-peRsistent-action)
         ("C-j" . helm-select-action)
         ("M-j" . helm-next-line)
         ("M-k" . helm-previous-line))
  :config
  (require 'helm-config)
  (helm-mode +1)

  ;; Ignore .DS_Store files with helm mode
  (add-to-list 'helm-boring-file-regexp-list "\\.DS_Store$")
  (setq helm-ff-skip-boring-files t)

  ;; Fuzzy matching
  (setq helm-mode-fuzzy-match t)
  (setq helm-completion-in-region-fuzzy-match t)

  (setq helm-ff-file-name-history-use-recentf t)

  (setq helm-reuse-last-window-split-state t)
  ;; Don't use full width of the frame

  (setq helm-split-window-in-side-p t)
  (helm-autoresize-mode t)
  (use-package helm-projectile
    :ensure t
    :init (helm-projectile-on)
    :config
    (setq projectile-completion-system 'helm)))


;; Projects in emacs
(use-package projectile
  :ensure t
  :init (projectile-mode t))


;; show git modification
(use-package git-gutter
  :ensure t
  :diminish git-gutter-mode
  :init (global-git-gutter-mode +1)
  :config
  ;; hide if there is no change)
  (setq git-gutter:hide-gutter t)
  (use-package git-gutter-fringe
    :ensure t
    :config
    ;; colored fringe "bars"
    (define-fringe-bitmap 'git-gutter-fr:added
      [224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224]
      nil nil 'center)
    (define-fringe-bitmap 'git-gutter-fr:modified
      [224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224]
      nil nil 'center)
    (define-fringe-bitmap 'git-gutter-fr:deleted
      [0 0 0 0 0 0 0 0 0 0 0 0 0 128 192 224 240 248]
      nil nil 'center))


  ;; Refreshing git-gutter
  (advice-add 'evil-force-normal-state :after 'git-gutter)
  (add-hook 'focus-in-hook 'git-gutter:update-all-windows))

;; rainbow colors for delimiters
(use-package rainbow-delimiters
  :ensure t
  :diminish rainbow-delimiters-mode
  :init (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

;; colors for emacs if a color is enterd
(use-package rainbow-mode
  :ensure t
  :diminish (rainbow-mode . "🌈")
  :init
  (dolist
      (hook '(css-mode-hook
              html-mode-hook
              js-mode-hook
              emacs-lisp-mode-hook
              text-mode-hook))
    (add-hook hook #'rainbow-mode)))


;;' better emacs package menu
(use-package paradox
  :commands (paradox-list-packages)
  :config
  (setq paradox-automatically-star nil
        paradox-display-star-count nil
        paradox-execute-asynchronously t))


(use-package perspeen
  :ensure t
  :config
  (perspeen-mode t))


;; spaceline does need powerline
(use-package powerline
  :ensure t
  :config
  (setq powerline-height (truncate (* 1.0 (frame-char-height)))))


;; Mode line config
(use-package spaceline-config
  :ensure spaceline
  :config
  (setq powerline-default-separator nil)
  (spaceline-spacemacs-theme)
  (spaceline-helm-mode))


;; color-theme
(use-package atom-one-dark-theme
  :ensure t)


;; closes elecs
(use-package elec-pair
  :ensure t
  :init (electric-pair-mode t))


;; auto compilation engine
(use-package company
  :ensure t
  :init (global-company-mode t)
  :bind (:map company-active-map
              ("M-j" . company-select-next)
              ("M-k" . company-select-previous))
  :config
  (setq company-idle-delay 0
        copmany-minimum-prefix-length 2
        company-tooltip-limit 20)
  ;; sort company canidate by statistics
  (use-package company-statistics
    :ensure t
    :config (company-statistics-mode))

  (use-package company-emoji
    :ensure t
    :init (add-to-list 'company-backends 'company-emoji)))


(use-package mode-icons
  :ensure t
  :init (mode-icons-mode))


;; On-the-fly syntax checking
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode t)
  :diminish flycheck-mode)


(use-package ruby-mode
  :mode "\\.rb\\'"
  :interpreter "ruby"
  :bind(:map
        ruby-mode-map
        ("C-c r" . onc/run-current-file))
  :config
  (use-package rubocop
    :ensure t
    :init (add-hook 'ruby-mode-hook #'rubocop-mode))
  (use-package inf-ruby
    :ensure t
    :init
    (add-hook 'ruby-mode-hook #'inf-ruby-minor-mode)
    (add-hook 'compilation-filter-hook #'inf-ruby-auto-enter))

  (use-package company-inf-ruby
    :ensure t
    :config (add-to-list 'company-backends 'company-inf-ruby)))


;; Python
(use-package phyton
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode)
  :config
  (use-package elpy
    :config
    (setq elpy-rpc-backend "jedi"
          eply-modules (delq 'elpy-module-company elpy-modules))

    (add-hook 'python-mode-hook
              (lambda ()
                (company-mode)
                (add-to-list 'company-backends
                             (company-mode/backend-with-yes 'elpy-company-backend))))
    (elpy-use-cpython)))


;; JavascriptA
(use-package js2-mode
  :mode "\\.js\\'"
  :config
  (setq-default js2-global-externs '("exports" "module" "requre" "setTimeout" "THERE"))
  (setq-default js2-basic-offset 2)

  (use-package tern
    :defer t
    :init
    (add-hook 'js-mode-hook (lambda () (tern-mode t)))
    (add-hook 'js2-mode-hook (lambda () (tern-mode t)))
    (add-hook 'web-mode-hook (lambda () (tern-mode t)))

    :config
    (use-package company-tern
      :ensure t
      :config
      (add-to-list 'company-backends 'company-tern))))


;; zsh - file
(use-package sh-script
  :mode (("\\.zsh\'" . sh-mode)
         ("\\zshrc\\'" . sh-mode)))


;; scss
(use-package scss-mode
  :mode "\\.scss\\'")


;; ngnix config file
(use-package nginx-mode
  :ensure t)


;; Yaml files
(use-package yaml-mode
  :mode (("\\.yml\\'" . yaml-mode)
         ("\\.yaml\\'" . yaml-mode)))


;; Markdown files
(use-package markdown-mode
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.mmd\\'" . markdown-mode))
  :init
  (add-hook 'markdown-mode-hook #'orgtbl-mode)
  (add-hook 'markdown-mode-hook
            (lambda()
              (add-hook 'after-save-hook 'org-tables-to-markdown  nil 'make-it-local))))


;; Web-Mode for html, php and the like
(use-package web-mode
  :ensure t
  :mode (("\\.html?\\'" . web-mode)
         ("\\.php\\'"   . web-mode)
         ("\\.jsp\\'"   . web-mode)
         ("\\.erb\\'"   . web-mode))
  :config
  (setq web-mode-markup-indent-offset 2
                 web-mode-css-indent-offset 2
                 web-mode-code-indent-offset 2))


;; Support for AsciiDoc
(use-package adoc-mode
  :ensure t)


;; Gradle-files
(use-package gradle-mode
  :mode "\\.gradle\\'")


;; Json-files
(use-package json-mode
  :mode "\\.json\\'"
  :config (validate-setq js-indent-level 2))

;; #########################################################################
;; custom funcitons
;; #########################################################################

(defun onc/indent-whole-buffer ()
  "Delete trailing whitespace, indent and untabify whole buffer."
  (interactive)
  (save-excursion
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max))))

(defun onc/kill-this-buffer-if-not-modified ()
  "Kill current buffer, even if it has been modified."
  (interactive)
  (kill-buffer (current-buffer)))

(defun onc/run-current-file ()
  "Execute or compile the current file.
For example, if the current buffer is the file x.pl,
then it'll call “perl x.pl” in a shell.
The file can be php, perl, python, ruby, javascript, bash, ocaml, vb, elisp.
File suffix is used to determine what program to run.
If the file is modified, ask if you want to save first.
This command always run the saved version.
If the file is Emacs Lisp, run the byte compiled version if exist."
  (interactive)
  (let (suffixMap fName fSuffix progName cmdStr)

    ;; a keyed list of file suffix to comand-line program path/name
    (setq suffixMap
          '(("php" . "php")
            ("py" . "python")
            ("rb" . "ruby")
            ("js" . "node")
            ("sh" . "bash")))
    (setq fName (buffer-file-name))
    (setq fSuffix (file-name-extension fName))
    (setq progName (cdr (assoc fSuffix suffixMap)))
    (setq cmdStr (concat progName " \""   fName "\""))

    (when (buffer-modified-p)
      (progn
        (when (y-or-n-p "Buffer modified.  Do you want to save first? ")
          (save-buffer) ) ) )

    (if (string-equal fSuffix "el") ; special case for emacs lisp
        (progn
          (load (file-name-sans-extension fName)))
      (if progName
          (progn
            (message "Running…")
            ;; (message progName)
            (shell-command cmdStr "*run-current-file output*" ))
        (message "No recognized program file suffix for this file.")))))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("b884b0d909331aabeb6fec49689616ae49337077d856deda0b752899a58b8d0d" "a1fbb0512cc582cba9bd64a5f6db7de28b6fed669f812a74e493629f90c40dbd" "6d607cd6deb11df7918837fd968be9784b7a7fb8b3ff4babb6e9926786236a6c" "79a390152f279cd1497dca1df4d5ce38954ded2514528f72507d3d36ce9622a4" "71b8cc4938979cd45b85e5bb093d9a6469f6e8411721cf1d0ab3dbe8c6621a88" "2f8ba687be16aef113a9df8c4d732d54bbee7872c5466724b7ace02e1c610da5" "37dccf8a0ebe3f6a5d98ee5b76279ab7e1baf90ea55f633a906cd0afa77ddd7b" "55622c7c594c3c5891743734e50cd4ab9bc51c6f337c6c0f9a16a97f169fc3e8" "971cb0c644c20576cd0c500b3c816fd9dbffcdd53f84b5ba06a92396c7d31ba8" "c1b6c3df45ac4a853467712574fb82e501ec2a50d5554b2cf89164a0d63e37e6" "b70e65879f3c1ec1554b99dc4c029922989f818096e111378083e0471dc7181f" default)))
 '(fci-rule-color "#3E4451")
 '(package-selected-packages
   (quote
    (fill-column-indicator json-mode gradle-mode adoc-mode nxml-mode web-mode markdown-mode yaml-mode nginx-mode scss-mode company-tern tern js2-mode elpy paradox git-gutter-finge git-gutter-fringe git-gutter helm-projectile projectile company-inf-ruby inf-ruby flycheck exec-path-from-shell rubocop evil-search-highlight-persist rainbow-mode unbound company-emoji mode-icons company-statistics company atom-one-dark-theme spaceline perspeen rainbow-delimiters helm evil-leader evil use-package)))
 '(paradox-github-token t))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
