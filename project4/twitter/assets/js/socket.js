// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

var topics = {}
var tweets = []
// Now that you are connected, you can join channels with a topic:
let username          = document.querySelector("#username").innerText;
topics[username]      = socket.channel("twitter:" +  username, {})
topics[username].on("new_tweet", payload => tweetCallback(payload))
topics[username].join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) }) 

let chatInput         = document.querySelector("#chat-input")
let sendTweetButton   = document.querySelector("#send-tweet")
let followInput       = document.querySelector("#follow-input")
let followButton      = document.querySelector("#followBtn")
let searchInput       = document.querySelector("#search-input")
let searchButton      = document.querySelector("#searchBtn")
let searchResults     = document.querySelector("#search-results")
let clearButton       = document.querySelector("#clear-search")
let messagesContainer = document.querySelector("#messages")

sendTweetButton.addEventListener("click", event => {
  var tweet = chatInput.value;
  if (tweet.length < 280 && tweet != "") {
    topics[username].push("new_tweet", {body: "@" + username + ": " + tweet});
    chatInput.value = "";
  }
})

followButton.addEventListener("click", event => {
  var their_username = followInput.value;
  if (their_username != "" && their_username.length < 32) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "/api/follow/" + their_username, false);
    xhr.send();
    if(xhr.responseText == "Avail") {
      topics[their_username] = socket.channel("twitter:" + their_username, {})
      try {
        topics[their_username].on("new_tweet", payload => tweetCallback(payload)) 
      } catch(err) {
        console.log(err)
      }  
      topics[their_username].join()
        .receive("ok", resp => { alert("Followed " + their_username + " successfully") })
        .receive("error", resp => { console.log("Unable to follow " + their_username) }) 
      followInput.value = ""
    } else {
      alert("No user with name " + their_username);
    }
  } else {
    alert("Invalid username");
  }
})

searchButton.addEventListener("click", event => searchCallback());
clearButton.addEventListener("click", event => clearCallback());


// Some helper funs
var tweetCallback = function(payload) {
  let messageItem = document.createElement("li");
  messageItem.classList.add("list-group-item");
  messageItem.addEventListener("click", event => retweetCallback(payload.body));
  messageItem.innerText = `[${Date().split('GMT')[0].trim()}] ${payload.body}`;
  messagesContainer.appendChild(messageItem);
  tweets.push(payload.body);
}

var retweetCallback = function(tweet) {
  if(confirm("Retweet?")) {
    console.log("RT " + tweet);
    topics[username].push("new_tweet", {body: "@" + username + ": (RT ->) " + tweet});    
  }
}

var searchCallback = function() {
  var query = searchInput.value;
  var numResults = 0;
  for(var i = 0; i < tweets.length; ++i) {
    console.log(tweets[i])
    if (tweets[i].includes(query)) {
      let searchResultItem = document.createElement("li");
      searchResultItem.classList.add("list-group-item");
      searchResultItem.innerText = tweets[i];
      searchResults.appendChild(searchResultItem);
      numResults++;
    }
  }
  if(numResults == 0) {
    alert("Found no matching tweets");
  }
}

var clearCallback = function() {
  while(searchResults.hasChildNodes()) {
    searchResults.removeChild(searchResults.firstChild);
  }
}

export default socket
