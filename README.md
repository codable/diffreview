Diff Review
===========

A simple tool utilize *quickfix* and [vim-fugitive](https://github.com/tpope/vim-fugitive) to review your code changes.

![diffreview][1]

Prerequisites
--------------

* VIM 8.0 or neovim
* vim-fugitive

Installation
------------

Place this in your .vimrc:

```
Plugin 'codable/diffreview'
```

Usage
-----

### Review changes from master

```
:Greview master
```

### Review changes in current working directory

```
:Greview
```

### Move to next file

Type `]q`.

### Move to prev file

Type `[q`.

[1]: https://user-images.githubusercontent.com/1522697/38250140-a59cd398-3780-11e8-93b8-8ee9e23e3138.png
