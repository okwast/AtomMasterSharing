clientTM = require 'mastersharingcore'
events = require 'events'
types = require './types'
{Color} = require 'atom'
{Point} = require 'atom'
{Range} = require 'atom'

# This is the main part of the plugin.
# It represents the document in which sharing takes place.
# Therefore a client of the MasterSharingCore module is created,
# which is called clientTM here.
module.exports =
  class EditorManager extends events.EventEmitter
    editor:           undefined
    buffer:           undefined
    tm:               undefined
    # See the description of the manual function for information
    # about manualEdited.
    manualEdited:     false
    options:          undo: 'skip'
    otherCursors:     []
    # firstConnector is a flag to know, wether this client is the
    # first connecting to the server or not
    firstConnector:   false

    # A new client is created, which connects to the given URL.
    # Callbacks are registered for important events.
    constructor: (@editor, url, @firstConnector) ->
      @buffer = @editor.buffer
      color = atom.config.get 'atom-master-sharing.color'
      @tm = clientTM.createClient url, "", color.toHexString()

      @bufferDo =>
        @buffer.onDidChange @bufferChanged

        @editor.onDidChangeSelectionRange @selectionChanged

        @tm.on types.initialized, @initialized
        @tm.on types.clear, @resetBuffer
        @tm.on types.textChange, @changeText
        @tm.on types.newUser, @newUser
        @tm.on types.userLeft, @userLeft
        @tm.on types.updateCursor, @changeCursor
        @tm.on 'end', ->
        @tm.on 'error', ->

    # This function is an important one.
    # It gets a function and executes it, but changes the
    # @manualEdited variable.
    # The @manualEdited variable controls,
    # whether an update of the editor has been applied by the user
    # or by another sharing partner.
    # That is important, because changes by someone else must not
    # be synchronized again, because that would result in an
    # infinite sharing loop
    manual: (callback) =>
      @manualEdited = true
      callback()
      @manualEdited = false

    notify: (msg) ->
      atom.notifications.addInfo msg

    warn: (msg) ->
      atom.notifications.addWarning msg

    error: (msg) ->
      atom.notifications.addError msg

    # This function gets called, when a change in the buffer happens.
    # If the change has been done by the sharing session
    # no further handling is neccessary and it must not be send to the server.
    # If the change is made by the user it is send to the server.
    bufferChanged: (event) =>
      return if @manualEdited
      if event.oldText is "" and event.newText isnt ""
        @tm.textChanged
          type:     types.textChange
          subtype:  types.insertion
          oldRange: event.oldRange
          newRange: event.newRange
          oldText:  event.oldText
          newText:  event.newText
      else if event.oldText isnt "" and event.newText is ""
        @tm.textChanged
          type:     types.textChange
          subtype:  types.deletion
          oldRange: event.oldRange
          newRange: event.newRange
          oldText:  event.oldText
          newText:  event.newText
      else if event.oldText? and event.oldText isnt "" and event.newText isnt ""
        @tm.textChanged
          type:     types.textChange
          subtype:  types.replacement
          oldRange: event.oldRange
          newRange: event.newRange
          oldText:  event.oldText
          newText:  event.newText
      else
        return

    # This function gets called, when a selection made by the user has changed.
    # The new selection position is then send to the server.
    selectionChanged: (event) =>
      @tm.cursorChanged
        type:  types.updateCursor
        range: event.newBufferRange

    # This function gets a callback and executes it, when the editor exists
    editorDo: (callback) =>
      if @editor?
        callback()
      else
        error "No Editor"

    # Same purpose as editorDo
    bufferDo: (callback) =>
      @editorDo =>
        if @buffer?
          callback()
        else
          @error "No Buffer"

    # This gets called, when the network is initialized
    # and the system is ready to start sharing
    initialized: =>
      @editorDo =>
        @editor.setCursorBufferPosition
          row:    0
          column: 0

    # Resets the buffer when the sharing starts
    resetBuffer: =>
      @bufferDo =>
        if @firstConnector
          @buffer.setText @buffer.getText()
        else
          @buffer.setText ""

    # Changes the text in the buffer
    changeText: (data) =>
      console.log 'changeText'
      @bufferDo =>
        @manual => @buffer.setTextInRange data.oldRange
        , data.newText, @options

    # A new user has connected
    newUser: (user) =>
      @addCursor user

    # A user left the session
    userLeft: (user) =>
      console.log "user left"
      @removeCursor user

    # New markers for a cursor and a selection are created.
    # To create the new cursor a new object is inserted to
    # the DOM tree.
    # The selection marker can be created via the atom API.
    # Also a line marker is added.
    addCursor: (transform) =>
      id = transform.clientId
      color = transform.color

      range =
        start:
          row:    0
          column: 0
        end:
          row:    0
          column: 0

      @editorDo =>

        root    = atom.views.getView(@editor).shadowRoot
        cursors = root.querySelector('.cursors')

        originalCursor = cursors.firstChild

        charWidth  = parseInt originalCursor.style.width
        lineHeight = parseInt originalCursor.style.height

        newCursor  = document.createElement('div')
        newCursor.classList.add('cursor')

        newCursor.style.borderLeftColor = color
        newCursor.style.height          = "#{lineHeight}px"
        newCursor.style.width           = "#{charWidth}px"
        newCursor.style.opacity         = 0.4
        newCursor.style.transform       = "translate(0, -100%)"

        marker = @editor.markBufferRange range,
          invalidate: 'never'

        cursorDecoration = @editor.decorateMarker marker,
          type:       'overlay'
          item:       newCursor
          class:      'cursorDecorationClass'
          onlyEmpty:  true

        lineDecoration = @editor.decorateMarker marker,
          type:       'line'
          class:      "atom-master-sharingLine#{transform.clientId}"

        string =
          """.atom-master-sharingSelection#{transform.clientId} div.region {
            background-color: #{color};
            opacity: 0.25;
          }
          .atom-master-sharingLine#{transform.clientId} {
            background-color: rgba(255,255,255,0.03);
          }"""

        root            = atom.views.getView(@editor).shadowRoot
        style           = root.getElementsByTagName('style')[0]
        style.innerHTML = style.innerHTML + string

        @otherCursors.push
          id:                   transform.clientId
          marker:               marker
          cursor:               newCursor
          cursorDecoration:     cursorDecoration

    createSelectionDecoration: (cursor) =>
      cursor.selectionDecoration = @editor.decorateMarker cursor.marker,
        type:  'highlight'
        class: "atom-master-sharingSelection#{cursor.id}"

    # Change the cursor of a user
    # The cursor will be hidden, if a selection is made
    changeCursor: (transform) =>
      for cursor in @otherCursors
        if cursor.id is transform.id
          cursor.marker.setBufferRange transform.range
          if @rangeIsEmpty transform.range
            cursor.cursor.style.visibility = 'visible'
            if cursor.selectionDecoration?
              cursor.selectionDecoration.destroy()
              cursor.selectionDecoration = undefined
          else
            cursor.cursor.style.visibility = 'hidden'
            @createSelectionDecoration cursor unless cursor.selectionDecoration?

    # Check wether a range is emtpy
    rangeIsEmpty: (range) ->
      range.start.row is range.end.row && range.start.column is range.end.column