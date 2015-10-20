AtomMasterSharingView = require './atom-master-sharing-view'
{CompositeDisposable} = require 'atom'
editorManager = require './editorManager'
# testEditor = require './testEditor'
msc = require 'mastersharingcore'


# This is the entry point of the atom master sharing plugin.
# In this file commands for activation are set.
module.exports = AtomMasterSharing =
  atomMasterSharingView: null
  modalPanel: null
  subscriptions: null
  server: undefined

  # Set up the settings that are visible in the settings view
  # of this plugin
  config:
    username:
      type: 'string'
      default: 'Username'
    color:
      type: 'color'
      default: 'blue'
    portForSharingDocument:
      type: 'integer'
      default: '8989'

  # Initialize this plugin on startup
  activate: (state) ->
    # Create the view for entering the address of your sharing partner
    @atomMasterSharingView = new
      AtomMasterSharingView(state.atomMasterSharingViewState)
    @modalPanel = atom.workspace.addModalPanel(
      item: @atomMasterSharingView.getElement(),
      visible: false
    )

    # Events subscribed to in atom's system can be easily
    # cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands, which are allowed to trigger the
    # activation of this plugin
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:connect': => @connect()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:startSharing': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:showMenu': => @showMenu()

  # Deactivation of plugin
  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomMasterSharingView.destroy()

  serialize: ->
    atomMasterSharingViewState: @atomMasterSharingView.serialize()

  # Start a sharing session
  # This function creates a server with the port specified in the settings view
  # Afterwards a client is created, which directly connects to the server
  startSession: ->
    if (editor = atom.workspace.getActiveTextEditor()) and !editor.manager?
      port = atom.config.get 'atom-master-sharing.portForSharingDocument'

      @server = msc.createServer port

      editor.manager = new editorManager editor
      , "http://localhost:#{port}", true

      editor.manager.notify "Started sharing on port #{port}"
    # if server.isActive
    #   server.stop()
    #   console.log 'Server has been shut down.'
    # else
    #   server.start atom.config.get('package.portForSharingDocument')
    #   console.log "Server was started on port:"+
    #   " #{atom.config.get('package.portForSharingDocument')}"

  # Calling this function opens a view at the top of the window.
  # There you can enter an URL with a port and hit enter.
  # Then a new editorManager is created.
  # Each editor manager handles one editor.
  # In general an editor is nothing more than a document,
  # which can be opened in multiple windows.
  connect: ->
    if !@modalPanel.isVisible()
      @modalPanel.show()
      @atomMasterSharingView.setCallback (path) =>
        @modalPanel.hide()
        if (editor = atom.workspace.getActiveTextEditor()) and !editor.manager?
          editor.manager = new editorManager editor, path
          editor.manager.notify "Connected to partner"

  # This function toggles the visibility of the view at the top
  # so that it can be closed without connecting to a sharing session.
  showMenu: ->
    console.log atom.config.get('atom-master-sharing.portForSharingDocument')
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()