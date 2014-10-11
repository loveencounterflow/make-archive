

- [CoffeeNode Terminal (TRM)](#coffeenode-terminal-trm)
	- [Installation & Usage](#installation-&-usage)
	- [tl;dr](#tl;dr)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# CoffeeNode Terminal (TRM)

## Installation & Usage

On the command line:

    npm install coffeenode-trm

In your scripts:

```coffeescript

# These lines start many of my scripts:
TRM       = require 'coffeenode-trm'
rpr       = TRM.rpr.bind TRM
echo      = TRM.echo.bind TRM
badge     = 'demo'
log       = TRM.get_logger 'plain', badge
info      = TRM.get_logger 'info',  badge
alert     = TRM.get_logger 'alert', badge
debug     = TRM.get_logger 'debug', badge
warn      = TRM.get_logger 'warn',  badge
help      = TRM.get_logger 'help',  badge

info "colors!"
alert "something went wrong"
TRM.dir ( [] )

# goes to stderr:
log TRM.gold [ 1, 2, 3, ]

# goes to stdout without the 'badge':
echo 'redirect only this part with `>`'

# `TRM.pen` (think of 'to pen a text') is like `TRM.echo`, except it does not output anything
# but returns a textual representation of its arguments:
message = TRM.pen 'do you like', ( TRM.green 'colorful' ), ( TRM.pink 'outputs' ), '?'
log message.trim()

# `rpr` (short for: 'representation') gives you a `( require 'util' ).inspect`-like output; it is applied
# by all `TRM` logging functions by default to avoid any `[object Object]` nonsense; apply it explicitly
# to get a view into strings.
log rpr 242 # same as `log 242` (true for all values except texts)

# output: demo  ▶  'do you like \u001b[38;05;34mcolorful\u001b[0m \u001b[38;05;199moutputs\u001b[0m ?\n'
log rpr message

# convert colors in the message to HTML spans.
# output: demo  ▶  do you like <span class='ansi-m-38-5-34'>colorful</span> <span class='ansi-m-38-5-199'>outputs</span> ?
log TRM.as_html message

```

## tl;dr

TRM is a library to do simplify doing colorful stuff and meaningful outputs on the command line.

