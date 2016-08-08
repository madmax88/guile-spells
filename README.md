# guile-spells

This is a ncurses wrapper for Guile Scheme written in 100% Guile, using only the FFI.
I wrote this because the Guile ncurses library refused to link on macOS, and it was a relatively 
simple and straightforward library.

Instead of curses, wizards cast spells.

# Usage

Consult the `example.scm` file for how to set this up.

# API

You should have some degree of familiarity with ncurses. 

## Starting

Before you can do anything with curses, you need to call the function `initscr`. 
Before your application exits, you must clean up the terminal by calling `endwin`. 

It might be worth it to add an exit handler that automatically cleans this up.

### Example 

    (initscr)
    ;; some code
    (endwin)

## Windows

Windows are created using the `new-win` function. Recall that windows __are not__ supposed to overlap. At the moment,
we provide no safegaurds against this. Don't do it.

All of the functions that you use to set attributes (primarily done with the `with-attributes` macro, more on that later...) 
modify the default window (\*stdscr\*, or from the C library, stdscr). However, if you use the macro `with-window`,
the window you provide will be modifed. 

### Example

    (define my-window (new-window *width* *height* *x0* *y0*))
    (with-window my-window
                (format "I like raisins"))

Or, more advanced, you can define a routine that performs a set of actions, and then use `with-window` to perform
the actions on windows. 
    
    (define say-hi (name)
      (format "Hi, ~a!" name))
      
    (with-window *stdscrn*
      (say-hi "world"))
      
In this example you can call say-hi in any `with-window` body and have the output formatted to the correct window.
        
## Attributes

A number of attributes are provided, including:
  * \*standout\* - highlight output
  * \*underline\* - underline output
  * \*reverse\* - swap the forground and background colors
  * \*diminished\* - fade text
  * \*bold\* - make text bold

In general, use the `with-attributes` macro to toggle these on and off.

### Example

    (with-attributes (*bold* *underline*)
      (format "Hello, world!"))
      
## Input 

Input can be obtained character-by-character using the `getch` function. To prevent echoing of the character,
call `no-echo`. To allow for the user to input special characters, invoke `(keypad #t)`. 

## Colors

There are a number of default colors:
  1. \*black\*
  2. \*red\*
  3. \*green\*
  4. \*yellow\*
  5. \*blue\*
  6. \*magenta\*
  7. \*cyan\*
  8. \*white\*
  
Users may also define their own color using the `make-color` function. Each color must be uniquely identified with
a numeric id. In principal, numbers after 50 are usually safe. You can test if a terminal supports defining colors by 
calling `change-color?`. Some terminals will report they can change colors, but will silently ignore color changing requests.

`make-color` allows you to call it with either a hexadecimal or RGB argument. So, you can call:

    (make-color my-id #:hexadecimal #xff0000)
    
or

    (make-color my-id #:red 255 #:green 0 #:blue 0)
    
To use these colors, assign them in a *color-pair*. You can create a color-pair using the `make-color-pair` function.
The color-pair 0 is defined as the default color pair, so you should pick a pair > 1. To use a color attribute, use the 
`with-attributes` macro with a call to `(color-pair <id>)`.

To get the default colors used by your terminal, make invoke `(use-default-colors)`

### Example

    (make-color-pair color-pair-id #:forground *red* #:background *white*)
    (with-attributes ((color-pair color-pair-id))
      (format "Pretty printing!"))

## Compatibility

I've confirmed this works on macOS, Debian, and Ubuntu. On Ubuntu and Debian I ran into an issue where 
the libncurses library wasn't symlinked correctly. Unfortunately, Guile simply emits a message stating "file not found"
whenever there is a dynamic link failure, regardless of the actual cause. 

## License

MIT License
Copyright (c) Maxwell Taylor, 2016
