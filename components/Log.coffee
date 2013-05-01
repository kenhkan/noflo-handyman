noflo = require("noflo")
_ = require("underscore")
_s = require("underscore.string")
print = require("node-print")
util = require("util")

format = "%13s | %s"
padding = "              | "
log = []
count = 0
options =
  showHidden: false
  depth: 2
  colors: false

flush = ->
  print.pf "%s", "---------- NEW STREAM ----------"

  for l in log.reverse()
    print.pf "%s", ""
    print.pf format, "CONNECT", ""
    display l
    print.pf format, "DISCONNECT", ""

  print.pf "%s", ""
  print.pf "%s", "--------------------------------"
  print.pf "%s", ""
  print.pf "%s", ""

  log = []

display = (log) ->
  for packet, i in log
    packet = util.inspect packet,
      options.showHidden, options.depth, options.colors
    packet = packet.replace /\n/g, "\n#{padding}"
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
      options: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.options.on "data", (options) =>
      if _.isObject options
        for own key, value of options
          options[key] = value

    @inPorts.in.on "connect", =>
      count++
      @cache = []
      @groups = []

    @inPorts.in.on "begingroup", (group) =>
      here = @locate()
      here[group] = []
      @groups.push group
      @outPorts.out.beginGroup group if @outPorts.out.isAttached()

    @inPorts.in.on "data", (data) =>
      here = @locate()
      here.push data
      @outPorts.out.send data if @outPorts.out.isAttached()

    @inPorts.in.on "endgroup", (group) =>
      @groups.pop()
      @outPorts.out.endGroup() if @outPorts.out.isAttached()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect() if @outPorts.out.isAttached()

      log.push @cache
      count--
      flush() if count is 0

  locate: ->
    here = @cache
    here = here[group] for group in @groups
    here

exports.getComponent = -> new Log
