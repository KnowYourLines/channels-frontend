<template>
  <SignIn @new-token="newToken" @new-user="newUser" :socketRef="socket" />
  <HelloWorld @socket-created="socketCreated" :token="token" :user="user" />
</template>

<script>
import HelloWorld from "./components/HelloWorld.vue";
import SignIn from "./components/SignIn.vue";

export default {
  name: "App",
  components: {
    HelloWorld,
    SignIn,
  },
  data() {
    return {
      token: '',
      socket: null,
      user: {}
    };
  },
  methods: {
    socketCreated: function (socket) {
      this.socket = socket;
    },
    newToken: function (token) {
      this.token = token;
    },
    newUser: function (user) {
      this.user = user;
    },
  },
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
