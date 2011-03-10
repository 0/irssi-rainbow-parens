# rainbow-parens

An [irssi](http://www.irssi.org/) plugin that displays matching brackets using matching colours.

## Setup

1. Place the script in `~/.irssi/scripts/autorun/` (perhaps create a symlink to it: `ln -s ~/rainbow-parens/rainbow-parens.pl ~/.irssi/scripts/autorun/rainbow-parens.pl).
2. Run it with `/script load autorun/rainbow-parens`. This should only be necessary once, as having it in the autorun directory will cause it to be loaded each time irssi starts.
3. Bind a key to `/rainbow-parens`. For example, `/bind meta-r /rainbow-parens`. This is only necessary once, because the binding is written to your `~/.irssi/config`.

## Usage

1. Type something in irssi.
2. Hit your binding for `/rainbow-parens` (meta-r (ie. alt-r or esc-r) in the above example).
