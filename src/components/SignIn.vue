<template>
  <div>
    <section v-if="showSignIn" id="firebaseui-auth-container"></section>
    <button @click="signOut">Sign Out</button><br /><br />
  </div>
</template>

<script>
import firebase from "firebase";
import * as firebaseui from "firebaseui";
import "firebaseui/dist/firebaseui.css";
export default {
  name: "SignIn",
  emits: ["new-token", "new-user"],
  props: {
    socketRef: {
      type: WebSocket,
      required: true,
    },
  },
  data() {
    return {
      token: null,
      showSignIn: true,
    };
  },
  methods: {
    signOut: function () {
      firebase
        .auth()
        .signOut()
        .then(() => {
          this.showSignIn = true;
          this.$nextTick(() => {
            this.ui.start("#firebaseui-auth-container", this.uiConfig);
          });
          alert("Successfully signed out.");
        })
        .catch((err) => {
          console.log(err);
        });
    },
  },
  mounted() {
    firebase.auth().onAuthStateChanged((user) => {
      console.log(user);
      if (user) {
        this.user = user;
        this.$emit("new-user", this.user);
        user.getIdToken().then((token) => {
          this.token = token;
          this.showSignIn = this.user.isAnonymous;
          this.$emit("new-token", this.token);
          if (this.socketRef.readyState === 1) {
            this.socketRef.send(
              JSON.stringify({ command: "join_room", token: this.token })
            );
            this.socketRef.send(
              JSON.stringify({ command: "fetch_user_notifications" })
            );
            this.socketRef.send(
              JSON.stringify({
                command: "fetch_display_name",
                token: this.token,
              })
            );
          } else {
            setTimeout(
              function () {
                this.socketRef.send(
                  JSON.stringify({ command: "join_room", token: this.token })
                );
                this.socketRef.send(
                  JSON.stringify({ command: "fetch_user_notifications" })
                );
                this.socketRef.send(
                  JSON.stringify({
                    command: "fetch_display_name",
                    token: this.token,
                  })
                );
              }.bind(this),
              1000
            );
          }
        });
      } else {
        firebase.auth().signInAnonymously();
      }
    });
    this.ui = firebaseui.auth.AuthUI.getInstance();
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
    if (
      firebase.auth().currentUser == null ||
      firebase.auth().currentUser.isAnonymous
    ) {
      this.$nextTick(() => {
        this.ui.start("#firebaseui-auth-container", this.uiConfig);
      });
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
