<template>
  <div v-if="userAllowed">
    <div class="column-left">
      <span>Your chatrooms:</span>
      <ul id="array-rendering">
        <li v-for="notification in notifications" :key="notification.room">
          <div v-if="notification.read" class="read-notification">
            <button
              type="button"
              class="btn"
              @click="visitRoom(notification.room)"
            >
              {{ notification.room__display_name }}</button
            ><br />
            <span v-if="notification.message__user__display_name">
              {{ notification.message__user__display_name }} :
              {{ notification.message__content }}</span
            >
            <span v-if="notification.user_joined__display_name">
              {{ notification.user_joined__display_name }} has joined the
              chat</span
            ><span v-if="notification.user_left__display_name">
              {{ notification.user_left__display_name }} has left the chat</span
            >
            <br />{{ notification.timestamp }}
            <br />
            <button
              type="submit"
              class="btn btn__primary"
              @click="exitRoom(notification.room)"
            >
              Exit room
            </button>
          </div>
          <div v-else class="unread-notification">
            <button
              type="button"
              class="btn"
              @click="visitRoom(notification.room)"
            >
              {{ notification.room__display_name }}</button
            ><br />
            <span v-if="notification.message__user__display_name">
              {{ notification.message__user__display_name }} :
              {{ notification.message__content }}</span
            >
            <span v-if="notification.user_joined__display_name">
              {{ notification.user_joined__display_name }} has joined the
              chat</span
            ><span v-if="notification.user_left__display_name">
              {{ notification.user_left__display_name }} has left the chat</span
            ><br />{{ notification.timestamp }}
            <br />
            <button
              type="submit"
              class="btn btn__primary"
              @click="exitRoom(notification.room)"
            >
              Exit room
            </button>
          </div>
          <br />
        </li>
      </ul>
    </div>
    <div class="column-center">
      <button v-if="shareable" @click="share">Share</button><br /><br />
      <button @click="createNewRoom">New room</button><br /><br />
      <Toggle v-model="privateRoom" @change="updatePrivacy">
        <template v-slot:label="{ checked, classList }">
          <span :class="classList.label">{{
            checked ? "Private" : "Public"
          }}</span>
        </template>
      </Toggle>
      Room name:
      <input
        type="text"
        autocomplete="on"
        v-model.lazy.trim="roomName"
        @keyup.enter="updateRoomName"
      /><br />
      Speaking as:
      <input
        type="text"
        autocomplete="on"
        v-model.lazy.trim="username"
        @keyup.enter="updateDisplayName"
      />
      <textarea
        class="textarea"
        id="chat"
        ref="log"
        cols="100"
        rows="20"
        readonly
      ></textarea
      ><br />
      <input id="message" ref="input" type="text" @keyup.enter="submit" /><input
        ref="submit"
        type="button"
        value="Send"
        @click="submit"
      />
    </div>
    <div class="column-right">
      Room members:
      <ul id="array-rendering">
        <li v-for="member in roomMembers" :key="member.display_name">
          {{ member.display_name }}
        </li>
      </ul>
      <span v-if="privateRoom">Users requesting to join:</span>
      <ul id="array-rendering">
        <li v-for="request in joinRequests" :key="request.user">
          {{ request.user__display_name }}
          <div class="btn-group">
            <button
              type="button"
              class="btn"
              @click="acceptRequest(request.user__username)"
            >
              Accept
            </button>
            <button
              type="submit"
              class="btn btn__primary"
              @click="rejectRequest(request.user__username)"
            >
              Reject
            </button>
          </div>
        </li>
      </ul>
    </div>
  </div>
  <div class="column-center" v-else>
    User not allowed in private room. Access requested.
  </div>
</template>

