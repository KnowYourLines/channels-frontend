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
#chat {
  max-width: 100%;
}
#message {
  width: 100%;
}
#array-rendering {
  list-style-type: none;
}
</style> 