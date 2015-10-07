# Todos CLI #

Command line interface for managing hierarchical todo lists.

## Features: ##
- pretty awesome cli
- each todo has a name, a description and a status (pending or done)
- arbitrarily nestable todos
- todos may declare dependencies on other todos
- serializes to yaml

## Core Concepts ##

Take a few minutes to read this section, to get an overview of how todos-cli works. It's nothing complicated, and its usage should then be fairly self-explanatory.

### Todos ###

Todos-cli reads, writes and manipulates *todos*. Each *todo* has a *name*, a *description*, and may be either *pending* or *done*.

*Todos* may contain any number of *children* *todos*, resulting in a tree structure. The name of each *todo* must be unique among its siblings. A *todo* which is *done* may not have any *pending* children.

Furthermore, *todos* can depend on others. A *todo* which is *done* may not have any *pending* dependencies.

- - -

The cli provides commands to create, move and remove *todos*, set and change these values, and to print and filter them.

### Navigation ###

To easily address *todos*, the cli uses an analogy to a file system. There always is a *current working todo* (*cwt*) on which commands operate unless otherwise specified.

*Todos* may be addressed by giving a path, consisting of the names of the ancestors and its own name, separated by a `/`. These paths are interpreted relative to the *current working todo*. A path starting with a `/` is an absolute path, which is resolved independent of the cwt.

A quick example:

- /
  - foo
    - bar
  - baz

`/foo/bar` would absolutely address `bar`, the relative path from `bar` to `baz` is `../../baz`. As you can see, using `..` to refer to the parent *todo* is supported, so is `.` to explicitly refer to the current *todo*. Autocompletion using tab is supported.

If the name of a todo contains a `/` or `\\`, it must be escaped as `\/` or `\\` in the path.

All commands which take a [todo] as an argument expect such a path.

The commands for navigating the todo tree are analogues to the usual terminal commands: `pwd` to print the *current working todo*, `cd` to change it, and `ls` to show the todos.

## Usage ##

Run `todos` to start an [immersive session](https://github.com/dthree/vorpal#what-is-an-immersive-cli-app) with the following commands:

### Manipulating Todos ###

- create new
- delete
- move
- copy
- setIndex
- moveUp
- moveDown

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

- - -

`man`



- - -

- |  less
- arguments and options for running todos

## Stuff to implement before first release ##

- TODO man command for displaying this readme
- TODO depend on todos-js, change require calls to absolute
- TODO package.json updates
- TODO write the readme
- TODO split code into more files
- TODO help --todo
- TODO help --cwt
- TODO chalk, markdown, pretty output
- TODO rework all command descriptions and misc output
- TODO include vorpal-less and maybe other extensions
- TODO save on exit
- TODO autocompletion for todo-paths
