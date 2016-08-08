(define-module (ncurses)
  #:use-module (system foreign)
  #:use-module (rnrs bytevectors)
  #:use-module ((guile) #:select (format) #:prefix guile/)
  #:export (initscr
            test
            endwin
            keypad
            no-echo
            new-window
            refresh
            delete-window
            move-cursor
            getch
            format
            window
            fetch-current-window
            with-window
            color-pair
            make-color-pair
            *stdscr*
            with-attributes
            window-attribute-on
            window-attribute-off
            lines
            columns
            start-color
            make-color
            change-color?
            use-default-colors
            *red*
            *white*
            *cyan*
            *magenta*
            *green*
            *blue*
            *yellow*
            *black*
            *normal*
            *standout*
            *underline*
            *reverse*
            *diminished*
            *bold*
            ))

;;; dynamic link to the curses library
(define ncurses (dynamic-link "libncurses"))
(define window (make-fluid #f)) ; indicates we're in a with-screen body
(define *stdscr* '())

;;;; constants from ncurses.h

;;; key codes: TODO - these are wrong, but they came from my ncurses.h file.
;;; To get these, just write a little shell script. My header file is wrong though...
(define *key-down*      0402)
(define *key-up*        0403)
(define *key-left*      0404)
(define *key-right*     0405)
(define *key-home*      0406)
(define *key-backspace* 0407)
(define *key-f0*        0410)
(define *key-enter*     0527)

;;; ncurses bits function
(define *ncurses-attr-shift* 8)
(define (ncurses-bits mask shift) (ash mask (+ shift *ncurses-attr-shift*)))

;;; window constants
(define *normal*     0)
(define *standout*   (ncurses-bits 1 8))
(define *underline*  (ncurses-bits 1 9))
(define *reverse*    (ncurses-bits 1 10))
(define *diminished* (ncurses-bits 1 12))
(define *bold*       (ncurses-bits 1 13))
(define *extract*    (- (ncurses-bits 1 13) 1))

;;; color constants, extracted from ncurses.h
(define *black*   0)
(define *red*     1)
(define *green*   2)
(define *yellow*  3)
(define *blue*    4)
(define *magenta* 5)
(define *cyan*    6)
(define *white*   7)

;;; allows us to access a color pair
(define (color-pair n) (ncurses-bits n 0))

(define (key-f n) (+ n *key-f0*))

(define (parse-key key)
  (case key
    ((*key-down*) 'key-down)
    ((*key-up*) 'key-up)
    ((*key-left*) 'key-left)
    ((*key-right*) 'key-right)
    ((*key-home*) 'key-home)
    ((*key-backspace*) 'key-backspace)
    ((*key-enter*) 'key-enter)
    (else (integer->char key))))

(define (fetch-current-window)
  (if (fluid-ref window)
      (fluid-ref window)
      *stdscr*))

;;; Perhaps the most fundamental macro: with-window
;;; In curses, every operation happens on a window.
;;; If you call the functions in this library, they use the default window
;;; called *stdscr*. However, if you use this macro with a window that you have defined,
;;; like with (with-window my-window (format "Hello, world! ~%")) the operations
;;; will be performed on my-window.
(define-syntax with-window
  (syntax-rules ()
    ((_ win body ...) (let ((old-window (fetch-current-window)))
                           (begin (fluid-set!  window win)
                                  body ...
                                  (fluid-set! window old-window))))))
  
;;; initialize the curses screen
;;; This must be called BEFORE any other routine can be used.
(define (initscr)
  (begin (dynamic-call "initscr" ncurses)
         (set! *stdscr* (dereference-pointer (dynamic-pointer "stdscr" ncurses)))))

;;; destroy the curses screen
;;; This must be called AFTER the other routines to ensure propper terminal cleanup. 
(define (endwin) (dynamic-call "endwin" ncurses))

;;; character-by-character input
(define (cbreak) (dynamic-call "cbreak" ncurses))

;;; turns off echoing of keyboard
(define (no-echo) (dynamic-call "noecho" ncurses))

;;; allows color to be used
(define (start-color) (dynamic-call "start_color" ncurses))

;;; capture special keys
(define* (keypad bool)
  ((pointer->procedure void
                       (dynamic-func "keypad" ncurses)
                       (list '* int))
   (fetch-current-window)
   (if bool 1 0)))

;;; creates a new window w/ specified parameters
(define (new-window width height x0 y0)
  ((pointer->procedure '*
                       (dynamic-func "newwin" ncurses)
                       (list int int int int))
   height width y0 x0))

;;; refreshes the window
;;; if no window is specified, defaults to stdscr
(define* (refresh)
  ((pointer->procedure void
                       (dynamic-func "wrefresh" ncurses)
                       (list '*))
   (fetch-current-window)))

;;; deletes the given window
(define (delete-window window)
  ((pointer->procedure void
                       (dynamic-func "delwin" ncurses)
                       (list '*))
   (fetch-current-window)))

;;; moves the cursor to the appropriate position
(define* (move-cursor x y)
  ((pointer->procedure void
                       (dynamic-func "wmove" ncurses)
                       (list '* int int))
   (fetch-current-window) y x))

;;; returns a single character of input
(define (getch)
  (parse-key ((pointer->procedure int
                                  (dynamic-func "getch" ncurses)
                                  (list '*))
              (fetch-current-window))))

(define (displayer format-str rest)
  (apply guile/format `(#f ,format-str ,@rest)))

;;; format-str is a formatting string like you'd give to format
;;; This function takes a variable number of arguments and emits them
;;; to the active window.
(define (format format-str . rest)
  ((pointer->procedure int
                       (dynamic-func "waddstr" ncurses)
                       (list '* '*))
   (fetch-current-window)
   (string->pointer (displayer format-str rest))))

;;; adds the given attribute to the active window
(define (window-attribute-on attribute)
  ((pointer->procedure int
                       (dynamic-func "wattron" ncurses)
                       (list '* int))
   (fetch-current-window) attribute))

;;; removes the given attribute
(define (window-attribute-off attribute)
  ((pointer->procedure int
                       (dynamic-func "wattroff" ncurses)
                       (list '* int))
   (fetch-current-window) attribute))

;;; sets the given attributes to on, performs the body, then cleans up.
(define-syntax with-attributes
  (syntax-rules ()
    ((_ (attribute ...) body ...) (begin (map window-attribute-on
                                              (list attribute ...))
                                         body ...
                                         (map window-attribute-off
                                              (list attribute ...))))))

;;; Returns the number of lines of the terminal
(define (lines)
  (bytevector-uint-ref (pointer->bytevector  (dynamic-pointer "LINES" ncurses)
                                             (sizeof int))
                       0
                       (native-endianness)
                       (sizeof int)))

;;; Returns the number of columns of the terminal
(define (columns)
  (bytevector-uint-ref (pointer->bytevector (dynamic-pointer "COLS" ncurses)
                                            (sizeof int))
                       0
                       (native-endianness)
                       (sizeof int)))

;;; initializes the color pair
(define* (make-color-pair pair-id #:key forground background)
  ((pointer->procedure int
                       (dynamic-func "init_pair" ncurses)
                       (list short short short)) pair-id forground background))

(define *red-mask*   #b111111110000000000000000)
(define *green-mask* #b000000001111111100000000)
(define *blue-mask*  #b000000000000000011111111)

(define (hex->red hex) (ash (logand hex *red-mask*) -16))
(define (hex->green hex) (ash (logand hex *green-mask*) -8))
(define (hex->blue hex) (ash (logand hex *blue-mask*) 0))

;;; Creates a new color with the given ID.
;;; You either must specify #:hexadecimal for a hexadecimal color representation,
;;; or you must specify #:red #:green #:blue
(define* (make-color id
                     #:key
                     (hexadecimal #f)
                     (red   (if hexadecimal (hex->red hexadecimal) #f))
                     (green (if hexadecimal (hex->green hexadecimal) #f))
                     (blue  (if hexadecimal (hex->blue hexadecimal) #f)))
  (cond ((or (not red) (not green) (not blue)) (error "Error: red, green, or blue not specified."))
        (else ((pointer->procedure int
                                   (dynamic-func "init_color" ncurses)
                                   (list short short short short)) id red green blue))))

(define (test id red green blue)
   ((pointer->procedure int
                        (dynamic-func "init_color" ncurses)
                        (list short short short short)) id red green blue))

;;; Can we change colors?
(define (change-color?)
  (if (not (zero? ((pointer->procedure int
                                       (dynamic-func "can_change_color" ncurses)
                                       '()))))
      #t
      #f))

;;; Use the default colors
(define (use-default-colors)
  (dynamic-call "use_default_colors" ncurses))
