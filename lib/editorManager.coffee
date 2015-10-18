clientTM = require 'mastersharingcore'
events = require 'events'
types = require './types'
{Color} = require 'atom'
{Point} = require 'atom'
{Range} = require 'atom'

module.exports =
  class EditorManager extends events.EventEmitter
    editor:           undefined
    buffer:           undefined
    tm:               undefined
    manualEdited:     false
    options:          undo: 'skip'
    otherCursors:     []

    constructor: (@editor, url) ->
      @buffer = @editor.buffer
      @tm = clientTM.createClient url, "Test", 'white'

      console.log '@tm'
      console.log @tm

      @bufferDo =>
        @buffer.onDidChange @bufferChanged

        @editor.onDidChangeSelectionRange @selectionChanged

        @tm.on types.initialized, @initialized
        @tm.on types.clear, @clearBuffer
        # @tm.on types.textChange, (x) ->
        #   console.log 'textChange'
        #   console.log 'x'
        @tm.on types.textChange, @changeText
        @tm.on types.newUser, @newUser
        @tm.on types.userLeft, @userLeft
        @tm.on types.updateCursor, @changeCursor
        @tm.on 'end', ->
        @tm.on 'error', ->

    parseUrl: (url) ->
      url = url.split ':'
      {host: url[0], port: url[1]}

    manual: (callback) =>
      @manualEdited = true
      callback()
      @manualEdited = false

    notify: (msg) ->
      # @emit 'info', msg
      atom.notifications.addInfo msg

    warn: (msg) ->
      # @emit 'warn', msg
      atom.notifications.addWarning msg

    error: (msg) ->
      # @emit 'error', msg
      atom.notifications.addError msg

    bufferChanged: (event) =>
      console.log 'bufferChanged'
      console.log event
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

    # cursorChanged: (event) =>
    #   @tm.cursorChanged
    #     type: types.updateCursor
    #     pos:  event.newScreenPosition

    selectionChanged: (event) =>
      @tm.cursorChanged
        type:  types.updateCursor
        range: event.newBufferRange

    editorDo: (callback) =>
      if @editor?
        callback()
      else
        # @emit 'noEditor'
        error "No Editor"
        #TODO react to problem

    bufferDo: (callback) =>
      @editorDo =>
        if @buffer?
          callback()
        else
          # @emit 'noBuffer'
          @error "No Buffer"
          #TODO react to problem

    initialized: =>
      console.log 'initialized'
      @editorDo =>
        @editor.setCursorBufferPosition
          row:    0
          column: 0

    clearBuffer: =>
      @bufferDo =>
        @buffer.setText ""

    changeText: (data) =>
      console.log 'changeText'
      @bufferDo =>
        @manual => @buffer.setTextInRange data.oldRange
        , data.newText, @options

    newUser: (user) =>
      @addCursor user

    userLeft: (user) =>
      @removeCursor user

    addCursor: (transform) =>
      #TODO ugly
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
          class:      "collaborationManLine#{transform.clientId}"

        string =
          """.collaborationManSelection#{transform.clientId} div.region {
            background-color: yellow;
            opacity: 0.25;
          }
          .collaborationManLine#{transform.clientId} {
            background-color: rgba(255,255,0,0.03);
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
        class: "collaborationManSelection#{cursor.id}"

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

    rangeIsEmpty: (range) ->
      range.start.row is range.end.row && range.start.column is range.end.column