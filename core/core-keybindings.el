;;; core-keybindings.el --- Spacemacs Core File
;;
;; Copyright (c) 2012-2014 Sylvain Benner
;; Copyright (c) 2014-2015 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(require 'core-funcs)

(defvar spacemacs/prefix-titles nil
  "alist for mapping command prefixes to long names.")

(defvar spacemacs-default-map (make-sparse-keymap)
  "Base keymap for all spacemacs leader key commands.")

(defun spacemacs/translate-C-i (_)
  "If `dotspacemacs-distinguish-gui-tab' is non nil, the raw key
sequence does not include <tab> or <kp-tab>, and we are in the
gui, translate to [C-i]. Otherwise, [9] (TAB)."
  (interactive)
  (if (and (not (cl-position 'tab (this-single-command-raw-keys)))
           (not (cl-position 'kp-tab (this-single-command-raw-keys)))
           dotspacemacs-distinguish-gui-tab
           (display-graphic-p))
      [C-i] [?\C-i]))
(define-key key-translation-map [?\C-i] 'spacemacs/translate-C-i)

;; (defun spacemacs/translate-C-m (_)
;;   "If `dotspacemacs-distinguish-gui-ret' is non nil, the raw key
;; sequence does not include <ret>, and we are in the gui, translate
;; to [C-m]. Otherwise, [9] (TAB)."
;;   (interactive)
;;   (if (and
;;        (not (cl-position 'return (this-single-command-raw-keys)))
;;        (not (cl-position 'kp-enter (this-single-command-raw-keys)))
;;        dotspacemacs-distinguish-gui-ret
;;        (display-graphic-p))
;;     [C-m] [?\C-m]))
;; (define-key key-translation-map [?\C-m] 'spacemacs/translate-C-m)

(defun spacemacs/declare-prefix (prefix name &optional long-name)
  "Declare a prefix PREFIX. PREFIX is a string describing a key
sequence. NAME is a string used as the prefix command.
LONG-NAME if given is stored in `spacemacs/prefix-titles'."
  (let* ((command name)
         (full-prefix (concat dotspacemacs-leader-key " " prefix))
         (full-prefix-emacs (concat dotspacemacs-emacs-leader-key " " prefix))
         (full-prefix-lst (listify-key-sequence (kbd full-prefix)))
         (full-prefix-emacs-lst (listify-key-sequence
                                 (kbd full-prefix-emacs))))
    ;; define the prefix command only if it does not already exist
    (unless long-name (setq long-name name))
    (which-key-declare-prefixes
      full-prefix-emacs (cons name long-name)
      full-prefix (cons name long-name))))

(defun spacemacs/declare-prefix-for-mode (mode prefix name &optional long-name)
  "Declare a prefix PREFIX. MODE is the mode in which this prefix command should
be added. PREFIX is a string describing a key sequence. NAME is a symbol name
used as the prefix command."
  (let  ((command (intern (concat (symbol-name mode) name)))
         (full-prefix (concat dotspacemacs-leader-key " " prefix))
         (full-prefix-emacs (concat dotspacemacs-emacs-leader-key " " prefix))
         (is-major-mode-prefix (string-prefix-p "m" prefix))
         (major-mode-prefix (concat dotspacemacs-major-mode-leader-key
                                    " " (substring prefix 1)))
         (major-mode-prefix-emacs
          (concat dotspacemacs-major-mode-emacs-leader-key
                  " " (substring prefix 1))))
    (unless long-name (setq long-name name))
    (let ((prefix-name (cons name long-name)))
      (which-key-declare-prefixes-for-mode mode
        full-prefix-emacs prefix-name
        full-prefix prefix-name)
      (when (and is-major-mode-prefix dotspacemacs-major-mode-leader-key)
        (which-key-declare-prefixes-for-mode mode major-mode-prefix prefix-name))
      (when (and is-major-mode-prefix dotspacemacs-major-mode-emacs-leader-key)
        (which-key-declare-prefixes-for-mode
          mode major-mode-prefix-emacs prefix-name)))))

(defun spacemacs/set-leader-keys (key def &rest bindings)
  "Add KEY and DEF as key bindings under
`dotspacemacs-leader-key' and `dotspacemacs-emacs-leader-key'.
KEY should be a string suitable for passing to `kbd', and it
should not include the leaders. DEF is most likely a quoted
command. See `define-key' for more information about the possible
choices for DEF. This function simply uses `define-key' to add
the bindings.

For convenience, this function will accept additional KEY DEF
pairs. For example,

\(spacemacs/set-leader-keys
   \"a\" 'command1
   \"C-c\" 'command2
   \"bb\" 'command3\)"
  (while key
    (define-key spacemacs-default-map (kbd key) def)
    (setq key (pop bindings) def (pop bindings))))
(put 'spacemacs/set-leader-keys 'lisp-indent-function 'defun)

(defalias 'evil-leader/set-key 'spacemacs/set-leader-keys)

(defun spacemacs//init-leader-mode-map (mode map &optional minor)
  "Check for MAP-prefix. If it doesn't exist yet, use `bind-map'
to create it and bind it to `dotspacemacs-major-mode-leader-key'
and `dotspacemacs-major-mode-emacs-leader-key'. If MODE is a
minor-mode, the third argument should be non nil."
  (let ((prefix (intern (format "%s-prefix" map))))
    (or (boundp prefix)
        (progn
          (eval
           `(bind-map ,map
              :prefix-cmd ,prefix
              ,(if minor :minor-modes :major-modes) (,mode)
              :keys (,dotspacemacs-major-mode-emacs-leader-key
                     ,(concat dotspacemacs-emacs-leader-key
                              (unless minor " m")))
              :evil-keys (,dotspacemacs-major-mode-leader-key
                          ,(concat dotspacemacs-leader-key
                                   (unless minor " m")))))
          (boundp prefix)))))

(defun spacemacs/set-leader-keys-for-major-mode (mode key def &rest bindings)
  "Add KEY and DEF as key bindings under
`dotspacemacs-major-mode-leader-key' and
`dotspacemacs-major-mode-emacs-leader-key' for the major-mode
MODE. MODE should be a quoted symbol corresponding to a valid
major mode. The rest of the arguments are treated exactly like
they are in `spacemacs/set-leader-keys'."
  (let* ((map (intern (format "spacemacs-%s-map" mode))))
    (when (spacemacs//init-leader-mode-map mode map)
      (while key
        (define-key (symbol-value map) (kbd key) def)
        (setq key (pop bindings) def (pop bindings))))))
(put 'spacemacs/set-leader-keys-for-major-mode 'lisp-indent-function 'defun)

(defalias
  'evil-leader/set-key-for-mode
  'spacemacs/set-leader-keys-for-major-mode)

(defun spacemacs/set-leader-keys-for-minor-mode (mode key def &rest bindings)
  "Add KEY and DEF as key bindings under
`dotspacemacs-major-mode-leader-key' and
`dotspacemacs-major-mode-emacs-leader-key' for the minor-mode
MODE. MODE should be a quoted symbol corresponding to a valid
minor mode. The rest of the arguments are treated exactly like
they are in `spacemacs/set-leader-keys'."
  (let* ((map (intern (format "spacemacs-%s-map" mode))))
    (when (spacemacs//init-leader-mode-map mode map t)
      (while key
        (define-key (symbol-value map) (kbd key) def)
        (setq key (pop bindings) def (pop bindings))))))
(put 'spacemacs/set-leader-keys-for-minor-mode 'lisp-indent-function 'defun)

(provide 'core-keybindings)
