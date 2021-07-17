<template>
  <div v-if="userAllowed">
    <div class="column-left">
      <ChatHistory :notifications="notifications" :socketRef="socketRef" />
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
      <ChatMembers
        :roomMembers="roomMembers"
        :privateRoom="privateRoom"
        :joinRequests="joinRequests"
        :socketRef="socketRef"
      />
    </div>
  </div>
  <div class="column-center" v-else>
    User not allowed in private room. Access requested.
  </div>
</template>

<script>
import { v4 as uuidv4 } from "uuid";
import Toggle from "@vueform/toggle";
import ChatHistory from "./ChatHistory.vue";
import ChatMembers from "./ChatMembers.vue";
export default {
  name: "Chat",
  components: {
    Toggle,
    ChatHistory,
    ChatMembers,
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
      joinRequests: [],
      notifications: [],
      roomMembers: [],
    };
  },
  methods: {
    createNewRoom: function () {
      window.location.href = window.location.href.split("?")[0];
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
    },
    updateRoomName: function () {
      this.socketRef.send(
        JSON.stringify({
          command: "update_room_name",
          name: this.roomName,
        })
      );
      this.$refs.input.focus();
    },
    updatePrivacy: function () {
      if (!this.privateRoom) {
        this.joinRequests = [];
        this.socketRef.send(JSON.stringify({ command: "approve_all_users" }));
      }
      this.socketRef.send(
        JSON.stringify({
          command: "update_privacy",
          privacy: this.privateRoom,
        })
      );
      this.$refs.input.focus();
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
            this.socketRef.send(
              JSON.stringify({
                command: "fetch_display_name",
                token: this.token,
              })
            );
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
        this.socketRef.send(
          JSON.stringify({ command: "fetch_display_name", token: this.token })
        );
      }
    };
    this.socketRef.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if ("members" in data) {
        this.roomMembers = JSON.parse(data.members);
      } else if ("refresh_members" in data) {
        this.socketRef.send(JSON.stringify({ command: "fetch_members" }));
      } else if ("notifications" in data) {
        this.notifications = JSON.parse(data.notifications);
      } else if ("requests" in data) {
        this.joinRequests = JSON.parse(data.requests);
      } else if ("refresh_notifications" in data) {
        this.socketRef.send(
          JSON.stringify({ command: "fetch_user_notifications" })
        );
      } else if ("refresh_allowed_status" in data) {
        this.socketRef.send(
          JSON.stringify({ command: "fetch_allowed_status", token: this.token })
        );
      } else if ("allowed" in data) {
        this.userAllowed = true;
      } else if ("not_allowed" in data) {
        this.userAllowed = false;
      } else if ("privacy" in data) {
        this.privateRoom = data.privacy;
        if (this.privateRoom) {
          this.socketRef.send(
            JSON.stringify({ command: "fetch_join_requests" })
          );
        }
      } else if ("refresh_join_requests" in data) {
        this.socketRef.send(JSON.stringify({ command: "fetch_join_requests" }));
      } else if ("refresh_privacy" in data) {
        this.socketRef.send(JSON.stringify({ command: "fetch_privacy" }));
      } else if ("new_room_name" in data) {
        this.roomName = data.new_room_name;
      } else if ("refresh_room_name" in data) {
        this.socketRef.send(JSON.stringify({ command: "fetch_room_name" }));
      } else if ("refresh_chat" in data) {
        if (this.$refs.log) {
          this.$refs.log.value = "";
        }
        this.socketRef.send(
          JSON.stringify({ command: "fetch_messages", token: this.token })
        );
      } else if ("new_display_name" in data) {
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
          this.user.providerData[0] &&
          (this.username === this.user.displayName ||
            this.username === this.user.email ||
            this.username === this.user.phoneNumber ||
            this.username === this.user.uid)
        ) {
          this.username =
            this.user.providerData[0].displayName ||
            this.user.displayName ||
            this.user.providerData[0].email ||
            this.user.email ||
            this.user.providerData[0].phoneNumber ||
            this.user.phoneNumber ||
            this.user.providerData[0].uid ||
            this.user.uid;
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