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
(require 'css-mode)
(require 'js)
(require 'markdown-mode)
(require 'ziggy-mode)

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

(defvar zine-supermd-inline--tresit-range-settings
  (treesit-range-rules
   :embed 'html
   :host 'supermd-inline
   '((html_tag) @capture)

   :embed 'latex
   :host 'supermd-inline
   '((latex_block) @capture))
  "Tree-sitter injections for supermd-inline.")

(defvar zine-supermd-inline--treesit-font-lock-setting
  (treesit-font-lock-rules
   :feature 'verbatim
   :language 'supermd-inline
   '([
      (code_span)
      (link_title)
      ] @markdown-code-face)

   :feature 'delimiter
   :language 'supermd-inline
   '([
      (emphasis_delimiter)
      (code_span_delimiter)
      ] @font-lock-delimiter-face)

   :feature 'emphasis
   :language 'supermd-inline
   '((emphasis) @markdown-italic-face)

   :feature 'strong
   :language 'supermd-inline
   '((strong_emphasis) @markdown-bold-face)

   :feature 'url
   :language 'supermd-inline
   '([
      (link_destination)
      (uri_autolink)
      ] @markdown-url-face)

   :feature 'reference
   :language 'supermd-inline
   '([
      (link_label)
      (link_text)
      (image_description)
      ] @markdown-reference-face)

   :feature 'escape
   :language 'supermd-inline
   '([
      (backslash_escape)
      (hard_line_break)
      ] @font-lock-escape-face)

   :feature 'link-delimiter
   :language 'supermd-inline
   '(
     (image ["!" "[" "]" "(" ")"] @font-lock-delimiter-face)
     (inline_link ["[" "]" "(" ")"] @font-lock-delimiter-face)
     (shortcut_link ["[" "]"] @font-lock-delimiter-face)
     )
   )
  "Tree-sitter font-lock settings for supermd-inline.")

(defvar zine-supermd--treesit-range-settings
  (treesit-range-rules
   :embed 'html
   :host 'supermd
   '((html_block) @capture)

   :embed 'ziggy
   :host 'supermd
   '((document . (section . (thematic_break) (_) @capture (thematic_break)))
     ((minus_metadata) @capture))

   :embed 'supermd_inline
   :host 'supermd
   '((inline) @capture))
  "Tree-sitter injections for supermd.")

(defvar zine-supermd--treesit-font-lock-setting
  (treesit-font-lock-rules
   :feature 'title
   :language 'supermd
   '((atx_heading (inline) @markdown-header-face)
     (setext_heading (paragraph) @markdown-header-face))

   :feature 'title-punctuation
   :language 'supermd
   '([
      (atx_h1_marker)
      (atx_h2_marker)
      (atx_h3_marker)
      (atx_h4_marker)
      (atx_h5_marker)
      (atx_h6_marker)
      (setext_h1_underline)
      (setext_h2_underline)
      ] @font-lock-punctuation-face)

   :feature 'link-title
   :language 'supermd
   '([
      (link_title)
      (link_label)
      ] @markdown-link-title-face)

   :feature 'code-block
   :language 'supermd
   '([
      (indented_code_block)
      (fenced_code_block)
      ] @markdown-code-face)

   :feature 'delimiter
   :language 'supermd
   '((fenced_code_block_delimiter) @font-lock-delimiter-face)

   :feature 'url
   :language 'supermd
   '((link_destination) @markdown-url-face)

   :feature 'list-punctuation
   :language 'supermd
   '([
      (list_marker_plus)
      (list_marker_minus)
      (list_marker_star)
      (list_marker_dot)
      (list_marker_parenthesis)
      (thematic_break)
      ] @markdown-list-face)

   :feature 'other-punctuation
   :language 'supermd
   '([
      (block_continuation)
      (block_quote_marker)
      ] @font-lock-punctuation-face)

   :feature 'escape
   :language 'supermd
   '((backslash_escape) @font-lock-escape-face)
   )
  "Tree-sitter font-lock settings for supermd.")

(defconst zine-mode-superhtml-syntax-table
  (let ((table (make-syntax-table)))

    (modify-syntax-entry ?< "(>" table)
    (modify-syntax-entry ?> ")<" table)
    table))

