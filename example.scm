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
  (ncurses/getch))

(ncurses/initscr)
(ncurses/start-color)
(ncurses/use-default-colors)
(ncurses/make-color 40 #:red 999 #:green 0 #:blue 0)

(ncurses/refresh)

(ncurses/init-color-pair 10 #:forground 40  #:background 0)
(example)

(ncurses/endwin)
