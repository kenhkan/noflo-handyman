noflo = require "noflo"

class Quit extends noflo.Component

  description: "Quit the Node.js session"

  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "disconnect", =>
      process.exit()

exports.getComponent = -> new Quit
