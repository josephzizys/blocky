;;; meta.lisp --- visual lisp macros for a blocky-in-blocky funfest

;; Copyright (C) 2011  David O'Toole

;; Author: David O'Toole <dto@ioforms.org>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(in-package :blocky)

(defmacro define-visual-macro ((name super &rest fields)
		     &rest body)
  "Define a visual block element called NAME.
The argument SUPER should be the name of the base prototype of the
resulting block. FIELDS should be a list of field descriptors as given
to `define-prototype'. The BODY forms are evaluated when the resulting
block is recompiled; therefore the BODY forms define the output of the
recompilation."
    `(progn 
       (define-block (,name :super ,super) ,@fields)
       (define-method recompile ,name () ,@body)
       (define-method evaluate ,name ()
	 (eval (recompile self)))))

(define-visual-macro (prog0 list
			    (category :initform :structure)
			    (inputs :initform (list (new reference))))
		     (mapc #'recompile %inputs))

(define-method initialize prog0 (&rest args)
  (initialize%%block self)
  (assert (blockyp (first %inputs)))
  (pin (first %inputs)))

(define-visual-macro (quote list
			    (category :initform :operators))
		     `(quote ,(mapcar #'recompile %inputs)))

(define-visual-macro 
    (with-target list
      (inputs :initform (list (new socket :label "send to:")
			      (new list)))
      (category :initform :structure))
    (destructuring-bind (target body) 
	(mapcar #'recompile %inputs)
      `(with-target ,target
	 ,body)))

(define-visual-macro (define-block tree
	    (label :initform "define block")
	    (locked :initform t)
	    (expanded :initform t)
	    (inputs :initform 
		    (list (new string :label "name")
			  (new tree :label "options"
				    :inputs (list (new string :value "block" :label "super")))
			  (new tree :label "fields" :inputs (list (new list))))))
	   ;; spit out a define-block
	   (destructuring-bind (name super fields) 
	       (mapcar #'recompile %inputs)
	     (let ((block-name (make-symbol (first name)))
		   (super (make-prototype-id (first super))))
	       (append (list 'define-block (list block-name :super super))
		       fields))))

(define-visual-macro (argument block
	    (category :initform :variables)
	    (inputs :initform 
		    (list (new string :label "name")
			  (new entry :label "type")
			  (new string :label "default"))))
	   (destructuring-bind (name type default) 
	       (mapcar #'recompile %inputs)
	     (list (make-symbol name) type :default default)))

(define-visual-macro (method tree
	    (inputs :initform (list 
			       (new string :label "name")
			       (new tree :label "for block"
					 :inputs (list (new string :value "name" :label "")))
			       (new tree :label "definition" :inputs (list (new block))))))
	   (destructuring-bind (name prototype definition) 
	       (mapcar #'recompile %inputs)
	     (let ((method-name (make-symbol (first name)))
		   (prototype-id (make-prototype-id prototype)))
	       (append (list 'define-method method-name prototype-id)
		       (first definition)))))

(define-visual-macro (field block
	    (category :initform :variables)
	    (inputs :initform
		    (list (new string :label "name")
			  (new socket :label "value"))))
	   ;;
	   (destructuring-bind (name value) 
	       (mapcar #'recompile %inputs)
	     (list name :initform value)))

(define-method accept field (thing)
  (declare (ignore thing))
  nil)

;;; meta.lisp ends here