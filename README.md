# Csstoc: Work in progress 
:warning: This bash script is attended for Unix/Linux-based OS only.
## Usages 
`csstoc [-h] [-v] [-s] [-f filePath ] [--no-color]`
### Script description
Csstoc stands for 'css table of content'. It prints a table of content inside a .css or .scss files, based on user set titles. It is inspired by the way markdown allows generating toc.

### Available options

`-h, --help` Print this help and exit 
`-v, --verbose` Print script debug info 
`-f, --file` FilePath in which to generate a toc 
`-s, --standard-output` Print results to standard-output
`--no-color` Disable colours in output.

:warning: Concatenated flags like for example `-vs` are not supported.

### Requirements
In order to generate a csstoc, the following conditions must apply:
1. the css/scss file must have these two tags inside à block comment to delimit where toc should be placed.
```css 
<-- toc -->
<-- tocstop -->
```
2. Titles are identified like this:
- Level 1 Title 
`/*1# Title's name`

- Level 2 Title 
`/*2# Title's name`

- Level 3 Title 
`/*3# Title's name`

- Level 4 Title 
`/*4# Title's name`

## Installation
1. copy and paste the content of the `csstoc`file into a new file on your system and called it `csstoc`.
2. Make it executable with the command line `chmod +x csstoc`
3. Store the newly created file somewhere available to your `$PATH` variable.

### Bonus: easily accessible csstoc in Visual Studio Code
1. Install the vs code extension [Command Runner](https://github.com/edonet/vscode-command-runner).
2. In vs code, edit your `settings.json` to add your custom command.

```json 
"command-runner.commands": {
    "csstoc": "csstoc -f ${file}",
},
```

`${file}` equals to the current opened file.

3. Now you can effortlessly run your script from within the vs code command palette.