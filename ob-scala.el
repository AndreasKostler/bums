;;; ob-scala.el --- org-babel functions for Scala evaluation in sbt console

;; Copyright (C) 2012-2014 Free Software Foundation, Inc.

;; Author: Andreas Koestler
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Comments
;;  - Until session support and sbt-send-string have been merged
;; upstream manually install this fork of sbt-mode
;; https://github.com/CommBank/sbt-mode
;;;
;;; Requirements:
;;; - sbt :: http://scala-sbt.org
;;; - sbt-mode :: https://github.com/hvesalai/sbt-mode

;;; Code:

(require 'ob)
(require 'sbt-mode)
(require 'sbt-mode-buffer)
(eval-when-compile (require 'cl))

(defvar org-babel-tangle-lang-exts) ;; Autoloaded
(add-to-list 'org-babel-tangle-lang-exts '("scala" . "scala"))
(defvar org-babel-default-header-args:scala '())


(defun make-filter-fun (buffer params)
  "Create a comint filter function that extracts the result and formats it nicely for org-mode to insert"
  (lexical-let* ((buffer buffer)
                 (params params)
                 (info (org-babel-get-src-block-info))
                 (result-type (cdr (assoc :result-type params)))
                 (result-params (list (cdr (assoc :results params))))
                 (extract-result (lambda (s)
                                   (let ((res-list (split-string s "res.*: " )))
                                     (when (> (length res-list) 1)
                                       (let* ((res (car (last res-list)))
                                              (res (substring res 0 (string-match "\n" res))))
                                         (case result-type
                                           (output res)
                                           (value
                                            (org-babel-scala-table-or-string res))))))))
                 (reassemble-table (lambda (res)
                                     (org-babel-reassemble-table
                                      res
                                      (org-babel-pick-name
                                       (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
                                      (org-babel-pick-name
                                       (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params)))))))
    (lambda (s)
      (let ((res (funcall extract-result s)))
        (when res
          (with-current-buffer buffer
            (org-babel-insert-result (funcall reassemble-table res)
                                     result-params info
                                     nil 0 "scala")))
        ))))



;;(setq-local comint-output-filter-functions (cons (make-filter-fun
;;(current-buffer) params) comint-output-filter-fuctions)
(defun org-babel-execute:scala (body params)
  "Execute a block of Scala code with org-babel.  This function is
called by `org-babel-execute-src-block'"
  (message "executing Scala source code block")
  (let ((session (cdr (assoc :session params)))
        (full-body (org-babel-expand-body:generic
                    body params))
        (src-buffer (current-buffer)))
    (org-babel-scala-initiate-session session)
    (with-current-buffer (sbt:buffer-name session)
      (setq comint-output-filter-functions nil)
      (add-hook 'comint-output-filter-functions
                (make-filter-fun src-buffer params) t))
    (sbt:send-string full-body session)
    ;; Avoid b"Code block produced no output." message
    ""))

(defun org-babel-scala-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.
If RESULTS look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (org-babel-script-escape results))

(defun org-babel-prep-session:scala (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "Sessions are not (yet) supported for Scala"))

(defvar org-babel-scala-seen-prompt nil)

(defun org-babel-wait-for-prompt (session &optional timeout)
  "Wait until PROC sends us a prompt.
The process PROC should be associated to a comint buffer."
  (with-current-buffer (sbt:buffer-name session)
    (while (progn
             (goto-char comint-last-input-end)
             (not (or org-babel-scala-seen-prompt
                      (setq org-babel-scala-seen-prompt
                            (re-search-forward sbt:console-prompt-regexp nil t))
                      (not (accept-process-output (get-process (sbt:buffer-name session)) timeout))))))
    (unless org-babel-scala-seen-prompt
      (error "Can't find the console prompt"))))

(defun org-babel-scala-initiate-session (&optional session)
  "If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session.  Sessions are not
supported in Scala."
  (unless (comint-check-proc (sbt:buffer-name session))
    (setq org-babel-scala-seen-prompt nil)
    (message "Starting sbt session %s" (sbt:buffer-name session))
    (sbt:run-sbt nil nil session)
    (sbt:command "console" session)
    (org-babel-wait-for-prompt session 5)))


(defun org-babel-scala-insert-block (session)
     (interactive "MSession name: ")
     (insert (format "#+begin_src %s :tangle yes :noweb yes :output replace :session %s\n  \n#+end_src" "scala" session))
     (goto-char (- (point) 10)))

(provide 'ob-scala)


;;; ob-scala.el ends here
