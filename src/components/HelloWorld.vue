<template>
  <div>
    <section id="firebaseui-auth-container"></section>
    <button @click="signOut">Sign Out</button><br /><br />
    Room name:
    <input
      type="text"
      autocomplete="on"
      v-model.lazy.trim="roomName"
      @keyup.enter="updateRoomName"
    />
    Speaking as:
    <input
      type="text"
      autocomplete="on"
      v-model.lazy.trim="username"
      @keyup.enter="updateDisplayName"
    />
  </div>

  <textarea ref="log" cols="100" rows="20" readonly></textarea><br />
  <input ref="input" type="text" size="100" @keyup.enter="submit" /><input
    ref="submit"
    type="button"
    value="Send"
    @click="submit"
  />
</template>

<script>
import { v4 as uuidv4 } from "uuid";
import firebase from "firebase";
import * as firebaseui from "firebaseui";
import "firebaseui/dist/firebaseui.css";
export default {
  name: "HelloWorld",
  data() {
    return {
      username: null,
      token: null,
      roomName: null,
    };
  },
  methods: {
    signOut: function () {
      firebase
        .auth()
        .signOut()
        .then(() => {
          firebase.auth().signInAnonymously();
          this.ui.start("#firebaseui-auth-container", this.uiConfig);
          alert("Successfully signed out.");
        })
        .catch((err) => {
          console.log(err);
        });
    },
    updateDisplayName: function () {
      this.socketRef.send(
        JSON.stringify({
          command: "update_display_name",
          name: this.username,
          token: this.token,
        })
      );
      this.socketRef.send(
        JSON.stringify({ command: "fetch_display_name", token: this.token })
      );
      this.$refs.input.focus();
      this.socketRef.send(JSON.stringify({ command: "refresh_chat" }));
    },
    updateRoomName: function () {
      this.socketRef.send(
        JSON.stringify({
          command: "update_room_name",
          name: this.roomName,
        })
      );
      this.$refs.input.focus();
      this.socketRef.send(JSON.stringify({ command: "refresh_room_name" }));
    },
    submit: function () {
      const message = this.$refs.input.value;
      this.socketRef.send(
        JSON.stringify({
          message: message,
          user: this.username,
          token: this.token,
        })
      );
      this.$refs.input.value = "";
    },
  },
  created() {
    const firebaseConfig = {
      apiKey: process.env.VUE_APP_FIREBASE_API_KEY,
      authDomain: process.env.VUE_APP_FIREBASE_AUTH_DOMAIN,
      projectId: process.env.VUE_APP_FIREBASE_PROJECT_ID,
      storageBucket: process.env.VUE_APP_FIREBASE_STORAGE_BUCKET,
      messagingSenderId: process.env.VUE_APP_FIREBASE_MESSAGING_SENDER_ID,
      appId: process.env.VUE_APP_FIREBASE_APP_ID,
      measurementId: process.env.VUE_APP_FIREBASE_MEASUREMENT_ID,
    };
    firebase.initializeApp(firebaseConfig);
    firebase.auth().onAuthStateChanged((user) => {
      console.log(user);
      if (user) {
        this.user = user;
        user.getIdToken().then((token) => {
          this.token = token;
          this.socketRef.send(
            JSON.stringify({ command: "join_room", token: this.token })
          );
          this.socketRef.send(
            JSON.stringify({ command: "fetch_display_name", token: this.token })
          );
        });
      } else {
        firebase.auth().signInAnonymously();
      }
    });
    this.ui = firebaseui.auth.AuthUI.getInstance();
    if (!this.ui) {
      this.ui = new firebaseui.auth.AuthUI(firebase.auth());
    }
    this.uiConfig = {
      autoUpgradeAnonymousUsers: true,
      signInSuccessUrl: window.location.href,
      signInOptions: [
        firebase.auth.GoogleAuthProvider.PROVIDER_ID,
        firebase.auth.FacebookAuthProvider.PROVIDER_ID,
        firebase.auth.PhoneAuthProvider.PROVIDER_ID,
        {
          provider: firebase.auth.EmailAuthProvider.PROVIDER_ID,
          signInMethod:
            firebase.auth.EmailAuthProvider.EMAIL_LINK_SIGN_IN_METHOD,
        },
      ],
      callbacks: {
        // signInFailure callback must be provided to handle merge conflicts which
        // occur when an existing credential is linked to an anonymous user.
        signInFailure: function (error) {
          // For merge conflicts, the error.code will be
          // 'firebaseui/anonymous-upgrade-merge-conflict'.
          if (error.code != "firebaseui/anonymous-upgrade-merge-conflict") {
            return Promise.resolve();
          }
          // The credential the user tried to sign in with.
          var cred = error.credential;
          // Copy data from anonymous user to permanent user and delete anonymous
          // user.
          // ...
          // Finish sign-in after data is copied.
          return firebase.auth().signInWithCredential(cred);
        },
      },
    };
  },
  mounted() {
    this.$refs.input.focus();
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
    this.socketRef.onopen = () => {
      console.log("WebSocket open");
      this.socketRef.send(JSON.stringify({ command: "fetch_messages" }));
      this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
    };
    this.socketRef.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if (data.new_room_name) {
        this.roomName = data.new_room_name;
      } else if (data.refresh_room_name) {
        this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
      } else if (data.refresh_chat) {
        this.$refs.log.value = "";
        this.socketRef.send(JSON.stringify({ command: "fetch_messages" }));
      } else if (data.new_display_name) {
        this.username = data.new_display_name;
        if (
          this.user.providerData[0] &&
          (this.username === this.user.providerData[0].displayName ||
            this.username === this.user.providerData[0].email ||
            this.username === this.user.providerData[0].phoneNumber ||
            this.username === this.user.providerData[0].uid)
        ) {
          this.username =
            this.user.providerData[0].displayName ||
            this.user.providerData[0].email ||
            this.user.providerData[0].phoneNumber ||
            this.user.providerData[0].uid;
          this.socketRef.send(
            JSON.stringify({
              command: "update_display_name",
              name: this.username,
              token: this.token,
            })
          );
        } else if (
          this.username === this.user.displayName ||
          this.username === this.user.email ||
          this.username === this.user.phoneNumber ||
          this.username === this.user.uid
        ) {
          this.username =
            this.user.displayName ||
            this.user.email ||
            this.user.phoneNumber ||
            this.user.uid;
          this.socketRef.send(
            JSON.stringify({
              command: "update_display_name",
              name: this.username,
              token: this.token,
            })
          );
        }
      } else {
        this.$refs.log.value += data.message + "\n";
      }
    };
    this.socketRef.onerror = (e) => {
      console.log(e.message);
    };
    this.socketRef.onclose = () => {
      console.log("WebSocket closed");
    };
  },
  beforeUpdate() {
    if (
      firebase.auth().currentUser == null ||
      firebase.auth().currentUser.isAnonymous
    ) {
      this.ui.start("#firebaseui-auth-container", this.uiConfig);
    }
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
