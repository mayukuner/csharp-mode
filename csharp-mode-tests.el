(require 'ert)
(require 'cl-lib)
(require 'csharp-mode)
(require 'cl)
(require 'package)

;;; test-helper functions

(defun move-to-line-after (text)
  (search-forward text)
  (move-beginning-of-line 1)
  (forward-line 1))

(defun get-current-line-contents ()
  (let* ((start)
         (end))
    (move-beginning-of-line 1)
    (setq start (point))
    (move-end-of-line 1)
    (setq end (point))
    (buffer-substring start end)))

;; development only packages, not declared as a package-dependency
(setq csharp-test-packages '(assess))

;; ensure development packages are installed.
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(defun csharp-test-packages-installed-p ()
  "Return nil if there are packages that are not installed."
  (loop for p in csharp-test-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(defun csharp-test-packages-install-packages ()
  "Install missing packages."
  (unless (csharp-test-packages-installed-p)
    ;; Referesh package lists
    (package-refresh-contents)
    ;; Install missing
    (dolist (p csharp-test-packages)
      (when (not (package-installed-p p))
        (ignore-errors
          (package-install p))))))
(csharp-test-packages-install-packages)


;;; actual tests

(ert-deftest activating-mode-doesnt-cause-failure ()
  (with-temp-buffer
    (csharp-mode)
    (should
     (equal 'csharp-mode major-mode))))

(defvar debug-res nil)

(ert-deftest fontification-of-literals-detects-end-of-strings ()
  ;; this replaces the manual test of fontification-test.cs, but file has been
  ;; kept around to assist manual testing/verification.
  (require 'assess)
  (should (assess-face-at=
           "string Literal = @\"with trailing slash\\\";\n public Type2 Reference = null;"
           'csharp-mode
           ;; should not be interpreted as string because of trailing \!
           "Type2" 'font-lock-type-face
           )))

(ert-deftest fontification-of-compiler-directives ()
  ;; this replaces the manual test of
  ;; test-files/fontification-test-compiler-directives.cs, but file
  ;; has been kept around to assist manual testing/verification.
  (require 'assess)
  (should (assess-face-at=
           "#region test\nx = true;"
           'csharp-mode
           ;; should not be interpreted as string because of trailing \!
           "true" 'font-lock-constant-face
           ))
  (should (assess-face-at=
           "#region test'\nx = true;"
           'csharp-mode
           ;; should not be interpreted as string because of trailing \!
           "true" 'font-lock-constant-face
           ))
  (should (assess-face-at=
           "#region test\"\nx = true;"
           'csharp-mode
           ;; should not be interpreted as string because of trailing \!
           "true" 'font-lock-constant-face
           )))

(ert-deftest fontification-of-compiler-directives-after-comments ()
  ;; this replaces the manual test of
  ;; test-files/fontification-test-compiler-directives-with-comments.cs, but file
  ;; has been kept around to assist manual testing/verification.
  (require 'assess)
  (let* ((test-string "#region case 1\n\n//this is a comment\n#region case2"))
    (should (assess-face-at=
             test-string
             'csharp-mode
             ;; should not be interpreted as string because of trailing \!
             "case1" 'font-lock-comment-face))
    (should (assess-face-at=
             test-string
             'csharp-mode
             ;; should not be interpreted as string because of trailing \!
             "case2" 'font-lock-comment-face))))

(defun list-repeat-once (mylist)
  (append mylist mylist))

(ert-deftest build-warnings-and-errors-are-parsed ()
  (dolist (test-case
           `(("./test-files/msbuild-warning.txt" ,csharp-compilation-re-msbuild-warning
              ,(list-repeat-once
                '("Class1.cs"
                  "Folder\\Class1.cs"
                  "Program.cs"
                  "Program.cs")))
             ("./test-files/msbuild-error.txt" ,csharp-compilation-re-msbuild-error
              ,(list-repeat-once
                '("Folder\\Class1.cs")))
             ("./test-files/msbuild-concurrent-warning.txt" ,csharp-compilation-re-msbuild-warning
              ,(list-repeat-once
                '("Program.cs")))
             ("./test-files/msbuild-concurrent-error.txt" ,csharp-compilation-re-msbuild-error
              ,(list-repeat-once
                '("Program.cs")))
             ("./test-files/msbuild-square-brackets.txt" ,csharp-compilation-re-msbuild-error
              ,(list-repeat-once
                '("Properties\\AssemblyInfo.cs"
                  "Program.cs"
                  "Program.cs")))
             ("./test-files/msbuild-square-brackets.txt" ,csharp-compilation-re-msbuild-warning
              ,(list-repeat-once
                '("Program.cs")))
             ("./test-files/xbuild-warning.txt" ,csharp-compilation-re-xbuild-warning
              ,(list-repeat-once
                '("/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ClassLibrary1/Class1.cs"
                  "/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ClassLibrary1/Folder/Class1.cs"
                  "/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ConsoleApplication1/Program.cs"
                  "/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ConsoleApplication1/Program.cs"
                  "/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ConsoleApplication1/Program.cs")))
             ("./test-files/xbuild-error.txt" ,csharp-compilation-re-xbuild-error
              ,(list-repeat-once
                '("/Users/jesseblack/Dropbox/barfapp/ConsoleApplication1/ClassLibrary1/Folder/Class1.cs")))
             ("./test-files/devenv-error.txt" ,csharp-compilation-re-xbuild-error
              ("c:\\working_chad\\dev_grep\\build_grep_database\\databaseconnection.cpp"
               "c:\\working_chad\\dev_grep\\build_grep_database\\databaseconnection.cpp"
               "c:\\working_chad\\dev_grep\\build_grep_database\\databaseconnection.cpp"))
             ("./test-files/devenv-error.txt" ,csharp-compilation-re-xbuild-warning
              ("c:\\working_chad\\dev_grep\\build_grep_database\\databaseconnection.cpp"))
             ("./test-files/devenv-mixed-error.txt" ,csharp-compilation-re-xbuild-error
              ("C:\\inservice\\SystemTesting\\OperateDeviceProxy\\OperateDevice_Proxy\\Program.cs"
               "C:\\inservice\\SystemTesting\\OperateDeviceProxy\\OperateDevice_Proxy\\Program.cs"
               "C:\\inservice\\SystemTesting\\OperateDeviceProxy\\OperateDevice_Proxy\\Program.cs"
               "c:\\inservice\\systemtesting\\operationsproxy\\operationsproxy.cpp"
               "c:\\inservice\\systemtesting\\operationsproxy\\operationsproxy.cpp"
               "c:\\inservice\\systemtesting\\operationsproxy\\operationsproxy.cpp"))))

    (let* ((file-name (car test-case))
           (regexp    (cadr test-case))
           (matched-file-names (cl-caddr test-case))
           (times     (length matched-file-names))
           (find-file-hook '()) ;; avoid vc-mode file-hooks when opening!
           (buffer (find-file-read-only file-name)))
      (message (concat "Testing compilation-log: " file-name))
      (dotimes (number times)
        (let* ((expected (nth number matched-file-names)))
          (message (concat "- Expecting match: " expected))
          (re-search-forward regexp)
          (should
           (equal expected (match-string 1)))))
      (kill-buffer buffer))))

(ert-deftest imenu-parsing-supports-default-values ()
  (dolist (test-case
           '(;; should support bools
             ("(bool a, bool b = true)"                  "(bool, bool)")
             ("(bool a=true, bool b)"                    "(bool, bool)")
             ;; should support strings
             ("(string a, string b = \"quoted string\")" "(string, string)")
             ("(string a = \"quoted string\", string b)" "(string, string)")
             ;; should support chars
             ("(char a, char b = 'b')"                   "(char, char)")
             ("(char a = 'a', char b)"                   "(char, char)")
             ;; should support self-object-access
             ("(object o = Const)"                       "(object)")
             ;; should support other-object-access
             ("(object o = ConstObject.Const)"           "(object)")
             ))
    (let* ((test-value     (car test-case))
           (expected-value (cadr test-case))
           (result         (csharp--imenu-remove-param-names-from-paramlist test-value)))
      (should (equal expected-value result)))))

(defmacro def-imenutest (testname filename index &rest body)
  `(ert-deftest ,testname ()
     (let* ((find-file-hook nil) ;; avoid vc-mode file-hooks when opening!
            (buffer         (find-file-read-only ,filename))
            (,index         (csharp--imenu-create-index-helper nil "" t t)) ;; same line as in `csharp-imenu-create-index'.
            )
       ,@body
       (kill-buffer buffer))))

(def-imenutest imenu-parsing-supports-generic-parameters
  "./test-files/imenu-generics-test.cs" imenu-index
  (let* ((class-entry    (cadr imenu-index))
         (class-entries  (cdr class-entry))
         (imenu-items    (mapconcat 'car class-entries " ")))

    ;; ("(top)" "method void NoGeneric(this IAppBuilder, params object[])" "method void OneGeneric<T>(this IAppBuilder, params object[])" "method void TwoGeneric<T1,T2>(this IAppBuilder, params object[])" "(bottom)")
    (should (string-match-p "NoGeneric" imenu-items))
    (should (string-match-p "OneGeneric<T>" imenu-items))
    (should (string-match-p "TwoGeneric<T1,T2>" imenu-items))))

(def-imenutest imenu-parsing-supports-comments
  "./test-files/imenu-comment-test.cs" imenu-index
  (let* ((class-entry    (cadr imenu-index))
         (class-entries  (cdr class-entry))
         (imenu-items    (mapconcat 'car class-entries " ")))
    (should (string-match-p "HasNoComment" imenu-items))
    (should (string-match-p "HasComment" imenu-items))
    (should (string-match-p "CommentedToo" imenu-items))))

(def-imenutest imenu-parsing-supports-explicit-interface-properties
  "./test-files/imenu-interface-property-test.cs" imenu-index
  (let* ((class-entry    (cl-caddr imenu-index))
         (class-entries  (cdr class-entry))
         (imenu-items    (mapconcat 'car class-entries " ")))
    (should (string-match-p "prop IIMenuTest.InterfaceString" imenu-items))))

(def-imenutest imenu-parsing-supports-explicit-interface-methods
  "./test-files/imenu-interface-property-test.cs" imenu-index
  (let* ((class-entry    (cl-caddr imenu-index))
         (class-entries  (cdr class-entry))
         (imenu-items    (mapconcat 'car class-entries " ")))
    (should (string-match-p "method string IIMenuTest.MethodName" imenu-items))))

(def-imenutest imenu-parsing-supports-namespaces
  "./test-files/imenu-namespace-test.cs" imenu-index
  (let* ((ns-entry       (cadr imenu-index))
         (ns-item        (car ns-entry)))
    (should (string-match-p "namespace ImenuTest" ns-item))))

(def-imenutest imenu-parsing-provides-types-with-namespace-names
  "./test-files/imenu-namespace-test.cs" imenu-index
  (let* ((ns-entry       (cadr imenu-index))
         (ns-items       (cdr ns-entry))
         (imenu-items    (mapconcat 'car ns-items " ")))
    (should (string-match-p "interface ImenuTest.ImenuTestInterface" imenu-items))
    (should (string-match-p "class ImenuTest.ImenuTestClass" imenu-items))
    (should (string-match-p "enum ImenuTest.ImenuTestEnum" imenu-items))))

(defvar csharp-hook1 nil)
(defvar csharp-hook2 nil)

(ert-deftest activating-mode-triggers-all-hooks ()
  (add-hook 'csharp-mode-hook (lambda () (setq csharp-hook1 t)))
  (add-hook 'prog-mode-hook   (lambda () (setq csharp-hook2 t)))

  (with-temp-buffer
    (csharp-mode)
    (should (equal t (and csharp-hook1
                          csharp-hook2)))))

(defvar c-mode-hook-run nil)
(ert-deftest avoid-runing-c-mode-hook ()
  (add-hook 'c-mode-hook (lambda () (setq c-mode-hook-run t)))

  (with-temp-buffer
    (csharp-mode)
    (should-not c-mode-hook-run)))

(ert-deftest indentation-rules-should-be-as-specified-in-test-doc ()
  (let* ((buffer (find-file "test-files/indentation-tests.cs"))
         (orig-content)
         (indented-content))
    ;; double-ensure mode is active
    (csharp-mode)

    (setq orig-content (buffer-substring-no-properties (point-min) (point-max)))
    (indent-region (point-min) (point-max))
    (setq indented-content (buffer-substring-no-properties (point-min) (point-max)))

    (should (equal orig-content indented-content))))

;;(ert-run-tests-interactively t)
