#print
fs = require 'fs'
path = require 'path'
cs = require 'coffee-script'
jade = require "jade"
mkdirp = require("mkdirp").sync
glob = require "glob"
us = require 'underscore'
request = require 'request'
jscover = require 'jscover'
yaml = require 'yamljs'

spawn = require('child_process').spawn
# jsp = require("uglify-js").parser;
# pro = require("uglify-js").uglify;

colorMap =
  black : 30
  red : 31
  green : 32
  yellow : 33
  blue : 34
  magenta : 35
  cyan : 36
  white : 37

color = (text, color="green") ->
  "\x1B[#{colorMap[color]}m#{text}\x1B[0m"

print = (name, args...) ->
  process.stdout.write "--------======== #{color name, "cyan"} ========--------\n"
  console.log args... if args.length > 0
  return

error = (name, args...) ->
  process.stderr.write "--------======== #{color "ERROR: "+name, "red"} ========--------\n"
  console.error args... if args.length > 0
  return

fileDelete = (p) ->
  p = path.join process.cwd(), p if p[0] isnt '/'
  try
    fs.unlinkSync p
  catch e


list = (includes, excludes) ->
  l = []
  includes = [includes] if typeof includes is 'string'
  excludes = [] if not excludes
  excludes = [excludes] if typeof excludes is 'string'
  l = l.concat glob.sync include for include in includes
  l = us.difference l, glob.sync exclude for exclude in excludes
  us.uniq(l).map (p) -> path.relative process.cwd(), p

run = (cmd, cb, instantPrint = true) ->
  cmd = cmd.split(' ');
  exec = spawn cmd[0], cmd[1..], {stdio: ['ignore', 'pipe', 'pipe'] }
  out = []
  err = []
  exec.stdout.on 'data', (data) ->
    if instantPrint then process.stdout.write data else out.push(data)
  exec.stderr.on 'data', (data) ->
    console.log(data.toString())
    if instantPrint then process.stderr.write data else err.push(data)
  if cb? then exec.on 'exit', (code) ->
    error 'Run cmd', cmd.join(' ') + '\n' if code > 1
    if instantPrint then cb code else cb code, out, err

httpGet = (url, file, cb) ->
  request url, (err, resp, body)->
    if err
      console.log "#{color "http get"}: \"#{url}\""
      cb err
    else
      console.log "#{color "http get"}: \"#{short file}\""
      fs.writeFileSync file, body
      cb
  return

short = (p, fix='') ->
  p.replace path.join(process.cwd(), fix) + '/', '';

coffee = (includes, excludes) ->
  l = list includes, excludes
  for file in l
    target = path.join path.dirname(file), "#{path.basename(file, '.coffee')}.js"
    content = fs.readFileSync(file).toString()
    content = cs.compile content, bare: true
    fs.writeFileSync target, content
    console.log "#{color "coffee"}: \"#{short file}\" => \"#{target}\""
  return

mocha = (includes, excludes, report='spec', cb) ->
  l = list includes, excludes
  print "Run Mocha Tests"
  cmd = "#{__dirname}/node_modules/.bin/mocha --compilers coffee:coffee-script --colors --reporter #{report} #{l.join ' '}"
  if cb? then run cmd, cb else run cmd

packageJson = ->
  fs.writeFileSync 'package.json', JSON.stringify(yaml.parse(fs.readFileSync('package.yaml').toString().trim()), null, 2) if fs.existsSync 'package.yaml'
  return


jscoverage = (dir, cb) ->
  tmp = dir+'.__tmp'
  fs.renameSync dir, tmp
  # cmd = __dirname + "/node_modules/visionmedia-jscoverage/jscoverage #{tmp} #{dir}"
  # console.log dir;
  # cb()
  # return;
  # # process.exit();
  jscover tmp, dir, null, (err, stdout)->
    treeDelete tmp
    console.log "#{color "jscoverage"}: \"#{short dir}\""
    cb()

  # console.log cmd
  # run cmd, ->
  #   treeDelete tmp
  #   console.log "#{color "jscoverage"}: \"#{short dir}\""
  #   cb()

