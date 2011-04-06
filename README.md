# irssi-rainbow-parens

An [Irssi](http://www.irssi.org/) script that displays matching brackets using matching colours.

## Setup

1. Place the script in `~/.irssi/scripts/autorun/`.
    * Perhaps create a symlink to it: `ln -s ~/irssi-rainbow-parens/rainbow-parens.pl ~/.irssi/scripts/autorun/rainbow-parens.pl`.
2. Run it with `/script load autorun/rainbow-parens`.
    * This should only be necessary once, as having it in the autorun directory will cause it to be loaded each time Irssi starts.

## Configuration

These values hopefully have sane defaults, so need not be changed.

To change them, use the Irssi `/set` command; for example, `/set rainbow-parens-max_lines 2`.

* **rainbow-parens-min\_lines**: Minimum number of lines for the preview window. Integer value, greater than 1. _Default_: 2.
* **rainbow-parens-max\_lines**: Maximum number of lines for the preview window. Integer value, greater than or equal to **rainbow-parens-min\_lines**. _Default_: 8.

## Bindings

There are four public-facing commands which can be bound to keys.

To bind a key, use the Irssi `/bind` command; for example, `/bind meta-R /rainbow-parens-toggle`.

* **rainbow-parens-toggle**: This opens and closes a permanent window which is updated with each keystroke. _Suggested binding_: meta-R.
* **rainbow-parens-once**: This opens a temporary window which is closed upon the next keystroke. Primarily useful for verifying a single line.
* **rainbow-parens-prev**: Instead of displaying the contents of the input line, runs through the output buffer and colourizes the selected output line. _Suggested binding_: meta-P.
* **rainbow-parens-next**: Same as **rainbow-parens-prev**, but in the opposite direction. _Suggested binding_: meta-N.

## Examples

* Matching brackets of all sorts are coloured: ![rainbow](http://0.github.com/irssi-rainbow-parens/examples/rainbow.png).
* If that isn't possible, mismatched brackets are highlighted: ![mismatched](http://0.github.com/irssi-rainbow-parens/examples/mismatched.png).
* This is mostly useful for Lisping without indentation: ![lisp](http://0.github.com/irssi-rainbow-parens/examples/lisp.png).
* However, it works for anything: ![text](http://0.github.com/irssi-rainbow-parens/examples/text.png).
* Of course, it still won't save you from [drowning](http://0.github.com/irssi-rainbow-parens/examples/sea.png).

## Limitations

* Due to the nature of Irssi's readline, it is not possible to add formatting directly in the input line, hence the need for the extra window kludge.
