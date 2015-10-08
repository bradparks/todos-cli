Todo = require '../../todos-js/lib/todo'
Path = require '../../todos-js/lib/path'

marked = require 'marked'
TerminalRenderer = require 'marked-terminal'
less = require 'vorpal-less'
parseInt = require 'parse-int'
chalk = require 'chalk'

fs = require 'fs'

module.exports = (vorpal, controller, program, foundFile) ->
  vorpal.controller = controller
  vorpal.program = program

  vorpal.updateDelimiter = ->
    if @controller.cwt is @controller.root
      cwtDisplayName = '/' if @controller.cwt is @controller.root
    else
      cwtDisplayName = Path.deescape @controller.cwt.model.name

    return @delimiter "[todos #{cwtDisplayName}]"

  error = (msg) ->
    vorpal.session.log chalk.red msg

  vorpal.command 'mk <name> [todo]'
    .description 'make a new todo, as child of [todo]'
    .alias 'add'
    .alias 'new'
    .alias 'create'
    .alias 'make'
    .option '-d, --description <description>', 'set description without prompting.'
    .option '-s, --done', 'sets the status to done, instead of pending.'
    .option '-i, --index <index>', 'index among the todo\'s siblings'
    .action (args, cb) ->
      if args.options.index?
        index = parseInt args.options.index
        unless index?
          error "#{args.options.index} is not an integer"
          return cb()
        if index < 0
          error "#{index} may not be below zero"
          return cb()

      name = Path.escape args.name
      description = args.options.description
      parent = controller.resolvePath (args.todo)

      makeTodo = ->
        todo = Todo name, description, args.options.done
        try
          controller.addChildAtIndex parent, todo, index
        catch err
          switch err.message
            when 'Invalid index.'
              error 'Index must be between zero and the number of siblings of the todo.'
            when 'Operation would have resulted in siblings with the same name.'
              error 'The name must be unique among the todo\'s siblings.'
            else
              error err
              error err.message
        finally
          cb()

      if description?
        makeTodo()
      else
        question =
          name: 'description'
          message: 'Description: '
          default: ''

        @.prompt question, (answer) ->
          description = answer.description
          makeTodo()

  vorpal.command 'file [path]'
    .description 'sets the file to which todos saves all data,
      or prints the current savefile if no argument is given'
    .option '-s, --save', 'immediately save to that file'
    .action (args, cb) ->
      if args.path?
        controller.file = args.path
      else
        @.log controller.file

      controller.save() if args.save?

      cb()

  vorpal.command 'save [path]'
    .description 'save to either the current savefile, or to path'
    .action (args, cb) ->
      controller.save(args.path)
      cb()

  vorpal.command 'autosave [boolean]'
    .description 'Set whether all changes to the todos should be saved immediately (true), or only when running save or exit (false). Prints the current setting if no boolean is passed.'
    .action (args, cb) ->
      if args.boolean?
        controller.autosave = args.boolean
      else
        @.log controller.autosave

      cb()

  vorpal.command 'pwd'
    .description 'Print the current working todo (cwt). See help --cwt for further information on the cwt.'
    .alias 'pwt'
    .action (args, cb) ->
      @.log controller.getCwtPath()
      cb()

  vorpal.command 'cd [todo]'
    .description 'Change the current working todo to the given one, or to `/` if nothing was passed. Works just like cd in a normal shell, including absolute/relative paths and `.` and `..`'
    .alias 'ct'
    .action (args, cb) ->
      args.todo = '/' unless args.todo?

      unless (controller.changeWorkingTodo args.todo)?
        @.log "#{args.todo} is not a valid todo. See help --cwt"

      vorpal.updateDelimiter()

      cb()

  vorpal.command 'ls [todo]'
    .description 'Show the current or the specified todo.'
    .action (args, cb) ->
      todo = (controller.resolvePath args.todo)

      all = todo.all -> return true

      for node in all
        prefix = ''
        for i in [0..node.getPath().length]
          prefix = "#{prefix}  "

        @.log "#{prefix}#{Path.deescape node.model.name}"
        @.log "#{prefix}#{node.model.description}"
        @.log "#{prefix}#{node.model.done}"
        @.log "#{prefix}#{node.model.dependencies}"

      cb()

  vorpal.command 'mv <index> [todo]'
    .description 'move a todo to the given index among its siblings'
    .action (args, cb) ->
      controller.moveChildToIndex controller.resolvePath(args.todo), args.index
      cb()

  vorpal.command 'rm [todo]'
    .description 'delete a todo'
    .action (args, cb) ->
      controller.dropNode controller.resolvePath args.todo
      cb()

  vorpal.command 'rn <name> [todo]'
    .description 'change the name to the given name'
    .alias 'rename'
    .alias 'setName'
    .action (args, cb) ->
      controller.setName controller.resolvePath(args.todo), Path.escape args.name
      vorpal.updateDelimiter()
      cb()

  vorpal.command 'sd <description> [todo]'
    .description 'change the description to the given description'
    .alias 'setDescription'
    .action (args, cb) ->
      controller.setDescription controller.resolvePath(args.todo), args.description
      cb()

  vorpal.command 'setdone <boolean> [todo]'
    .description 'change done to the given boolean'
    .action (args, cb) ->
      done = false
      if args.boolean is 'true'
        done = true
      if args.boolean is '1'
        done = true

      controller.setDone controller.resolvePath(args.todo), done
      cb()

  vorpal.command 'man'
    .description 'show the usage manual for todos-cli'
    .action (args, cb) ->
      output = ''

      try
        @.log marked fs.readFileSync("#{__dirname}/../README.md").toString()
      catch error
        @.log "Could not find README.md at #{__dirname}/../README.md"
        @.log error

      cb()

  marked.setOptions {renderer: new TerminalRenderer()}

  vorpal.use(less)
  .updateDelimiter()
  .show()

  unless program.noWelcome
    if foundFile
      vorpal.exec 'ls'
    else
      vorpal.session.log ''
      vorpal.session.log marked '# Welcome to todos-cli #'
      vorpal.session.log ''
      vorpal.session.log marked 'Run `help` for a quick overview of all available commands.\nOr type `man | less` for an explanation of the core concepts.'
