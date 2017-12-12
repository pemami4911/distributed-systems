# Twitter

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Files

* assets
  * js
    - app.js
        imports for the js app
    - socket.js
        sets up Phoenix channels on the JS side, defines callbacks for updating DOM with messages
  * css
    - app.css
        put css here for my app
* lib
  * twitter
    - application.ex
        supervisor definition for the backend
    - repo.ex
        ecto DB stuff
  * twitter_web
    * channels
      - room_channel.ex
          API for room message topics
      - user_socket.ex
          define channels, connections
    * controllers
      - page_controller.ex
          control the view (rendering)
    * templates 
      - HTML snippets for different pages of site
    * views
      - definitions for Elixir rendering of views
    - endpoint.ex
        boiler plate for bringing up the web app and serving files
    - router.ex
        defines routing for different get requests to the valid controller 
  - twitter_web.ex
      definitions and imports for every view, controller, etc
  - twitter.ex
      contexts (?)

## User flows

* Logging in
    1. User navigates to localhost:4000. A username/password log in form is displayed, with a "create account" option below (index.html, always shown first). 
    2. User enters their credentials, presses a "sign in" button.
    3. Use simple SHA256 to encrypt plaintext
    4. Query the DB to verify
    5. On success, the user is redirected to their dashboard "localhost:4000/username" if possible, or "localhost:4000/home"
    6. On failure, an error is displayed
    7. On success, the user is connected to all channels from their followers list (retrieved from db?) including their own channel
* User wants to compose tweet
    1. User clicks on the text entry box for composing tweets and types out a tweet, and hits send button
    2. The user channel pushes out the tweet to the backend, which broadcasts it to all subscribers
    3. The tweet is parsed by all appropriate clients and displayed in the TL
* User searches their TL
    1. All received tweets during a session are stored in a js array/dict. 
    2. N.b. the most recent 20 tweets are displayed on the TL
    3. The user clicks on a search tab, and is redirected to "localhost:4000/home/search"
    4. The user clicks in a text entry search bar and enters a query
    5. Any tweet containing the substring is dynamically displayed (same UI as TL)
    6. Optional: add a tab for My Mentions which automatically searches for "@Username"
    7. The user clicks on a "Home" tab and redirects to "localhost:4000/home"
* User RTs
    1. Each tweet will be displayed with a RT clickable button. 
    2. By clicking on the RT button on a tweet, a box will pop up asking for confirmation
    3. Upon RT'ing, the original author is appending to the body of the tweet and is pushed out of the user's channel
* User follows another user (use DB??)
    1. User clicks on text entry box and enters a username
    2. User clicks "follow"
    3. A request is sent to the backend "localhost:4000/home/follow/:username" which verifies that this user exists
    4. On success, the client adds a new channel with topic "tweet:username"
    5. On failure, displays an error dialogue or indicator
* User creates account
    1. The user is redirected to a form "localhost:4000/register"
    2. The user enters a valid username and password
    3. The user clicks "register"
    4. The string "username=???password=???" with hashed values is converted to base64
    4. A request is sent to the backend "localhost:4000/register/creds=?" 
    5. If no user already exists with this username, the db is updated and success is returned
    6. On success, the user is redirected to "localhost:4000/home"
    7. On failure, an error dialogue or indicator is displayed and the user is prompted to try different credentials

# TODO
* Replace old Twitter Client (copy it) calls to GenServer to use websockets to talk to the new engine