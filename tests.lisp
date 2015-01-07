(defpackage :cl-junit-xml.test
  (:use :cl :cl-user :lisp-unit2 :iter :cl-junit-xml)
  (:shadow :run-tests))

(in-package :cl-junit-xml.test)

(defun run-tests (&key suites tests)
  (let ((*package* (find-package :cl-junit-xml.test)))
    (lisp-unit2:run-tests
     :tests tests
     :tags suites
     :name :cl-junit-xml
     :run-contexts #'lisp-unit2:with-summary-context)))

(define-test simple ()
  (let* ((junit (make-junit))
         (suite (add-child junit (make-testsuite "suite")))
         (testcase (add-child suite (make-testcase "test" "class" 1.0)))
         (xml (write-xml junit nil))
         (xmls (cxml:parse xml (cxml-xmls:make-xmls-builder))))
    (declare (ignore testcase))

    (assert-equalp '("testsuites" nil
                     ("testsuite" (("time" "1.0")
                                   ("failures" "0")
                                   ("errors" "0")
                                   ("tests" "1")
                                   ("id" "0")
                                   ("name" "suite"))
                      ("testcase" (("time" "1.0")
                                   ("classname" "class")
                                   ("name" "test")))))
                   xmls)))

(define-test make-testsuite/with-optional-args ()
  (let* ((junit (make-junit))
         (suite (add-child junit (make-testsuite "suite" :timestamp "now"
                                                         :package "foo")))
         (xml (write-xml junit nil))
         (xmls (cxml:parse xml (cxml-xmls:make-xmls-builder))))
    (declare (ignore suite))

    (assert-equalp '("testsuites" nil
                    ("testsuite" (("time" "0.0")
                                  ("failures" "0")
                                  ("errors" "0")
                                  ("tests" "0")
                                  ("id" "0")
                                  ("timestamp" "now")
                                  ("package" "foo")
                                  ("name" "suite"))))
                   xmls)))

(define-test errors-and-failures ()
  (let* ((junit (make-junit))
         (suite (add-child junit (make-testsuite "suite")))
         (testcase (add-child suite (make-testcase "test" "class" 1.0
                                                   :failure "invalid assertion")))
         (testcase2 (add-child suite (make-testcase "test2" "class" 1.0
                                                   :error "problem running the test")))
         (xml (write-xml junit nil))
         (xmls (cxml:parse xml (cxml-xmls:make-xmls-builder))))
    (declare (ignore testcase testcase2))

    (assert-equalp '("testsuites" nil
                    ("testsuite" (("time" "2.0")
                                  ("failures" "1")
                                  ("errors" "1")
                                  ("tests" "2")
                                  ("id" "0")
                                  ("name" "suite"))
                     ("testcase" (("time" "1.0")
                                  ("classname" "class")
                                  ("name" "test2"))
                      ("error" nil "problem running the test"))
                     ("testcase" (("time" "1.0")
                                  ("classname" "class")
                                  ("name" "test"))
                      ("failure" nil "invalid assertion"))))
               xmls)))

(define-test writes-files ()
  (assert-false (probe-file (pathname "cl-junit-xml.test.xml")))
  (let* ((junit (make-junit))
         (suite (add-child junit (make-testsuite "suite" :timestamp "now")))
         (testcase (add-child suite (make-testcase "test" "class" 1.0)))
         (path (write-xml junit "cl-junit-xml.test.xml")))
    (declare (ignore testcase))
    (assert-true (probe-file path))
    (delete-file path)))

(define-test make-testcase/ignore-empty-strings ()
  (let ((tx-empty (make-testcase "test" "class" 0 :error "" :failure ""))
        (tx-nil (make-testcase "test" "class" 0 :error "" :failure ""))
        (tx (make-testcase "test" "class" 0 :error "e" :failure "f")))
    (assert-false (cl-junit-xml::error-text tx-empty))
    (assert-false (cl-junit-xml::error-text tx-nil))
    (assert-equal "e" (cl-junit-xml::error-text tx))
    (assert-false (cl-junit-xml::failure-text tx-empty))
    (assert-false (cl-junit-xml::failure-text tx-nil))
    (assert-equal "f" (cl-junit-xml::failure-text tx))))
