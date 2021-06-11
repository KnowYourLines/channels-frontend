<template>
  <div>
    <button @click="googleSignIn">Sign In with Google</button>
    <button @click="googleSignOut">Sign Out</button>
  </div>
  <br />
  <textarea ref="log" cols="100" rows="20"></textarea><br />
  <input ref="input" type="text" size="100" @keyup.enter="submit" /><br />
  <input ref="submit" type="button" value="Send" @click="submit" />
</template>

<script>
import axios from "axios";
import { v4 as uuidv4 } from "uuid";
import firebase from "firebase";
export default {
  name: "HelloWorld",
  data() {
    return {
      user: uuidv4()
    };
  },
  methods: {
    googleSignIn: function () {
      let provider = new firebase.auth.GoogleAuthProvider();
      const firebaseConfig = {
        apiKey: "AIzaSyDDEtNW4mCP6BqaegpNJZaFaepObxgwV-Q",
        authDomain: "channels-efc02.firebaseapp.com",
        projectId: "channels-efc02",
        storageBucket: "channels-efc02.appspot.com",
        messagingSenderId: "874229818669",
        appId: "1:874229818669:web:25e9c168b4319945125fa4",
        measurementId: "G-T9ZBBM3GGF",
      };
      firebase
        .initializeApp(firebaseConfig)
        .auth()
        .signInWithPopup(provider)
        .then((result) => {
          result.user.getIdToken().then((token) => {
            axios.defaults.headers.common = {
              Authorization: "Token " + token,
            };
            axios
              .get(process.env.VUE_APP_BACKEND_URL + "/chat/username/")
              .then((response) => {
                this.user = response.data["username"];
              })
              .catch(function (error) {
                if (error.response) {
                  console.log(error.response.data);
                  console.log(error.response.status);
                  console.log(error.response.headers);
                }
              });
          });
        })
        .catch((err) => {
          console.log(err); // This will give you all the information needed to further debug any errors
        });
    },
    googleSignOut: function () {
      firebase
        .auth()
        .signOut()
        .then(() => {
          alert("Successfully signed out.");
        })
        .catch((err) => {
          console.log(err); // This will give you all the information needed to further debug any errors
        });
    },
    submit: function () {
      const message = this.$refs.input.value;
      this.socketRef.send(
        JSON.stringify({
          message: message,
          user: this.user,
        })
      );
      this.$refs.input.value = "";
    },
  },
  created() {
    const urlParams = new URLSearchParams(window.location.search);
    let room = urlParams.get("room");
    if (!room) {
      room = uuidv4();
      let url = new URL(window.location.href);
      url.searchParams.set("room", room);
      window.location.href = url;
    }
    const backendUrl = new URL(process.env.VUE_APP_BACKEND_URL);
    const ws_scheme = backendUrl.protocol == "https:" ? "wss" : "ws";
    const path =
      ws_scheme +
      "://" +
      backendUrl.hostname +
      ":" +
      backendUrl.port +
      "/ws/chat/" +
      room +
      "/";
    this.socketRef = new WebSocket(path);
  },
  mounted() {
    this.$refs.input.focus();
    this.socketRef.onopen = () => {
      console.log("WebSocket open");
      this.socketRef.send(JSON.stringify({ command: "fetch_messages" }));
    };
    this.socketRef.onmessage = (e) => {
      const data = JSON.parse(e.data);
      this.$refs.log.value += data.message + "\n";
    };

    this.socketRef.onerror = (e) => {
      console.log(e.message);
    };
    this.socketRef.onclose = () => {
      console.log("WebSocket closed let's reopen");
    };
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>