coverage = (dirs, includes, excludes, cb) ->
  dirs = [dirs] if typeof dirs is 'string'
  flag = dirs.length;
  for dir in dirs
    jscoverage dir, ->
      if --flag is 0
        l = list includes, excludes
        cmd = __dirname + "/node_modules/.bin/mocha --colors --reporter json-cov #{l.join ' '}"
        run cmd, (code, outs, errs) ->
          size = 0
          size += out.length for out in outs
          buf = new Buffer size
          p = 0
          p += out.copy buf, p for out in outs
          # console.log buf.toString()
          report = JSON.parse buf.toString()
          file.filename = short file.filename for file in report.files
          cb code, report
        , false
    ,



testResult = (json) ->
  if json.failures.length is 0
    print "All #{json.passes.length} Tests Passed"
  else
    error "#{json.failures.length} Tests failures, #{json.passes.length} Tests Passed"
    console.log "#{color 'failure', 'red'}: #{test.fullTitle}" for test in json.failures
  console.log "#{color 'pass', 'green'}: #{test.fullTitle}" for test in json.passes

  print "Code Coverage: #{Math.round(json.coverage * 100) / 100}%"
  console.log "#{color file.filename}: #{Math.round(file.coverage * 100) / 100}%" for file in json.files

testReport = (name, data, tpl, file) ->
  data = {
    data : data
    name : name
  }
  if arguments.length == 3
    file = tpl
    tpl = __dirname + '/report/report.jade'
  fs.writeFileSync file, jade.compile(fs.readFileSync(tpl), {
    filename : tpl, pretty : false
  })(data)

treeDelete = (p) ->
  try
    p = path.join process.cwd(), p if p[0] isnt '/'
    return if not isDir p
    files = fs.readdirSync p
    if not files.length
      fs.rmdirSync p
      console.log "#{color "rmdir"}: \"#{short p}\""
    else
      for file in files
        p1 = path.join p, file
        if isDir p1
          treeDelete p1
        else
          fs.unlinkSync p1
          console.log "#{color "delete"}: \"#{short p1}\""
    fs.rmdirSync p
    console.log "#{color "rmdir"}: \"#{short p}\""
    return
  catch e
    return

isDir = (p) ->
  fs.existsSync(p) and fs.statSync(p).isDirectory()

mkdir = (p, mode="0755") ->
  if fs.existsSync p
    throw Error "Destination is not a directory (#{to}}." if not isDir p
  else
    mkdirp p, mode
    console.log "#{color "mkdir"}: \"#{short p}\""

listCopy = (to, includes, excludes) ->
  to = path.join process.cwd(), to if to[0] isnt '/'

  mkdir to
  if not fs.existsSync to
    mkdirp to, '0755'
    console.log "#{color "mkdir"}: \"#{short to}\""
  else
    throw Error "Destination is not a directory (#{short to}}." if not isDir to
  l = list includes, excludes
  for file in l
    toFile = path.join to, file
    if isDir file
      mkdir toFile
    else
      mkdir path.dirname toFile
      fs.linkSync file, toFile
      console.log "#{color "copy"}: \"#{short file}\" => \"#{short toFile}\""


  return

listDelete = (includes, excludes) ->
  l = list includes, excludes
  for file in l
    if not isDir file
      fs.unlinkSync file
      console.log "#{color "delete"}: \"#{short file}\""
  return

exports.run = run
exports.httpGet = httpGet
exports.mocha = mocha
exports.coverage = coverage
exports.testResult = testResult
exports.testReport = testReport
exports.coffee = coffee
exports.packageJson = packageJson

exports.print = print
exports.error = error
exports.list = list

exports.mkdirp = mkdirp
exports.listCopy = listCopy
exports.treeDelete = treeDelete
exports.listDelete = listDelete