(defun zine-superhtml--treesit-property-super-extend-p (node)
  "Check that NODE has text equal to \"super\" or \"extend\"."
  (or (equal (treesit-node-text node) "super")
      (equal (treesit-node-text node) "extend"))
  )

(defvar zine-superhtml--treesit-range-settings
  (treesit-range-rules
   :embed 'javascript
   :host 'superhtml
   '((script_element (raw_text) @capture))

   :embed 'css
   :host 'superhtml
   '((style_element (raw_text) @capture))
   )
  "Tree-sitter injections for superhtml.")

(defvar zine-superhtml--treesit-font-lock-setting
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
   '((attribute_name) @font-lock-function-call-face)

   :feature 'doctype
   :language 'superhtml
   '((doctype) @font-lock-keyword-face)

   :feature 'special
   :language 'superhtml
   '(((tag_name) @font-lock-builtin-face
      (:pred zine-superhtml--treesit-property-super-extend-p @font-lock-builtin-face)))

   :feature 'parse-error
   :language 'superhtml
   '((erroneous_end_tag_name) @font-lock-warning-face)

   :feature 'links
   :language 'superhtml
   '((
      (element
       (start_tag
        (attribute
         (attribute_name) @font-lock-keyword-face
         [
          (attribute_value) @font-lock-doc-markup-face
          (quoted_attribute_value (attribute_value) @font-lock-doc-markup-face)
          ]))
       (element
        (start_tag
         (tag_name) @font-lock-function-call-face)))
      (:equal @font-lock-function-call-face "super")
      (:equal @font-lock-keyword-face "id")
      ))

   :feature 'super-errors
   :language 'superhtml
   '((
      (element
       (start_tag
        (tag_name) @font-lock-builtin-face
        (attribute
         (attribute_name) @font-lock-warning-face) :+))
      (:equal @font-lock-builtin-face "super")
      ))

   :feature 'tag
   :language 'superhtml
   '((tag_name) @font-lock-function-call-face)
   )
  "Tree-sitter font-lock settings for superhtml.")

;;;###autoload
(define-derived-mode zine-superhtml-mode text-mode "Zine"
  "A tree-sitter-powered major mode for the Zine static site generator."
  :group 'zine-mode
  :syntax-table zine-mode-superhtml-syntax-table
  (when zine-superhtml-format-on-save
    (zine-superhtml-format-on-save-mode 1))
  (when (treesit-ready-p 'superhtml)
    (treesit-parser-create 'superhtml)
    (setq-local font-lock-fontify-region-function #'css--fontify-region)
    (setq-local treesit-font-lock-feature-list
                '((comment doctype tag special parse-error super-errors function error)
                  (string attributes keyword definition)
                  (links variable operator selector property constant query string-interpolation assignment jsx number escape-sequence)
                  (bracket delimiter)))
    (setq-local treesit-font-lock-settings (append zine-superhtml--treesit-font-lock-setting
                                                   css--treesit-settings
                                                   js--treesit-font-lock-settings))
    (setq-local treesit-range-settings zine-superhtml--treesit-range-settings)
    (treesit-major-mode-setup)))

;;;###autoload
(define-derived-mode zine-supermd-mode text-mode "Zine"
  "A tree-sitter-powered major mode for the Zine static site generator."
  :group 'zine-mode
  (when (and (treesit-ready-p 'supermd)
             (treesit-ready-p 'supermd-inline))
    (treesit-parser-create 'supermd)
    (treesit-parser-create 'supermd-inline)
    (setq-local treesit-font-lock-feature-list
                '((url comment doctype tag special parse-error function error)
                  (code-block link-title reference verbatim)
                  (strong emphasis escape)
                  (link-delimiter delimiter title-punctuation list-punctuation)))
    (setq-local treesit-font-lock-settings (append zine-supermd--treesit-font-lock-setting
                                                   zine-supermd-inline--treesit-font-lock-setting
                                                   ziggy--treesit-font-lock-setting
                                                   latex--treesit-font-lock-setting))
    (setq-local treesit-range-settings (append zine-supermd--treesit-range-settings
                                               zine-supermd-inline--treesit-range-settings))
    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.shtml\\'" . zine-superhtml-mode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smd\\'" . zine-supermd-mode))

(provide 'zine-mode)

;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not obsolete)
;; End:
;;; zine-mode.el ends here
