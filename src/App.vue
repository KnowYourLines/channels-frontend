<template>
  <LoadingScreen v-if="isLoading" />
  <div v-else>
    <SignIn @new-token="newToken" @new-user="newUser" :socketRef="socket" />
    <HelloWorld @socket-created="socketCreated" :token="token" :user="user" />
  </div>
</template>

<script>
import HelloWorld from "./components/HelloWorld.vue";
import SignIn from "./components/SignIn.vue";
import LoadingScreen from "./components/LoadingScreen.vue";

export default {
  name: "App",
  components: {
    HelloWorld,
    SignIn,
    LoadingScreen,
  },
  data() {
    return {
      token: "",
      socket: null,
      user: {},
      isLoading: true,
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
  mounted() {
    setTimeout(() => {
      this.isLoading = false;
    }, 1500);
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
