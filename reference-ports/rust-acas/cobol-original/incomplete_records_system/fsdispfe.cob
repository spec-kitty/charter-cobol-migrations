 display-file-error.
*>------------------
      if      fs-reply not = zero
              display "error code = " at 2430  with foreground-color 4
              display fs-reply at 2443 with foreground-color 4
              display "Hit return to continue" at 2448
              accept fs-reply at 2472.
