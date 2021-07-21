<template>
  <button type="button" class="btn" @click="visitRoom(notification.room)">
    {{ notification.room__display_name }}</button
  ><br />
  <span v-if="notification.message__user__display_name">
    {{ notification.message__user__display_name }} :
    {{ notification.message__content }}</span
  >
  <span v-if="notification.user_joined__display_name">
    {{ notification.user_joined__display_name }} has joined the chat</span
  ><span v-if="notification.user_left__display_name">
    {{ notification.user_left__display_name }} has left the chat</span
  ><span v-if="notification.join_request__user__display_name">
    {{ notification.join_request__user__display_name }} requested to join</span
  ><span v-if="notification.now_public">Room is now public</span
  ><span v-if="notification.now_private">Room is now private</span> <br />{{
    notification.timestamp
  }}
  <br />
  <button
    type="submit"
    class="btn btn__primary"
    @click="exitRoom(notification.room)"
  >
    Exit room
  </button>
</template>
<script>
export default {
  name: "ChatNotification",
  props: {
    notification: {
      type: Object,
      required: true,
    },
    socketRef: {
      type: WebSocket,
      required: true,
    },
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
  },
};
</script>