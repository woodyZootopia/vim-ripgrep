# vim-ripgrep

```vim
:Rg <string|pattern>
:LRg <string|pattern> "store to location list
```

Word under cursor will be searched if no argument is passed to `Rg`.
Selecting text in visual mode and `:Rg` will search selected text.

## configuration


| Setting                  | Default                     | Details
| ---------------------    | --------------------------- | ----------
| `g:rg_binary`            | `rg`                        | path to rg
| `g:rg_format`            | `%f:%l:%c:%m`               | value of grepformat
| `g:rg_option`            | `--vimgrep`                 | search command option
| `g:rg_highlight`         | `0`                         | true if you want matches highlighted
| `g:rg_derive_root`       | `0`                         | true if you want to find project root from cwd
| `g:rg_root_types`        | `['.git']`                  | list of files/dir found in project root
| `g:rg_use_location_list` | `0`                         | if `1`, use location list instead of quickfix list
| `g:rg_window_location`   | `botright`                  | quickfix window location
    
## misc

Show root search dir

```vim
:RgRoot
```
