;;; zine-mode.el --- major mode for zine, the static site generator -*- lexical-binding: t; -*-

;; Author: 2024 Robbie Lyman <rb.lymn@gmail.com>
;;
;; URL: https://github.com/robbielyman/zine-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.0"))
;;
;; This file is NOT part of Emacs.
;;
;;; License:
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;;; Commentary:
;; This major mode uses tree-sitter for font-lock, indentation and so on.

;;;; Code:

(require 'treesit)
(require 'reformatter)

(defgroup zine-mode nil
  "Tree-sitter powered support for Zine static site code."
  :link '(url-link "https://zine-ssg.io")
  :group 'languages)

(defcustom zine-superhtml-format-on-save t
  "Format buffers before saving using superhtml fmt."
  :type 'boolean
  :safe #'booleanp
  :group 'zine-mode)

(defcustom zine-superhtml-format-show-buffer t
  "Show a *superhtml-fmt* buffer after superhtml fmt completes with errors."
  :type 'boolean
  :safe #'booleanp
  :group 'zine-mode)

(defcustom zine-superhtml-bin "superhtml"
  "Path to superhtml executable."
  :type 'file
  :safe #'stringp
  :group 'zine-mode)

;; superhtml fmt

(reformatter-define zine-superhtml-format
  :program zine-superhtml-bin
  :args '("fmt" "--stdin")
  :group 'zine-mode
  :lighter " ZineSuperHTMLFmt")

;;;###autoload (autoload 'zine-superhtml-format-buffer "current-file" nil t)
;;;###autoload (autoload 'zine-superhtml-format-region "current-file" nil t)
;;;###autoload (autoload 'zine-superhtml-format-on-save-mode "current-file" nil t)

(defvar zine-suprehtml--treesit-font-lock-setting
  (treesit-font-lock-rules
   :feature 'comment
   :language 'superhtml
   '((comment) @font-lock-comment-face)

   :feature 'bracket
   :language 'superhtml
   '([
      "<"
      ">"
      "</"
      "/>"
      "<!"
      ] @font-lock-bracket-face)

   :feature 'delimiter
   :language 'superhtml
   '("=" @font-lock-delimiter-face)

   :feature 'string
   :language 'superhtml
   '([
      "\""
      (attribute_value)
      ] @font-lock-string-face)

   :feature 'attributes
   :language 'superhtml
   '((attribute_name) @font-lock-attribute-face)

   :feature 'doctype
   :language 'superhtml
   '((doctype) @font-lock-keyword-face)

   :feature 'special
   :language 'superhtml
   '(((tag_name) @font-lock-builtin-face
      (:any-of @font-lock-builtin-face "super" "extend")))

   :feature 'parse-error
   :language 'superhtml
   '((erroneous_end_tag_name) @font-lock-warning-face)

   :feature 'links
   :language 'superhtml
   '((
      (element
       (start_tag
        (attribute
         (attribute_name) @font-lock-attribute-face
         [
          (attribute_value) @font-lock-doc-markup-face
          (quoted_attribute_vale (attribute_value) @font-lock-doc-markup-face)
          ]))
       (element
        (start_tag
         (tag_name) @font-lock-function-call-face)))
      (:eq @font-lock-function-call-face "super")
      (:eq @font-lock-attribute-face "id")
      ))

   :feature 'super-errors
   :language 'superhtml
   '((
      (element
       (start_tag
        (tag_name) @font-lock-builtin-face
        (attribute
         (attribute_name) @font-lock-warning-face):+))
      (:eq @font-lock-builtin-face "super")
      ))

   :feature 'tag
   :language 'superhtml
   '((tag_name) @font-lock-function-call-face)
   )
  "Tree-sitter font-lock settings for superhtml.")

;;;###autoload
(define-derived-mode zine-mode prog-mode "Zine"
  "A tree-sitter-powered major mode for the Zine static site generator."
  :group 'zine-mode
  (when zine-superhtml-format-on-save
    (zine-superhtml-format-on-save-mode 1))
  (when (treesit-ready-p 'superhtml)
    (treesit-parser-create 'superhtml)
    (setq-local treesit-font-lock-feature-list
                '((comment doctype tag special parse-error super-errors)
                  (string attributes)
                  (links)
                  (bracket delimiter)))
    (setq-local treesit-font-lock-settings zine-superhtml--treesit-font-lock-setting)
    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.shtml\\'" . zine-mode))

(provide 'zine-mode)

;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not obsolete)
;; End:
;;; zine-mode.el ends here
