(add-to-load-path (dirname (current-filename)))
(use-modules ((ncurses)
              #:prefix ncurses/))

;;; This is what you would normally do in an application
(define (example)
  (ncurses/with-attributes (ncurses/*underline* (ncurses/color-pair 10))
                           (ncurses/format "Hello, ~a!~%" 'world))
  (ncurses/format "Press any button to exit~%")
  (ncurses/format "Number of lines: ~a~%" (ncurses/lines))
  (ncurses/format "Number of columns: ~a~%" (ncurses/columns))
  (ncurses/format "Change color? ~a~%" (ncurses/change-color?))
  (ncurses/refresh))

(ncurses/initscr)
(ncurses/start-color)
(ncurses/use-default-colors)
(ncurses/no-echo)

(ncurses/make-color 40 #:red 999 #:green 0 #:blue 0)
(ncurses/make-color-pair 10 #:forground 40  #:background 0)

;;; Define two testing windows
(define my-window (ncurses/new-window (floor (/ (ncurses/columns) 2))
                                      (floor (/ (ncurses/lines) 2))
                                      0
                                      0))

(define my-window-2 (ncurses/new-window (floor (/ (ncurses/columns) 2))
                                        (floor (/ (ncurses/lines) 2))
                                        (floor (/ (ncurses/columns) 2))
                                        0))

;;; You must refresh to see the windows
(ncurses/refresh)

;;; The display code is agnostic of window
;;; We can specify any window, and the display logic will work.
(ncurses/with-window my-window
                     (example))

(ncurses/with-window my-window-2
                     (example))

(ncurses/getch)
(ncurses/endwin)
