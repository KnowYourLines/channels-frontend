<template>
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
      <span :class="classList.label">{{ checked ? "Private" : "Public" }}</span>
    </template>
  </Toggle>
  <br /><br />
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
</template>

<script>
import Toggle from "@vueform/toggle";
import Chat from "./components/Chat.vue";
import SignIn from "./components/SignIn.vue";

export default {
  name: "App",
  components: {
    Toggle,
    Chat,
    SignIn,
  },
  data() {
    return {
      socket: null,
      user: {},
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
        this.joinRequests = [];
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
.column-left {
  float: left;
  width: 33.333%;
}
.column-right {
  float: right;
  width: 33.333%;
}
.column-center {
  display: inline-block;
  width: 33.333%;
}
.toggle-container {
  display: inline-block;
}
.toggle-container:focus {
  outline: none;
  box-shadow: 0 0 0 var(--toggle-ring-width, 3px)
    var(--toggle-ring-color, rgba(16, 185, 129, 0.18823529411764706));
}
.toggle {
  display: flex;
  width: var(--toggle-width, 5rem);
  height: var(--toggle-height, 1.25rem);
  border-radius: 999px;
  position: relative;
  cursor: pointer;
  transition: all 0.3s;
  align-items: center;
  box-sizing: content-box;
  border: var(--toggle-border, 0.125rem) solid;
  font-size: var(--toggle-font-size, 1rem);
  line-height: 1;
}
.toggle-on {
  background: var(--toggle-bg-on, #10b981);
  border-color: var(--toggle-border-on, #10b981);
  justify-content: flex-start;
  color: var(--toggle-text-on, #fff);
}
.toggle-off {
  background: var(--toggle-bg-off, #e5e7eb);
  border-color: var(--toggle-border-off, #e5e7eb);
  justify-content: flex-end;
  color: var(--toggle-text-off, #374151);
}
.toggle-on-disabled {
  background: var(--toggle-bg-on-disabled, #d1d5db);
  border-color: var(--toggle-border-on-disabled, #d1d5db);
  justify-content: flex-start;
  color: var(--toggle-text-on-disabled, #9ca3af);
  cursor: not-allowed;
}
.toggle-off-disabled {
  background: var(--toggle-bg-off-disabled, #e5e7eb);
  border-color: var(--toggle-border-off-disabled, #e5e7eb);
  justify-content: flex-end;
  color: var(--toggle-text-off-disabled, #9ca3af);
  cursor: not-allowed;
}
.toggle-handle {
  display: inline-block;
  background: var(--toggle-handle-enabled, #fff);
  width: 20px;
  height: 20px;
  top: 0;
  border-radius: 50%;
  position: absolute;
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: var(--toggle-duration, 0.15s);
}
.toggle-handle-on {
  left: 100%;
  transform: translateX(-100%);
}
.toggle-handle-off {
  left: 0;
}
.toggle-handle-on-disabled {
  left: 100%;
  transform: translateX(-100%);
  background: var(--toggle-handle-disabled, #f3f4f6);
}
.toggle-handle-off-disabled {
  left: 0;
  background: var(--toggle-handle-disabled, #f3f4f6);
}
.toggle-label {
  text-align: center;
  width: calc(var(--toggle-width, 5rem) - var(--toggle-height, 1.25rem));
  box-sizing: border-box;
  white-space: nowrap;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}
</style>
