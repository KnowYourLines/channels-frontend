<template>
  <textarea ref="log" cols="100" rows="20"></textarea><br />
  <input ref="input" type="text" size="100" @keyup.enter="submit" /><br />
  <input ref="submit" type="button" value="Send" @click="submit" />
</template>

<script>
import axios from "axios";
// import { v4 as uuidv4 } from "uuid";
export default {
  name: "HelloWorld",
  props: {
    msg: String,
  },
  methods: {
    submit: function () {
      const message = this.$refs.input.value;
      this.socketRef.send(
        JSON.stringify({
          message: message,
          user: this.user,
        })
      );
      this.$refs.input.value = "";
    },
  },
  created() {
    const backendUrl = new URL(process.env.VUE_APP_BACKEND_URL);
    const ws_scheme = backendUrl.protocol == "https:" ? "wss" : "ws";
    const path =
      ws_scheme +
      "://" +
      backendUrl.hostname +
      ":" +
      backendUrl.port +
      "/ws/chat/helloworld/";
    this.socketRef = new WebSocket(path);
    axios
      .get(process.env.VUE_APP_BACKEND_URL + "/chat/username/")
      .then((response) => {
        this.user = response.data["username"];
      })
      .catch(function (error) {
        if (error.response) {
          console.log(error.response.data);
          console.log(error.response.status);
          console.log(error.response.headers);
        }
      });
  },
  mounted() {
    this.$refs.input.focus();
    this.socketRef.onopen = () => {
      console.log("WebSocket open");
      this.socketRef.send(JSON.stringify({ command: "fetch_messages" }));
    };
    this.socketRef.onmessage = (e) => {
      const data = JSON.parse(e.data);
      this.$refs.log.value += data.message + "\n";
    };

    this.socketRef.onerror = (e) => {
      console.log(e.message);
    };
    this.socketRef.onclose = () => {
      console.log("WebSocket closed let's reopen");
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