<script>
import { v4 as uuidv4 } from "uuid";
import Toggle from "@vueform/toggle";
export default {
  name: "HelloWorld",
  components: {
    Toggle,
  },
  emits: ["socket-created"],
  props: {
    token: {
      type: String,
      required: true,
    },
    user: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      username: null,
      roomName: null,
      shareable: null,
      privateRoom: false,
      userAllowed: true,
      joinRequests: null,
      notifications: null,
      roomMembers: null,
    };
  },
  methods: {
    visitRoom: function (room) {
      let url = new URL(window.location.href);
      url.searchParams.set("room", room);
      window.location.href = url;
    },
    exitRoom: function (room) {
      this.socketRef.send(
        JSON.stringify({ command: "exit_room", room_id: room })
      );
      const urlParams = new URLSearchParams(window.location.search);
      let currentRoom = urlParams.get("room");
      if (room == currentRoom) {
        window.location.href = window.location.href.split("?")[0];
      }
    },
    createNewRoom: function () {
      window.location.href = window.location.href.split("?")[0];
    },
    acceptRequest: function (username) {
      this.socketRef.send(
        JSON.stringify({ command: "approve_user", username: username })
      );
      this.socketRef.send(
        JSON.stringify({ command: "refresh_allowed_status" })
      );
      this.socketRef.send(JSON.stringify({ command: "refresh_chat" }));
    },
    rejectRequest: function (username) {
      this.socketRef.send(
        JSON.stringify({ command: "reject_user", username: username })
      );
    },
    share: function () {
      const shareData = {
        url: window.location.href,
      };
      navigator.share(shareData);
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
    updatePrivacy: function () {
      if (!this.privateRoom) {
        this.joinRequests = [];
        this.socketRef.send(JSON.stringify({ command: "approve_all_users" }));
        this.socketRef.send(
          JSON.stringify({ command: "refresh_allowed_status" })
        );
        this.socketRef.send(JSON.stringify({ command: "refresh_chat" }));
      }
      this.socketRef.send(
        JSON.stringify({
          command: "update_privacy",
          privacy: this.privateRoom,
        })
      );
      this.$refs.input.focus();
      this.socketRef.send(JSON.stringify({ command: "refresh_privacy" }));
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
  beforeCreate() {
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
    this.$emit("socket-created", this.socketRef);
  },
  mounted() {
    this.$refs.input.focus();
    this.shareable = typeof navigator.share === "function";
    this.socketRef.onopen = () => {
      console.log("WebSocket open");
      if (!this.token) {
        setTimeout(
          function () {
            this.socketRef.send(
              JSON.stringify({ command: "fetch_messages", token: this.token })
            );
            this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
            this.socketRef.send(JSON.stringify({ command: "fetch_privacy" }));
            this.socketRef.send(
              JSON.stringify({ command: "fetch_user_notifications" })
            );
            this.socketRef.send(JSON.stringify({ command: "fetch_members" }));
          }.bind(this),
          1000
        );
      } else {
        this.socketRef.send(
          JSON.stringify({ command: "fetch_messages", token: this.token })
        );
        this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
        this.socketRef.send(JSON.stringify({ command: "fetch_privacy" }));
        this.socketRef.send(
          JSON.stringify({ command: "fetch_user_notifications" })
        );
        this.socketRef.send(JSON.stringify({ command: "fetch_members" }));
      }
    };
    this.socketRef.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if (data.members) {
        this.roomMembers = JSON.parse(data.members);
      } else if (data.refresh_members) {
        this.socketRef.send(JSON.stringify({ command: "fetch_members" }));
      } else if (data.notifications) {
        this.notifications = JSON.parse(data.notifications);
      } else if (data.requests) {
        this.joinRequests = JSON.parse(data.requests);
      } else if (data.refresh_notifications) {
        this.socketRef.send(
          JSON.stringify({ command: "fetch_user_notifications" })
        );
      } else if (data.refresh_allowed_status) {
        this.socketRef.send(
          JSON.stringify({ command: "fetch_allowed_status", token: this.token })
        );
      } else if (data.allowed) {
        this.userAllowed = true;
      } else if (data.not_allowed) {
        this.userAllowed = false;
      } else if (data.privacy) {
        this.privateRoom = data.privacy == "True" ? true : false;
        if (this.privateRoom) {
          this.socketRef.send(
            JSON.stringify({ command: "fetch_join_requests" })
          );
        }
      } else if (data.refresh_join_requests) {
        this.socketRef.send(JSON.stringify({ command: "fetch_join_requests" }));
      } else if (data.refresh_privacy) {
        this.socketRef.send(JSON.stringify({ command: "fetch_privacy" }));
      } else if (data.new_room_name) {
        this.roomName = data.new_room_name;
      } else if (data.refresh_room_name) {
        this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
      } else if (data.refresh_chat) {
        if (this.$refs.log) {
          this.$refs.log.value = "";
        }
        this.socketRef.send(
          JSON.stringify({ command: "fetch_messages", token: this.token })
        );
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
};
</script>
<style >
.unread-notification {
  background-color: #5dbeff;
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
#chat {
  max-width: 100%;
}
#message {
  width: 100%;
}
#array-rendering {
  list-style-type: none;
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