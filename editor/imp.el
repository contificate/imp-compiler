;; IMP highlighting

;; I lack the required immortality to deal with emacs' regex building utility functions
(setq words '("let" "in" "integer" "while" "do" "if" "else" "return"))
(setq keywords
      (mapcar (lambda (x) (cons (concat "\\b" x "\\b") font-lock-function-name-face)) words))

(setq imp-highlights (append keywords '(("\\b[0-9]+" . font-lock-constant-face))))

(define-derived-mode imp-mode fundamental-mode "IMP"
  "major mode for editing IMP programs"
  (setq font-lock-defaults '(imp-highlights)))

(provide 'imp-mode)
