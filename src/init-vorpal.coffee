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

  warn = (msg) ->
    vorpal.session.log chalk.yellow msg

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

  vorpal.command 'rm [todos...]'
    .description 'delete todos'
    .alias 'remove'
    .alias 'del'
    .alias 'delete'
    .option '-r, --recursive', 'remove children without prompting'
    .action (args, cb) ->
      todos = []

      if args.todos?
        for t in args.todos
          node = controller.resolvePath t
          if node?
            todos.push node
          else
            warn "skipping #{t}, that is not a valid path to a todo"

      todos.push controller.cwt if todos.length is 0 and not args.todos?

      questions = []
      unless args.recursive
        for todo in todos
          if todo.children.length > 0
            path = Path.renderPath todo
            question =
              name: "confirm#{path}"
              message: "#{path} has child-todos. Delete anyways? (Y/n)"
              default: true
              todo: todo
            questions.push question

      for todo in todos
        if todo is controller.root
          rootQuestion =
            name: "confirm#{Path.renderPath todo}"
            message: 'You are about to delete the root-todo. This will delete everything and create a new, empty root. Continue anyways? (y/N)'
            default: false
            todo: todo
          questions = [rootQuestion]

      if questions.length is 0
        for todoToDelete in todos
          controller.dropNode todoToDelete

        vorpal.updateDelimiter()
        cb()
      else
        @.prompt questions, (answers) ->
          for todoToDelete in todos
            ans = answers["confirm#{Path.renderPath todoToDelete}"]
            if ans?
              unless ans is 'n' or ans is 'N' or ans is 'no' or ans is 'No' or ans is 'false' or ans is false
                controller.dropNode todoToDelete
            else
              controller.dropNode todoToDelete

          vorpal.updateDelimiter()
          cb()

  vorpal.command 'mv [todo] <index>'
    .alias 'move'
    .description 'move a todo among its siblings'
    .option '-r, --relative', 'add index to the current index'
    .action (args, cb) ->
      node = controller.resolvePath args.todo

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      if node is controller.root
        error 'Can not move the root.'
        return cb()

      index = args.index
      index += node.parent.children.indexOf node if args.options.relative?

      try
        controller.moveChildToIndex node, index
      catch err
        switch err.message
          when 'Invalid index.'
            error 'Index must be between zero and the number of siblings of the todo.'
          else
            error err
            error err.message
      finally
        cb()

  vorpal.command 'sn [todo] [name]'
    .description 'set the name to the given name'
    .alias 'setName'
    .alias 'rn'
    .alias 'rename'
    .action (args, cb) ->
      setName = (name) ->
        try
          controller.setName node, Path.escape name
        catch err
          switch err.message
            when 'Operation would have resulted in siblings with the same name.'
              error 'Name already taken by a sibling.'
        vorpal.updateDelimiter()
        cb()

      node = controller.resolvePath args.todo

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      if node is controller.root
        error 'Can not rename the root.'
        return cb()

      if args.name?
        setName args.name
      else
        question =
          name: 'name'
          message: 'Enter new name: '
          default: ''

        @.prompt question, (answer) ->
          setName(answer.name)

  vorpal.command 'sd [todo] [description]'
    .description 'set the description to the given text'
    .alias 'setDescription'
    .action (args, cb) ->
      node = controller.resolvePath args.todo

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      if args.description?
        controller.setDescription node, args.description
        return cb()
      else
        question =
          name: 'description'
          message: 'Enter new description: '
          default: ''

        @.prompt question, (answer) ->
          controller.setDescription node, answer.description
          return cb()

  vorpal.command 'done [todo]'
    .description 'set the status to done'
    .action (args, cb) ->
      node = controller.resolvePath args.todo

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      controller.setDone node, true
      cb()

  vorpal.command 'pending [todo]'
    .description 'set the status to pending'
    .action (args, cb) ->
      node = controller.resolvePath args.todo

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      controller.setDone node, false
      cb()

  vorpal.command 'ad [todo] <dependency>'
    .description 'add a dependency'
    .alias 'addDependency'
    .option '-i, --index', 'the index at which to add the dependency'
    .action (args, cb) ->
      node = controller.resolvePath args.todo
      dep = controller.resolvePath args.dependency

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      unless dep?
        error "#{args.dependency} is not a valid path to a todo"
        return cb()

      result = controller.addDependencyAtIndex node, dep, args.options.index
      if result is null
        error 'Invalid dependency: circular, or on child or ancestor'
      cb()

  vorpal.command 'rd [todo] <dependency>'
    .description 'remove a dependency'
    .alias 'removeDependency'
    .action (args, cb) ->
      node = controller.resolvePath args.todo
      dep = controller.resolvePath args.dependency

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      unless dep?
        error "#{args.dependency} is not a valid path to a todo"
        return cb()

      controller.removeDependency node, dep
      cb()

  vorpal.command 'md [todo] <dependency> <index>'
    .alias 'moveDependency'
    .description 'move a dependency among its siblings'
    .option '-r, --relative', 'add index to the current index'
    .action (args, cb) ->
      node = controller.resolvePath args.todo
      dep = controller.resolvePath args.dependency

      unless node?
        error "#{args.todo} is not a valid path to a todo"
        return cb()

      unless dep?
        error "#{args.dependency} is not a valid path to a todo"
        return cb()

      index = args.index
      index += node.model.dependencies.indexOf(Path.renderPath dep) if args.options.relative?

      try
        controller.moveDependencyToIndex node, dep, index
      catch err
        switch err.message
          when 'Invalid index.'
            error 'Index must be between zero and the number of siblings of the dependency.'
          else
            error err
            error err.message
      finally
        cb()

  vorpal.command 'pwd'
    .description 'print the current working todo'
    .alias 'pwt'
    .action (args, cb) ->
      @.log controller.getCwtPath()
      cb()

  vorpal.command 'cd [todo]'
    .description 'change current working todo'
    .alias 'ct'
    .action (args, cb) ->
      args.todo = '/' unless args.todo?

      unless (controller.changeWorkingTodo args.todo)?
        error "#{args.todo} is not a valid path to a todo"

      vorpal.updateDelimiter()

      cb()

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
