AtomMasterSharingView = require './atom-master-sharing-view'
{CompositeDisposable} = require 'atom'
editorManager = require './editorManager'
# testEditor = require './testEditor'
msc = require 'mastersharingcore'

module.exports = AtomMasterSharing =
  atomMasterSharingView: null
  modalPanel: null
  subscriptions: null
  server: undefined

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

  activate: (state) ->
    @atomMasterSharingView = new
      AtomMasterSharingView(state.atomMasterSharingViewState)
    @modalPanel = atom.workspace.addModalPanel(
      item: @atomMasterSharingView.getElement(),
      visible: false
    )

    # Events subscribed to in atom's system can be easily
    # cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:connect': => @connect()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:startSession': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:showMenu': => @showMenu()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-master-sharing:startTest': => @startTest()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomMasterSharingView.destroy()

  serialize: ->
    atomMasterSharingViewState: @atomMasterSharingView.serialize()

  startSession: ->
    if (editor = atom.workspace.getActiveTextEditor()) and !editor.manager?
      console.log "Server started"
      port = atom.config.get 'atom-master-sharing.portForSharingDocument'
      port = 8989

      console.log 'msc'
      console.log msc

      @server = msc.createServer port

      editor.manager = new editorManager editor
      , "http://localhost:#{port}"

      editor.manager.notify "Started sharing on port #{port}"
    # if server.isActive
    #   server.stop()
    #   console.log 'Server has been shut down.'
    # else
    #   server.start atom.config.get('package.portForSharingDocument')
    #   console.log "Server was started on port:"+
    #   " #{atom.config.get('package.portForSharingDocument')}"

  connect: ->
    # console.log 'Package was toggled!'
    # client.start 'localhost', 8989
    console.log "Client started"
    if !@modalPanel.isVisible()
      @modalPanel.show()
      @atomMasterSharingView.setCallback (path) =>
        @modalPanel.hide()
        # atom.workspace.open()
        if (editor = atom.workspace.getActiveTextEditor()) and !editor.manager?
          editor.manager = new editorManager editor, path
          editor.manager.notify "Connected to partner"

        # s = path.split ':'
        # host = s[0]
        # port = s[1]
        # console.log host
        # console.log port
        # client.start host, port

  showMenu: ->
    console.log atom.config.get('atom-master-sharing.portForSharingDocument')
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  # startTest: ->
  #   console.log "Test started"
  #   if !@modalPanel.isVisible()
  #     @modalPanel.show()
  #     @packageView.setCallback (path) =>
  #       @modalPanel.hide()
  #       # atom.workspace.open()
  #       if (editor = atom.workspace.getActiveTextEditor())
  #and !editor.manager?
  #         tester = new testEditor path