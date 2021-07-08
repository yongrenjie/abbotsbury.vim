## abbotsbury.vim

Vim plugin which lets you expand DOIs into full citations, in a filetype-specific manner:

https://user-images.githubusercontent.com/22414895/124992953-95738400-e03b-11eb-908d-9c82aa80e5d5.mov

and provides autocompletion (with complete expansion to a citation) inside bib files (the entries are drawn from `abbot.yaml` files, created by the `abbot` reference manager):

https://user-images.githubusercontent.com/22414895/124993273-0e72db80-e03c-11eb-8c53-a2dcb4f8708b.mov


### Installation

```vim
Plug 'yongrenjie/abbotsbury.vim'  " vim-plug; similar for other plugin managers
```

Note that this plugin depends on the `abbot` command-line executable.
See https://github.com/yongrenjie/abbotsbury for instructions on how to install this.
