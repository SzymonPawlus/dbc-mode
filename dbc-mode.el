;;; dbc-mode.el --- Major mode for DBC bytecode files -*- lexical-binding: t; -*-

;; Author: Your Name <your.email@example.com>
;; Maintainer: Your Name <your.email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, tools, bytecode
;; URL: https://github.com/your-username/dbc-mode

;;; Commentary:

;; This package provides a major mode for editing DBC bytecode files.
;; It includes syntax highlighting, indentation, and basic completion support
;; for instructions and types defined in the DBC specification.

;; Features:
;; - Syntax highlighting for instructions, registers, types, and comments (#).
;; - Completion-at-point support (CAPF) for instructions and keywords.
;; - Intelligent indentation (basic block support).

;;; Code:

(defgroup dbc-mode nil
  "Major mode for DBC bytecode."
  :group 'languages
  :prefix "dbc-mode-")

(defvar dbc-mode-hook nil)

(defvar dbc-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'comment-region)
    map)
  "Keymap for `dbc-mode'.")

;;; Syntax Table
(defvar dbc-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Comments start with #
    (modify-syntax-entry ?# "<" st)
    (modify-syntax-entry ?\n ">" st)
    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    ;; Symbol constituents
    (modify-syntax-entry ?_ "w" st)
    ;; Punctuation
    (modify-syntax-entry ?{ "(}" st)
    (modify-syntax-entry ?} "){" st)
    (modify-syntax-entry ?, "." st)
    (modify-syntax-entry ?\; "." st)
    st)
  "Syntax table for `dbc-mode'.")

;;; Keywords and Constants

(defconst dbc-instructions
  '(
    ;; MOV
    "mov_l8_imm" "mov_l8_l8" "cmov_l8_l8" "cmov_l8_imm"
    "mov_l16_imm" "mov_l16_l16" "cmov_l16_l16" "cmov_l16_imm"
    "mov_l32_imm" "mov_l32_l32" "cmov_l32_l32" "cmov_l32_imm"
    "mov_l64_imm" "mov_l64_l64" "cmov_l64_l64" "cmov_l64_imm"
    "mov_g64_g64" "mov_g64_l64" "mov_g64_imm"
    "mov_g32_g32" "mov_g32_l32" "mov_g32_imm"
    "mov_g16_g16" "mov_g16_l16" "mov_g16_imm"
    "mov_g8_g8" "mov_g8_l8" "mov_g8_imm"
    "mov_gptr_lptr" "mov_l64_g64" "mov_l32_g32" "mov_l16_g16"
    "mov_l8_g8" "mov_lptr_gptr" "mov_lptr_lptr" "setNull_lptr"
    "mov_lopq_lopq"
    ;; Arithmetic
    "add_l64_l64" "add_l64_imm" "add_l32_l32" "add_l32_imm"
    "sub_l64_l64" "sub_l64_imm" "sub_l32_l32" "sub_l32_imm"
    "mul_l64_l64" "mul_l64_imm" "mul_l32_l32" "mul_l32_imm"
    "mod_l64_l64" "mod_l64_imm" "mod_l32_l32" "mod_l32_imm"
    "div_l64_l64" "div_l64_imm" "div_l32_l32" "div_l32_imm"
    "neg_l64" "neg_l32"
    ;; Float/Unsigned
    "fadd_l64_l64" "fadd_l64_imm" "fadd_l32_l32" "fadd_l32_imm"
    "fsub_l64_l64" "fsub_l64_imm" "fsub_l32_l32" "fsub_l32_imm"
    "fmul_l64_l64" "fmul_l64_imm" "fmul_l32_l32" "fmul_l32_imm"
    "fdiv_l64_l64" "fdiv_l64_imm" "fdiv_l32_l32" "fdiv_l32_imm"
    "fneg_l64" "fneg_l32"
    "umul_l64_l64" "umul_l64_imm" "umul_l32_l32" "umul_l32_imm"
    "umod_l64_l64" "umod_l64_imm" "umod_l32_l32" "umod_l32_imm"
    "udiv_l64_l64" "udiv_l64_imm" "udiv_l32_l32" "udiv_l32_imm"
    ;; Logic
    "log_and_l8_l8" "log_and_l8_imm" "log_or_l8_l8" "log_or_l8_imm"
    "log_xor_l8_l8" "log_xor_l8_imm" "log_not_l8"
    "cmpEq_l64_l64" "cmpEq_l64_imm" "cmpG_l64_l64" "cmpG_l64_imm"
    "ucmpG_l64_l64" "ucmpG_l64_imm" "cmpL_l64_l64" "cmpL_l64_imm"
    "ucmpL_l64_l64" "ucmpL_l64_imm"
    "cmpEq_l32_l32" "cmpEq_l32_imm" "cmpG_l32_l32" "cmpG_l32_imm"
    "ucmpG_l32_l32" "ucmpG_l32_imm" "cmpL_l32_l32" "cmpL_l32_imm"
    "ucmpL_l32_l32" "ucmpL_l32_imm"
    "cmpEq_l8_l8" "cmpEq_l8_imm" "cmpG_l8_l8" "cmpG_l8_imm"
    "ucmpG_l8_l8" "ucmpG_l8_imm" "cmpL_l8_l8" "cmpL_l8_imm"
    "ucmpL_l8_l8" "ucmpL_l8_imm" "cmpNull_lptr"
    ;; Misc
    "variantSetInner_lvnt_type" "variantGetInner_lptr_lvnt_type"
    "variantSetInner_lptr_type" "variantGetInner_lptr_lptr_type"
    "label" "jmp_label" "jmpIf_label" "jmpIfNot_label"
    "call_func" "call_builtinfunc" "call_cfunc"
    "ret_tailcall_func" "ret" "nop" "exit" "breakpoint"
    "init_lany_type" "deinit" "input_l64" "output_l64" "input_l32" "output_l32"
    "strOutput_lptr"
    "setVTable_lptr_type" "upcast_lptr_lptr" "downcast_lptr_lptr_type"
    "virtual_call_lptr_method" "alloc_lptr_type" "free_lptr"
    "store_lptr_lany" "load_lany_lptr" "ref_lptr_lany"
    "structLea_lptr_lptr_field" "structLoad_lany_lptr_field" "structStore_lptr_lany_field"
    "fixedSizeTableLea_lptr_lptr_l64" "fixedSizeTableLoad_lany_lptr_l64" "fixedSizeTableStore_lptr_lany_l64"
    "dynTableLea_lptr_lptr_l64" "dynTableLoad_lany_lptr_l64" "dynTableStore_lptr_lany_l64"
    "dynTableReAlloc_lptr_type_l64"
    "cast_l8_type" "cast_l16_type" "cast_l32_type" "cast_l64_type"
    "initFromVmValue")
  "List of DBC instructions.")

