# Todos CLI #

Command line interface for todos-js.

- - -

This file is the entry point for the application.
Initializes the vorpal session.

We build the cli using vorpal, for starting the program we use commander.

    initVorpal = require './init-vorpal'

    Controller = require '../../todos-js/lib/controller'

    program = require 'commander'
    vorpal = (require 'vorpal')()

    fs = require 'fs'
    path = require 'path'

    pjson = require '../package.json'

Initialize commander.

Take the version of the program from the package.json file.

    program.version pjson.version

The commander command for starting our program.

      .description 'An application for managing hierarchical todo lists'
      .option '-f, --file <path>', 'path to file to read from and to save to'
      .option '-w, --working-todo <todo>',
        'starting current working todo (cwt), see help -cwt'
      .option '-a, --autosave <boolean>', 'use autosave, defaults to true'
      .option '-n, --no-welcome', 'do not output anything on startup'
      .option '-m, --markdown', 'render descriptions as markdown, defaults to true'
      .parse process.argv

Initialize the Controller.

    controller = new Controller program.file, program.autosave

    controller.loadTree program.workingTodo
    .then (result) ->
      initVorpal(vorpal, controller, program, true)
    , (error) ->
      controller.initTree program.workingTodo
      initVorpal(vorpal, controller, program, false)
