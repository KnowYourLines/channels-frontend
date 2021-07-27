<template>
  <LoadingScreen v-if="isLoading" />
  <div v-else>
    <SignIn
      @new-user="newUser"
      @socket-created="socketCreated"
      @new-room-members="newRoomMembers"
      @new-notifications="newNotifications"
      @new-join-requests="newJoinRequests"
      @new-allowed-status="newAllowedStatus"
      @new-room-name="newRoomName"
      @clear-chat="clearChat"
      @new-username="newUsername"
      @new-message="newMessage"
      @new-privacy="newPrivacy"
    />
    <Toggle v-if="userAllowed" v-model="privateRoom" @change="updatePrivacy">
        <template v-slot:label="{ checked, classList }">
          <span :class="classList.label">{{
            checked ? "Private" : "Public"
          }}</span>
        </template>
      </Toggle>
      <br/><br />
    <Chat
      ref="chat"
      :socketRef="socket"
      :user="user"
      :roomMembers="roomMembers"
      :joinRequests="joinRequests"
      :notifications="notifications"
      :privateRoom="privateRoom"
      :userAllowed="userAllowed"
      v-model:username.lazy.trim="username"
      v-model:roomName.lazy.trim="roomName"
      @new-join-requests="newJoinRequests"
    />
  </div>
</template>

<script>
import Toggle from "@vueform/toggle";
import Chat from "./components/Chat.vue";
import SignIn from "./components/SignIn.vue";
import LoadingScreen from "./components/LoadingScreen.vue";

export default {
  name: "App",
  components: {
    Toggle,
    Chat,
    SignIn,
    LoadingScreen,
  },
  data() {
    return {
      socket: null,
      user: {},
      isLoading: true,
      joinRequests: [],
      notifications: [],
      roomMembers: [],
      username: "",
      roomName: "",
      privateRoom: false,
      userAllowed: true,
    };
  },
  methods: {
    updatePrivacy: function () {
      if (!this.privateRoom) {
        this.joinRequests = []
        this.socket.send(JSON.stringify({ command: "approve_all_users" }));
      }
      this.socket.send(
        JSON.stringify({
          command: "update_privacy",
          privacy: this.privateRoom,
        })
      );
      this.$refs.chat.$refs.input.focus();

    },
    socketCreated: function (socket) {
      this.socket = socket;
    },
    newUser: function (user) {
      this.user = user;
    },
    newRoomMembers: function (members) {
      this.roomMembers = members;
    },
    newNotifications: function (notifications) {
      this.notifications = notifications;
    },
    newJoinRequests: function (requests) {
      this.joinRequests = requests;
    },
    newAllowedStatus: function (status) {
      this.userAllowed = status;
    },
    newRoomName: function (name) {
      this.roomName = name;
    },
    newUsername: function (username) {
      this.username = username;
    },
    newPrivacy: function (privacy) {
      this.privateRoom = privacy;
    },
    newMessage: function (message) {
      this.$refs.chat.$refs.log.value += message;
    },
    clearChat: function () {
      if (this.$refs.chat.$refs.log) {
        this.$refs.chat.$refs.log.value = "";
      }
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
