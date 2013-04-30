noflo = require("noflo")
_s = require("underscore.string")
print = require("node-print")

format = "%13s | %s"
log = []
count = 0

flush = ->
  console.log "---------- NEW STREAM ----------"

  for l in log.reverse()
    console.log ""
    print.pf format, "CONNECT", ""
    display l
    print.pf format, "DISCONNECT", ""

  console.log ""
  console.log "--------------------------------"
  console.log ""
  console.log ""

  log = []

display = (log) ->
  for packet, i in log
    print.pf format, "DATA", packet
    delete log[i]

  for group, l of log
    print.pf format, "BEGINGROUP", group
    display l
    print.pf format, "ENDGROUP", group

class Log extends noflo.Component

  description: _s.clean "Log all packets, groups, and disconnects, to be
  displayed on next tick."

  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "connect", =>
      count++
      @cache = []
      @groups = []

    @inPorts.in.on "begingroup", (group) =>
      here = @locate()
      here[group] = []
      @groups.push group
      @outPorts.out.beginGroup group

    @inPorts.in.on "data", (data) =>
      here = @locate()
      here.push data
      @outPorts.out.send data

    @inPorts.in.on "endgroup", (group) =>
      @groups.pop()
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

      log.push @cache
      count--
      flush() if count is 0

  locate: ->
    here = @cache
    here = here[group] for group in @groups
    here

exports.getComponent = -> new Log
