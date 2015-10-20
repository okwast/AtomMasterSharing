# AtomMasterSharing

This is an Atom plugin using the MasterSharing System for distributed group programming.

The system allows you to share a document with friends and colleagues for collaborative work.

## Usage

### Start Sharing
Only open a document and do one of these:
- search for the 'Atom Master Sharing: StartSharing' command in the command palette and execute it
- select it in the menu: Packages -> Atom Master Sharing -> StartSharing
- press the shortcut 'ctrl-alt-p'
You will directly be connected to your own sharing session.


### Connect to someone else
To connect to a sharing session of someone else, just do one of the following:
- search for the 'Atom Master Sharing: Connect' command in the command palette and execute it
- select the menu entry: Packages -> Atom Master Sharing -> Connect
- press the shortcut 'ctrl-alt-o'
Afterwards enter an url or ip-address with a port into the box that has opened at the top of the window and hit enter.
You should be connected to your partner now and can start working.


### Browser
When someone is sharing a document, you can also connect to the session via a browser.
Just enter the same address as you would, if you were connecting with the atom client.
A website will be opened and the content of the document will be visible.

So far the browser client is in readonly mode, so editing is not possible.


### Ending a session and restarting
Until now this package is in a early development state.
Because of this, not every feature is completely finished.
One of the bigger problems for usage is, that no proper ending mechanism exists.
So if you want to stop sharing your document, save it and reload your atom window.
This is done with the `Window: Reload` command.
So open the command palette cmd/ctrl-shift-p, then enter `Window: Reload` and hit enter.
The shortcut to directly reload window is `ctrl-alt-r` on Windows/Linux and `ctrl-alt-cmd-l` on OSX.
Reloading the window stops the sharing session no matter if it is your session or someone else's.


### Info
If you would like to change the standard port or color, just open the settings of the plugin an change them before usage.
Therefore open the settings view of Atom, go to the packages tab, search for Atom Master Sharing and click on settings.


## Note
This uses the npm module [MasterSharingCore](https://www.npmjs.com/package/mastersharingcore), which is in an early state of development and should not yet be used in a productive environment.
Feel also free to have a look at its [code at github](https://github.com/okwast/MasterSharingCore).
