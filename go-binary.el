;;; go-binary.el --- Install and update all necessary Go tool binaries

;; Copyright (C) 2018 Brantou

;; Author: Brantou <brantou89@gmail.com>
;; URL: https://github.com/brantou/go-binary.el
;; Keywords: tools
;; Version: 0.1.0
;; Package-Requires: ()

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; `go-binary.el'  install and update all necessary go tool binaries for Go language.
;;

;;; Code:

(defgroup go-binary nil
  "Install and update all necessary Go tool binaries."
  :prefix "go-binary-"
  :link '(url-link :tag "MELPA" "https://melpa.org/#/go-binary")
  :link '(url-link :tag "MELPA Stable" "https://stable.melpa.org/#/go-binary")
  :link '(url-link :tag "GitHub" "https://github.com/brantou/go-binary.el")
  :group 'go)

(defcustom go-binary--insert-cmd-prefix "go get "
  "Go get [packages]."
  :type 'string
  :group 'go-binary
  :safe 'stringp)

(defcustom go-binary--update-cmd-prefix "go get -u "
  "Go get -u [packages]."
  :type 'string
  :group 'go-binary
  :safe 'stringp)

(defcustom go-binary--buffer-name "*go-binary-output*"
  "Default buffer name for go-binary."
  :type 'string
  :group 'go-binary
  :safe 'stringp)

(defcustom go-binary-packages
  '((go-mode '("github.com/rogpeppe/godef"
               "github.com/mdempsky/gocode"
               "golang.org/x/tools/cmd/goimports"
               "github.com/zmb3/gogetdoc"))
    (go-guru '("golang.org/x/tools/cmd/guru"))
    (go-rename '("golang.org/x/tools/cmd/gorename"))
    (go-eldoc '("github.com/mdempsky/gocode"))
    (company-go '("github.com/mdempsky/gocode"))
    (godoctor '("github.com/godoctor/godoctor"))
    (go-tag '("github.com/fatih/gomodifytags"))
    (go-fill-struct '("github.com/davidrjenni/reftools/cmd/fillstruct"))
    (go-impl '("github.com/josharian/impl"))
    (go-imenu '("github.com/lukehoban/go-outline"))
    (go-gen-test '("github.com/cweill/gotests/..."))
    (flycheck-gometalinter '("github.com/alecthomas/gometalinter"))
    (flycheck-golangci-lint '("github.com/golangci/golangci-lint/cmd/golangci-lint")))
  "The keyword of the associated list can be the package name or the name of the function in the package that uses the autoload annotation."
  :type '(alist :value-type (group list))
  :group 'go-binary)

;;; gen function
(defun go-binary--gen-install-cmds ()
  "Gen install cmds."
  (go-binary--gen-cmds go-binary--update-cmd-prefix))

(defun go-binary--gen-update-cmds ()
  "Gen update cmds."
  (go-binary--gen-cmds go-binary--update-cmd-prefix))

(defun go-binary--gen-cmds (cmd-prefix)
  "Gen cmds."
  (let (cmds)
    (mapc (lambda(entry)
            (let ((pkg (car entry))
                  (deps (cadr entry)))
              (when (or (featurep pkg) (fboundp pkg))
                (mapc (lambda(dep)
                        (when (listp dep)
                          (mapc (lambda(x)
                                  (push (concat cmd-prefix x) cmds))
                                dep)))
                      deps))))
          go-binary-packages)
    (delete-dups cmds)))

;;;###autoload
(defun go-binary-install()
  "Install go tool binaries."
  (interactive)
  (with-current-buffer
      (get-buffer-create go-binary--buffer-name)
    (erase-buffer))
  (message "start to install go tool binaries.")
  (apply 'go-binary--exec-cmds
         (append (list go-binary--buffer-name)
                 (go-binary--gen-install-cmds))))

;;;###autoload
(defun go-binary-update()
  "Update go tool binaries."
  (interactive)
  (with-current-buffer
      (get-buffer-create go-binary--buffer-name)
    (erase-buffer))
  (message "start to update go tool binaries.")
  (apply 'go-binary--exec-cmds
         (append (list go-binary--buffer-name)
                 (go-binary--gen-update-cmds))))

;;; asyn function
(defun go-binary--exec-cmds (buffer &rest cmds)
  "Exec a list of shell cmds sequentially."
  (with-current-buffer buffer
    (set (make-local-variable 'go-binary--cmds-list) cmds)
    (go-binary--start-next-cmd)))

(defun go-binary--start-next-cmd ()
  "Run the first cmd in the list."
  (if (null go-binary--cmds-list)
      (progn (insert "\nDone.")
             (message "Complete the installation of the go tool binaries."))
    (let ((cmd  (car go-binary--cmds-list)))
      (setq go-binary--cmds-list (cdr go-binary--cmds-list))
      (message cmd)
      (insert (format ">>> %s\n" cmd))
      (let ((process (start-process-shell-command cmd (current-buffer) cmd)))
        (set-process-sentinel process 'go-binary--sentinel)))))

(defun go-binary--sentinel (p e)
  "After a process exited, call `go-binary--start-next-cmd' again."
  (let ((buffer (process-buffer p)))
    (when (not (null buffer))
      (with-current-buffer buffer
        (insert (format "Command %s %s" p e))
        (go-binary--start-next-cmd)))))

(provide 'go-binary)

;;; go-binary.el ends here
