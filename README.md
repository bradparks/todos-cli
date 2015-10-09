# Todos CLI #

Command line interface for managing hierarchical todo lists.

## Features: ##
- pretty awesome cli
- each todo has a name, a description and a status (pending or done)
- arbitrarily nestable todos
- todos may declare dependencies on other todos
- serializes to yaml

## Core Concepts ##

Take a few minutes to read this section, to get an overview of how todos-cli works.
It's nothing complicated, and its usage should then be fairly self-explanatory.

### Todos ###

Todos-cli reads, writes and manipulates *todos*.
Each *todo* has a *name*, a *description*, and may be either *pending* or *done*.

*Todos* may contain any number of *children* *todos*, resulting in a tree structure.
The name of each *todo* must be unique among its siblings.
A *todo* which is *done* may not have any *pending* children.

Furthermore, *todos* can depend on others.
A *todo* which is *done* may not have any *pending* dependencies.

- - -

The cli provides commands to create, move and remove *todos*,
to set and change these values, and to print and filter them.

### Navigation ###

To easily address *todos*, the cli uses an analogy to a file system.
There always is a *current working todo* (*cwt*) on which commands operate unless otherwise specified.

*Todos* may be addressed by giving a path, consisting of the names of the ancestors and its own name, separated by a `/`.
These paths are interpreted relative to the *current working todo*.
A path starting with a `/` is an absolute path, which is resolved from the root.

A simple example todo-tree:

- /
  - foo
    - bar
  - baz

`/foo/bar` would absolutely address `bar`, the relative path from `bar` to `baz` is `../../baz`.
As you can see, using `..` to refer to the parent *todo* is supported, so is `.` to explicitly refer to the current *todo*.
Autocompletion using tab works as well.

If the name of a todo contains a `/` or `\`, it must be escaped as `\/` or `\\` in the path.

All commands which take a `[todo]` as an argument expect such a path.

The commands for navigating the todo tree are analogues to the usual terminal commands:
`pwd` to print the *current working todo*, `cd` to change it, and `ls` to show the todos.

## Usage ##

Run `todos` to start an [immersive session](https://github.com/dthree/vorpal#what-is-an-immersive-cli-app) with the following commands:

### Manipulating Todos ###

- - -

#### Creating Todos ####

`mk [options] <name> [todo]`

Alias: `add` | `new` | `create` | `make`

Creates a new todo, adding it as a child of the current working todo.
When giving a path to another todo, that todo is the parent for the new one.

Prompts for the description, unless it is given via the `-d` option.
Descriptions are rendered as [markdown](https://daringfireball.net/projects/markdown/).

The default status for a new todo is pending.
To create a todo as already done, pass the `-s` flag.

The new todo is added as the last child, unless an index is specified via the `-i` option.

Options:
```
  --help                           output usage information
  -d, --description <description>  set description without prompting.
  -s, --done                       sets the status to done, instead of pending.
  -i, --index <index>              index among the todo's siblings
```
- - -

#### Removing Todos ####

`rm [options] [todos...]`

Alias: `remove` | `del` | `delete`

Deletes either the current working todo, or any number of specified todos.

Unless the `-r` flag is used, this asks for confirmation when deleting a parent todo.  
Will always ask for confirmation before deleting the root todo.

When deleting the cwt, the parent of the old cwt becomes the new cwt.  
When deleting the root, a new, empty root is created.

Options:
```
  --help           output usage information
  -r, --recursive  remove children without prompting
```
- - -

#### Moving Todos ####

`mv [options] [todo] <index>`

Alias: `move`

Move a given todo (or the current working todo if none is specified) to a new place among its siblings.
With the `-r` flag, the index is given relative to the current position.

Options:
```
  --help          output usage information
  -r, --relative  add index to the current index
```
- - -
### View Todos ###
- ls (filter rows, filter columns, render markdown)
- show dependencies
- show dependents

### Setting values ###

- setName
- setDescription
- setStatus
- addDependency
- removeDependency
- moveDependencyToIndex

### Navigation ###

- pwd
- cd

### Persistence ###
- autosave
- file
- save

### Miscellaneous ###
- help
- tour

- - -

#### Usage Manual ####

`man`

Show the readme.md for the module in the terminal.

- - -

#### Viewing Less Output ####

` | less`

todos-cli comes with the [vorpal-less](https://github.com/vorpaljs/vorpal-less) extension.
Just write ` | less` behind a command to view the output in less mode.
Run `less --help` for more information on how to use vorpal-less.

- - -

- arguments and options for running todos TODO: move to top of usage section

## Stuff to implement before first release ##

- TODO all commands
- TODO save on exit
- TODO autocompletion for todo-paths
- TODO depend on todos-js, change require calls to absolute
- TODO package.json updates
- TODO handle errors on save
- TODO render descriptions as md
- TODO add --preserve-root to rm
- TODO allow mk to create necessary parents
- TODO implement tour
