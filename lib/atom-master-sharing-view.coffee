SubAtom = require 'sub-atom'
subs = new SubAtom

# This creates the view that is displayed at the top.
module.exports =
class AtomMasterSharingView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('atom-master-sharing')

    @element.innerHTML = """
      <table class="table">
        <tr>
          <td>
            Enter path of your partner
          </td>
          <td>
            <atom-text-editor mini id="sharingPath" style="width: 300px">http://localhost:#{atom.config.get('atom-master-sharing.portForSharingDocument')}</atom-text-editor>
          </td>
        </tr>
      </table>
    """

    subs.add @element, 'core:confirm', =>
      pathElem = @element.querySelector('#sharingPath')
      root = pathElem.shadowRoot
      lines = root.querySelector('.text.plain')
      if lines? and @callback?
        url = lines.querySelector('.link.http.hyperlink')
        if url?
          @callback url.innerHTML
        else
          @callback lines.innerHTML

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  # This sets the callback that is called,
  # when the enter key is hit, while the URL is entered
  setCallback: (callback) ->
    @callback = callback