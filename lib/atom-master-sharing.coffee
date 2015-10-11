AtomMasterSharingView = require './atom-master-sharing-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomMasterSharing =
  atomMasterSharingView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomMasterSharingView = new AtomMasterSharingView(state.atomMasterSharingViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomMasterSharingView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-master-sharing:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomMasterSharingView.destroy()

  serialize: ->
    atomMasterSharingViewState: @atomMasterSharingView.serialize()

  toggle: ->
    console.log 'AtomMasterSharing was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
