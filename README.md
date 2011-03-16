# irssi-rainbow-parens

An [irssi](http://www.irssi.org/) script that displays matching brackets using matching colours.

## Setup

1. Place the script in `~/.irssi/scripts/autorun/`.
    * Perhaps create a symlink to it: `ln -s ~/irssi-rainbow-parens/rainbow-parens.pl ~/.irssi/scripts/autorun/rainbow-parens.pl`.
2. Run it with `/script load autorun/rainbow-parens`.
    * This should only be necessary once, as having it in the autorun directory will cause it to be loaded each time irssi starts.
3. Bind a key to `/rainbow-parens-toggle`. For example, `/bind meta-R /rainbow-parens-toggle`.
    * This, too, is only necessary once, because the binding is written to your `~/.irssi/config`.

## Usage

1. Type something in irssi.
2. Hit your binding for `/rainbow-parens-toggle` (meta-R (ie. alt-shift-r or esc-shift-r) in the above example).

## Examples

* Matching brackets of all sorts are coloured: ![rainbow](http://0.github.com/irssi-rainbow-parens/examples/rainbow.png).
* If that isn't possible, mismatched brackets are highlighted: ![mismatched](http://0.github.com/irssi-rainbow-parens/examples/mismatched.png).
* This is mostly useful for Lisping without indentation: ![lisp](http://0.github.com/irssi-rainbow-parens/examples/lisp.png).
* However, it works for anything: ![text](http://0.github.com/irssi-rainbow-parens/examples/text.png).
* Of course, it still won't save you from [drowning](http://0.github.com/irssi-rainbow-parens/examples/sea.png).

## Limitations

* Due to the nature of irssi's readline, it is not possible to add formatting directly in the input line, so an extra line is output to the screen instead.
