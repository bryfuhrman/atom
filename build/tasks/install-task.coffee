fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
runas = null

fillTemplate = (filePath, data) ->
  template = _.template(String(fs.readFileSync(filePath + '.in')))
  filled = template(data)
  fs.writeFileSync(filePath, filled)

module.exports = (grunt) ->
  {cp, mkdir, rm} = require('./task-helpers')(grunt)

  grunt.registerTask 'install', 'Install the built application', ->
    installDir = grunt.config.get('atom.installDir')
    shellAppDir = grunt.config.get('atom.shellAppDir')
    if process.platform is 'win32'
      runas ?= require 'runas'
      copyFolder = path.resolve 'script', 'copy-folder.cmd'
      if runas('cmd', ['/c', copyFolder, shellAppDir, installDir], admin: true) isnt 0
        grunt.log.error("Failed to copy #{shellAppDir} to #{installDir}")

      createShortcut = path.resolve 'script', 'create-shortcut.cmd'
      runas('cmd', ['/c', createShortcut, path.join(installDir, 'atom.exe'), 'Atom'])
    else if process.platform is 'darwin'
      rm installDir
      mkdir path.dirname(installDir)
      cp shellAppDir, installDir
    else
      binDir = path.join(installDir, 'bin')
      shareDir = path.join(installDir, 'share', 'atom')

      iconName = path.join(shareDir,'resources','app','resources','atom.png')
      desktopFile = path.join('resources', 'linux', 'Atom.desktop')

      mkdir binDir
      cp 'atom.sh', path.join(binDir, 'atom')
      rm shareDir
      mkdir path.dirname(shareDir)
      cp shellAppDir, shareDir

      # Create Atom.desktop if installation in '/usr/local'
      applicationsDir = path.join('/usr','share','applications')
      if installDir is '/usr/local' and fs.isDirectorySync(applicationsDir)
        {description} = grunt.file.readJSON('package.json')
        fillTemplate(desktopFile, {description, installDir, iconName})
        cp desktopFile, path.join(applicationsDir,'Atom.desktop')

      # Create relative symbol link for apm.
      process.chdir(binDir)
      rm('apm')
      fs.symlinkSync(path.join('..', 'share', 'atom', 'resources', 'app', 'apm', 'node_modules', '.bin', 'apm'), 'apm')

      fs.chmodSync(path.join(shareDir, 'atom'), "755")
