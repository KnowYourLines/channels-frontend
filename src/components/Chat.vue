<template>
  <div v-if="userAllowed">
    <div class="column-left">
      <ChatHistory :notifications="notifications" :socketRef="socketRef" />
    </div>
    <div class="column-center">
      Room name:
      <input
        type="text"
        autocomplete="on"
        :value="roomName"
        @input="$emit('update:roomName', $event.target.value)"
        @keyup.enter="updateRoomName"
      /><br />
      Speaking as:
      <input
        type="text"
        autocomplete="on"
        :value="username"
        @input="$emit('update:username', $event.target.value)"
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
import ChatHistory from "./ChatHistory.vue";
import ChatMembers from "./ChatMembers.vue";
export default {
  name: "Chat",
  components: {
    ChatHistory,
    ChatMembers,
  },
  props: {
    socketRef: {
      type: WebSocket,
      required: false,
    },
    user: {
      type: Object,
      required: true,
    },
    joinRequests: {
      type: Array,
      required: true,
    },
    notifications: {
      type: Array,
      required: true,
    },
    roomMembers: {
      type: Array,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    roomName: {
      type: String,
      required: true,
    },
    privateRoom: {
      type: Boolean,
      required: true,
    },
    userAllowed: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    updateDisplayName: function () {
      this.socketRef.send(
        JSON.stringify({
          command: "update_display_name",
          name: this.username,
        })
      );
      this.socketRef.send(JSON.stringify({ command: "fetch_display_name" }));
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
    submit: function () {
      const message = this.$refs.input.value;
      this.socketRef.send(
        JSON.stringify({
          message: message,
          user: this.username,
        })
      );
      this.$refs.input.value = "";
    },
  },
  mounted() {
    this.$refs.input.focus();
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