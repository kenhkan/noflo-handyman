noflo = require "noflo"
_ = require "underscore"

class Print extends noflo.Component

  description: "Print data packets as well as groups"

  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "connect", =>
      console.log "> CONNECT"

    @inPorts.in.on "begingroup", (group) =>
      console.log "> BEGINGROUP"
      console.log "  #{@prepareOutput group}"
      @outPorts.out.beginGroup group

    @inPorts.in.on "data", (data) =>
      console.log "> DATA"
      console.log "  #{@prepareOutput data}"
      @outPorts.out.send data

    @inPorts.in.on "endgroup", (group) =>
      console.log "> ENDGROUP"
      console.log "  #{@prepareOutput group}"
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      console.log "DISCONNECT"
      @outPorts.out.disconnect()

  prepareOutput: (data) ->
    JSON.parse JSON.stringify data

exports.getComponent = -> new Print
