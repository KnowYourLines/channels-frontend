<template>
  <div>
    <button v-if="shareable" @click="share">Share</button><br /><br />
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
export default {
  name: "HelloWorld",
  emits: ['socket-connected'],
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
    };
  },
  methods: {
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
  mounted() {
    this.$refs.input.focus();
    this.shareable = typeof navigator.share === "function";
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
      this.$emit("socket-connected", this.socketRef);
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