(defconst dbc-keywords
  '("function" "global_data" "return" "->")
  "List of DBC structural keywords.")

(defconst dbc-types
  '("void" "i64" "i32" "i16" "i8" "u64" "u32" "u16" "u8" "ptr" "vnt")
  "List of DBC types.")

;;; Font Lock

(defconst dbc-font-lock-keywords
  `((,(regexp-opt dbc-instructions 'words) . font-lock-keyword-face)
    (,(regexp-opt dbc-keywords 'words) . font-lock-preprocessor-face)
    (,(regexp-opt dbc-types 'words) . font-lock-type-face)
    ;; Function names
    ("\\(?:function\\|call_func\\|label\\)\\s-+\\(\\_<[a-zA-Z0-9_]+\\_>\\)" 1 font-lock-function-name-face)
    ;; Builtins
    ("\\(builtin_[a-zA-Z0-9_]+\\)" . font-lock-builtin-face)
    ;; Constants
    ("\\_<[0-9]+\\_>" . font-lock-constant-face)
    ("\\_<0x[0-9a-fA-F]+\\_>" . font-lock-constant-face)
    ;; Variables (generic fallback)
    ("\\_<[a-zA-Z][a-zA-Z0-9_]*\\_>" . font-lock-variable-name-face))
  "Font lock keywords for `dbc-mode'.")

;;; Indentation (Basic)

(defun dbc-indent-line ()
  "Indent current line for DBC."
  (interactive)
  (let ((indent-col 0))
    (save-excursion
      (beginning-of-line)
      (condition-case nil
          (while (search-backward-regexp "[{}]" nil t)
            (if (looking-at "{")
                (setq indent-col (+ indent-col 4))
              (setq indent-col (max 0 (- indent-col 4)))))
        (error nil)))
    (save-excursion
      (beginning-of-line)
      (when (looking-at "^\\s-*\\(?:}\\|label\\)")
        (setq indent-col (max 0 (- indent-col 4)))))
    (indent-line-to (max 0 indent-col))))

;;; Completion

(defun dbc-completion-annotation (cand)
  "Annotate completion CAND."
  (cond ((member cand dbc-instructions) " <Instr>")
        ((member cand dbc-types) " <Type>")
        ((member cand dbc-keywords) " <Key>")
        (t nil)))

(defun dbc-completion-at-point ()
  "CAPF backend for DBC."
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (list (car bounds)
            (cdr bounds)
            (append dbc-instructions dbc-types dbc-keywords)
            :annotation-function #'dbc-completion-annotation
            :exclusive 'no))))

;;; Definition

;;;###autoload
(define-derived-mode dbc-mode prog-mode "DBC"
  "Major mode for editing DBC bytecode files.

\\{dbc-mode-map}"
  :syntax-table dbc-mode-syntax-table
  (setq-local font-lock-defaults '(dbc-font-lock-keywords))
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local comment-start-skip "#+\\s *")
  (setq-local indent-line-function 'dbc-indent-line)
  (add-hook 'completion-at-point-functions #'dbc-completion-at-point nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.dbc\\'" . dbc-mode))

(provide 'dbc-mode)
;;; dbc-mode.el ends here
