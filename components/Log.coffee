noflo = require "noflo"
_ = require "underscore"
print = require "node-print"
util = require "util"
{ deepCopy } = require "owl-deepcopy"

emptyFormat = "-"
displayFormat = "- %13s | %s"
padding = "-               | "
log = []
count = 0
options =
  showHidden: false
  depth: 2
  colors: false

flush = ->
  print.pf "%s", "------------ STREAM ------------"

  for l in log.reverse()
    print.pf emptyFormat
    print.pf displayFormat, "CONNECT", ""
    display l
    print.pf displayFormat, "DISCONNECT", ""

  print.pf emptyFormat
  print.pf "%s", "--------------------------------"
  print.pf emptyFormat
  print.pf emptyFormat

  log = []

display = (log) ->
  for packet, i in log.__CONTENT__ or []
    packet = util.inspect packet, options
    packet = packet.replace /\n/g, "\n#{padding}"
    print.pf displayFormat, "DATA", packet
    delete log.__CONTENT__

  for group, l of log
    print.pf displayFormat, "BEGINGROUP", group
    display l
    print.pf displayFormat, "ENDGROUP", group

class Log extends noflo.Component

  description: "Log all packets, groups, and disconnects, when the
  entire stream is complete."

  constructor: ->
    @tag = null

    @inPorts =
      in: new noflo.Port
      options: new noflo.Port
      tag: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.options.on "data", (opts) =>
      if _.isObject opts
        for own key, value of opts
          options[key] = value

    @inPorts.tag.on "data", (@tag) =>

    @inPorts.in.on "connect", =>
      count++
      @cache = {}
      @groups = []

      if @tag?
        @cache[@tag] ?= {}
        @groups.push @tag

    @inPorts.in.on "begingroup", (group) =>
      here = @locate()
      here[group] ?= []
      @groups.push group
      @outPorts.out.beginGroup group if @outPorts.out.isAttached()

    @inPorts.in.on "data", (data) =>
      here = @locate()
      here.__CONTENT__ ?= []
      here.__CONTENT__.push deepCopy data
      @outPorts.out.send data if @outPorts.out.isAttached()

    @inPorts.in.on "endgroup", (group) =>
      @groups.pop()
      @outPorts.out.endGroup() if @outPorts.out.isAttached()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect() if @outPorts.out.isAttached()

      @groups.pop() if @tag?

      log.push @cache
      count--
      flush() if count is 0

  locate: ->
    here = @cache
    here = here[group] for group in @groups
    here

exports.getComponent = -> new Log
