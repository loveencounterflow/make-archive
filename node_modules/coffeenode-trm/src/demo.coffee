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
TRM.dir ( new Date() )

# goes to stderr:
log TRM.gold [ 1, 2, 3, ]

# goes to stdout:
echo 'redirect only this part with `>`'

# `TRM.pen` (think of 'to pen a text') is like `TRM.echo`, except it does not output anything
# but returns a textual representation of its arguments:
message = TRM.pen 'do you like', ( TRM.green 'colorful' ), ( TRM.pink 'outputs' ), '?'
log message.trim()
log rpr message

# convert colors in the message to spans:
log TRM.as_html message
